from glob import glob

from setuptools import setup

package = "koebelt_link_ros"

setup(
    name=package,
    version="1.5.0",
    packages=[package],
    data_files=[
        ("share/ament_index/resource_index/packages", [f"resource/{package}"]),
        (f"share/{package}", ["package.xml"]),
        (f"share/{package}/launch", glob("launch/*.py")),
        (f"share/{package}/config", glob("config/*.yaml")),
    ],
    install_requires=["setuptools", "koebelt-link>=1.5"],
    zip_safe=True,
    maintainer="Thomas Koebel",
    description="Bridge ROS 2 topics to the koebelt dash app over KoebeltLink.",
    license="MIT",
    tests_require=["pytest"],
    entry_points={"console_scripts": [f"bridge = {package}.bridge:main"]},
)
