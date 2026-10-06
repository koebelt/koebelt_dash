# koebelt_link_ros

A ROS 2 (Humble, Jazzy) node that bridges existing topics to koebelt/dash,
built on the `koebelt-link` Python library.

```bash
pip install koebelt-link
cd ~/ros2_ws/src && git clone https://github.com/koebelt/koebelt_dash
cd ~/ros2_ws && colcon build --packages-select koebelt_link_ros
ros2 launch koebelt_link_ros bridge.launch.py config:=config/device.yaml pair:=XXX-XXX
```

See `config/device.yaml`. It maps:

- **Sensors**: `sensor_msgs/Imu`, `PointCloud2`, `JointState`, `BatteryState`,
  `NavSatFix` and `nav_msgs/Odometry` to app channels.
- **Controls**: sticks to `geometry_msgs/Twist` (only in MANUAL while armed),
  arm jog to `control_msgs/JointJog` (MoveIt Servo), mode to `std_msgs/String`,
  armed state to `/koebelt/armed`, and with `goal:` the app's Drive to /
  Fly to as a `geometry_msgs/PoseStamped` navigation goal (Nav2's `/goal_pose`).
- **Sequences**: the app uploads sequences to the node, which runs them on the
  robot and carries on if the link drops (the koebelt/link library's stored
  sequences). Drive to steps need `goal:` and `odom:`.
- **Safety**: STOP publishes a zero Twist and calls your `std_srvs/Trigger`
  service. The failsafe timeout and action come from the config.
- **Params**: entries under `params:` appear on the Tune screen and are published
  on `/koebelt/param/<KEY>`.
- **Video**: a `sensor_msgs/CompressedImage` (JPEG) topic under `video:` is
  served as MJPEG and shown in the app.
- **Links**: `transport:` is `wifi`, `ble`, `serial:/dev/tty…` or
  `radio:/dev/tty…:sik` (sik, lora, hc12, xbee, other); `fallback:` adds a
  second link for telemetry when the first goes quiet.

The apt package `ros-humble-koebelt-link-ros` named in the in-app guide is not
published yet; build from source for now.
