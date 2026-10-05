from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():
    return LaunchDescription([
        DeclareLaunchArgument("config", description="path to device.yaml"),
        DeclareLaunchArgument("pair", default_value="", description="pairing code shown in koebelt/dash"),
        Node(
            package="koebelt_link_ros",
            executable="bridge",
            name="koebelt_link_bridge",
            output="screen",
            parameters=[{"config": LaunchConfiguration("config"), "pair": LaunchConfiguration("pair")}],
        ),
    ])
