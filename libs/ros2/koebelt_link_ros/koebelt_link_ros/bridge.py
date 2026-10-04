"""ROS 2 node: bridges robot topics to koebelt dash.

    ros2 launch koebelt_link_ros bridge.launch.py config:=config/device.yaml pair:=4F7-K2Q
"""
from __future__ import annotations

import yaml
import rclpy
from rclpy.node import Node
from rclpy.qos import qos_profile_sensor_data

from koebelt_link import Device, Vec3

from .convert import control_to_twist, downsample, parse_fallback, parse_transport, quat_to_rpy, topic_values


class Bridge(Node):
    def __init__(self) -> None:
        super().__init__("koebelt_link_bridge")
        self.declare_parameter("config", "")
        self.declare_parameter("pair", "")
        path = self.get_parameter("config").get_parameter_value().string_value
        if not path:
            raise SystemExit("koebelt_link_bridge: pass config:=path/to/device.yaml")
        with open(path) as f:
            cfg = yaml.safe_load(f) or {}
        self.cfg = cfg

        self.dev = Device(cfg.get("name", "ROS robot"), kind=cfg.get("kind", "generic"), model=cfg.get("model", "ROS 2"),
                          sensors=[k.upper() for k in (cfg.get("sensors") or {})])
        fb = parse_fallback(cfg["fallback"]) if cfg.get("fallback") else None
        self.dev.connect(port=int(cfg.get("port", 47800)), fallback=fb, **parse_transport(cfg.get("transport", "wifi")))
        pair = self.get_parameter("pair").get_parameter_value().string_value
        if pair:
            self.dev.pair(pair)
        safety = cfg.get("safety") or {}
        self.dev.failsafe(timeout=float(safety.get("failsafe_timeout", 1.8)), action=str(safety.get("failsafe_action", "hold")))

        self._sensors(cfg.get("sensors") or {})
        self._controls(cfg.get("controls") or {}, safety)
        self._params(cfg.get("params") or [])
        self._channels(cfg.get("channels") or [])
        self._video(cfg.get("video") or {})

        self.create_timer(1 / 50, self.dev.tick)
        self.get_logger().info(f"KoebeltLink bridge for {self.dev.name} ({self.dev.kind}) ready")

    # ------------------------------------------------------------ ROS -> app
    def _sensors(self, s: dict) -> None:
        if "imu" in s:
            from sensor_msgs.msg import Imu

            def imu(m: Imu) -> None:
                a, g, q = m.linear_acceleration, m.angular_velocity, m.orientation
                self.dev.publish("imu", accel=Vec3(a.x, a.y, a.z), gyro=Vec3(g.x, g.y, g.z))
                if q.w or q.x or q.y or q.z:
                    r, p, y = quat_to_rpy(q.x, q.y, q.z, q.w)
                    self.dev.publish("att", roll=r, pitch=p, yaw=y)

            self.create_subscription(Imu, s["imu"], imu, qos_profile_sensor_data)
        if "lidar" in s:
            from sensor_msgs.msg import PointCloud2
            from sensor_msgs_py import point_cloud2

            self._last_cloud = 0.0

            def cloud(m: PointCloud2) -> None:
                now = self.get_clock().now().nanoseconds / 1e9
                if now - self._last_cloud < 0.2:
                    return
                self._last_cloud = now
                pts = point_cloud2.read_points(m, field_names=("x", "y", "z"), skip_nans=True)
                self.dev.publish("lidar", points=downsample(pts, 2000))

            self.create_subscription(PointCloud2, s["lidar"], cloud, qos_profile_sensor_data)
        if "joints" in s:
            from sensor_msgs.msg import JointState

            self.create_subscription(JointState, s["joints"], lambda m: self.dev.publish("joints", list(m.position)[:6]), 10)
        if "power" in s:
            from sensor_msgs.msg import BatteryState

            def bat(m: BatteryState) -> None:
                pct = m.percentage * 100 if m.percentage == m.percentage else 0.0  # NaN when unknown
                self.dev.publish("bat", volts=m.voltage, amps=abs(m.current) if m.current == m.current else 0.0, percent=pct)

            self.create_subscription(BatteryState, s["power"], bat, 10)
        if "odom" in s:
            from nav_msgs.msg import Odometry

            def odom(m: Odometry) -> None:
                p, q, v = m.pose.pose.position, m.pose.pose.orientation, m.twist.twist.linear
                self.dev.publish("pos", x=p.x, y=p.y, z=p.z)
                r, pi, y = quat_to_rpy(q.x, q.y, q.z, q.w)
                self.dev.publish("att", roll=r, pitch=pi, yaw=y)
                self.dev.publish("vel", vx=v.x, vy=v.y, vz=v.z)

            self.create_subscription(Odometry, s["odom"], odom, 10)
        if "gps" in s:
            from sensor_msgs.msg import NavSatFix

            self.create_subscription(NavSatFix, s["gps"], lambda m: self.dev.gps(m.latitude, m.longitude, m.altitude), 10)

    def _video(self, v: dict) -> None:
        """A sensor_msgs/CompressedImage topic (JPEG) served to the app as MJPEG."""
        if not v.get("topic"):
            return
        from sensor_msgs.msg import CompressedImage

        from koebelt_link import MjpegServer

        srv = MjpegServer(port=int(v.get("port", 8081)))
        self.dev.video(srv.url, label=v.get("label") or None)

        def frame(m: CompressedImage) -> None:
            fmt = m.format.lower()
            if srv.clients and ("jpeg" in fmt or "jpg" in fmt):
                srv.push(bytes(m.data))

        self.create_subscription(CompressedImage, v["topic"], frame, qos_profile_sensor_data)
        self.get_logger().info(f"Camera {v['topic']} on {srv.url}")

    # ------------------------------------------------------------ app -> ROS
    def _controls(self, c: dict, safety: dict) -> None:
        from std_msgs.msg import Bool, String

        max_lin, max_ang = float(c.get("max_linear", 1.0)), float(c.get("max_angular", 1.5))
        twist_pub = jog_pub = None
        if "twist" in c:
            from geometry_msgs.msg import Twist

            twist_pub = self.create_publisher(Twist, c["twist"], 10)

            @self.dev.on_control
            def _(ctl) -> None:
                t = Twist()
                if self.dev.armed and self.dev.mode == "MANUAL":
                    t.linear.x, t.angular.z = control_to_twist(ctl.ry, ctl.lx, self.dev.speed, max_lin, max_ang)
                twist_pub.publish(t)

        if "jog" in c:
            from control_msgs.msg import JointJog

            jog_pub = self.create_publisher(JointJog, c["jog"], 10)
            names = list(c.get("joint_names") or [f"joint_{i + 1}" for i in range(6)])

            @self.dev.on_jog
            def _(j) -> None:
                m = JointJog()
                m.header.stamp = self.get_clock().now().to_msg()
                m.joint_names = names[: len(j)]
                m.velocities = [float(v) * self.dev.speed * 2 for v in j[: len(names)]]
                jog_pub.publish(m)

        mode_pub = self.create_publisher(String, c.get("mode", "/koebelt/mode"), 10)
        armed_pub = self.create_publisher(Bool, "/koebelt/armed", 10)
        self.dev.on_mode(lambda m: mode_pub.publish(String(data=m)))
        self.dev.on_arm(lambda a: armed_pub.publish(Bool(data=a)))

        client = None
        if safety.get("stop_service"):
            from std_srvs.srv import Trigger

            client = self.create_client(Trigger, safety["stop_service"])

        @self.dev.on_stop
        def _() -> None:
            self.get_logger().warn("Emergency stop from koebelt dash")
            if twist_pub is not None:
                from geometry_msgs.msg import Twist

                twist_pub.publish(Twist())
            if client is not None:
                from std_srvs.srv import Trigger

                if client.service_is_ready():
                    client.call_async(Trigger.Request())
                else:
                    self.get_logger().error(f"stop service {safety['stop_service']} is not available")
            armed_pub.publish(Bool(data=False))

    def _channels(self, items: list) -> None:
        """Any numeric topic becomes a custom channel: a tile, a HUD widget and CSV columns in the app."""
        from std_msgs import msg as std

        for it in items:
            typ = str(it.get("type", "Float64"))
            if typ == "Temperature":
                from sensor_msgs.msg import Temperature as cls
            elif typ == "FluidPressure":
                from sensor_msgs.msg import FluidPressure as cls
            else:
                cls = getattr(std, typ)
            ch = self.dev.channel(str(it["id"]), axes=list(it.get("axes") or ["value"]), unit=str(it.get("unit", "")), hz=float(it.get("hz", 10)))
            self.create_subscription(cls, it["topic"], lambda m, ch=ch: ch.publish(*topic_values(m, len(ch.axes))), 10)

    def _params(self, items: list) -> None:
        from std_msgs.msg import Float64

        for it in items:
            key = str(it["key"])
            p = self.dev.param(key, float(it.get("default", 0)), float(it.get("min", 0)), float(it.get("max", 1)), unit=str(it.get("unit", "")))
            pub = self.create_publisher(Float64, f"/koebelt/param/{key}", 10)
            pub.publish(Float64(data=p.value))
            p.on_change(lambda v, pub=pub: pub.publish(Float64(data=v)))
        self.dev.on_params_written(self.dev.save_params)


def main() -> None:
    rclpy.init()
    node = Bridge()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.dev.close()
        node.destroy_node()
        rclpy.try_shutdown()


if __name__ == "__main__":
    main()
