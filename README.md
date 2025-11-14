# 3D Sparse Mapping

![Platform](https://img.shields.io/badge/platform-Raspberry%20Pi%205-blue)
![ROS2](https://img.shields.io/badge/ROS2-Humble-green)
![SLAM](https://img.shields.io/badge/SLAM-ORB_SLAM3-blue)
![OpenCV](https://img.shields.io/badge/OpenCV-4.6.0-green)
![License](https://img.shields.io/badge/license-MIT-blue)

A real-time Sparse mapping SLAM implementation of ORB-SLAM3 on Raspberry Pi 5 using ROS2 (Humble) with an external USB camera.

This project provides:

- Real-time monocular SLAM on Raspberry Pi 5 (ROS2)
- Dataset-based evaluation (TUM, EuRoC MAV, KITTI)
- Camera calibration tools
- Automated dataset & thermal evaluation scripts
- Scripts for converting datasets to ROS2 bags, running native ORB-SLAM3 examples

SLAM (Simultaneous Localisation and Mapping) enables a robot to construct a three-dimensional map of the environment while localising its own pose (position and orientation) within it. ORB-SLAM3 is a one of the most powerful SLAM implementations which have real-time, multi-map, and multi-mode support even on low-powered devices (such as the Raspberry Pi). I have implemented ORB-SLAM3 in ROS2 (Humble) on the Pi5, and built a full modular system that supports real-time monocular SLAM, RGB-D mapping, and dataset-based evaluation (TUM, EuRoC, and KITTI) with automated scripts and camera calibration tools. The system is capable of publishing 3D sparse maps, integrating with RViz2 for visualization, and supports live or recorded input via ROS 2 topics or native ORB-SLAM3 executables.

> This repository accompanies the bachelor's minor project at Manipal University Jaipur.

---

## Quick links

- Repo (fork/branch used in experiments): `https://github.com/eshan-sud/ORB_SLAM3/tree/978d82ef265e184a5f787d71ccdcd53df5adeba6`
- Scripts & automation live in `~/ros2_test/scripts/`
- Thermal evaluation pipeline: `~/ros2_test/scripts/evaluation/`

---

## Features

- Camera calibration
- Real-time Monocular SLAM (ROS2)
- Dataset-based evaluation scripts (TUM, EuRoC, KITTI)
- RViz2 visualization support
- Modular bash automation & helpers

---

## Testing environment

- **Hardware:** Raspberry Pi 5 Model B Rev 1.0 (with fan + heatsink)
- **OS:** Debian GNU/Linux 12 (bookworm)
- **Mode tested:** Monocular (real-time), other modes dataset-offline
- **Swap:** experiments used a 4 GB swap file to avoid memory crashes for heavy modes

---

### Hardware Used

1. Raspberry Pi 5 Model B Rev 1.0
2. Raspberry Pi Fan & Heatsink
3. Raspberry Pi Power Adaptor (minimum 27 Watts)
4. 256 GB Micro SD Card
5. External USB Camera

### Software / Packages Used

1. Raspian OS (12 (bookworm))
2. Python (3.11.2)
3. CMake (3.25.1)
4. OpenCV (4.6.0)
5. OpenCV Contrib
6. Vision_opencv
7. ROS2 (Humble Hawksbill)
8. Eigen3 (3.3.7)
9. g2o
10. Sophus (v1.1.0)
11. DBoW2 (v1.1)
12. Pangolin (4.5.0)
13. OpenGL (3.1)
14. Mesa (23.2.1-1~bpo12+rpt3)
15. ORB-SLAM3
16. Octomap
17. Image Common
18. Message Filters
19. Rclcpp
20. Octomap_ros
21. Geometry2
22. Common_interfaces

## How to start?

- Steps on how to setup & execute this project

### Headless Connection with Raspberry Pi 5

1. Download Raspberry Pi Imager from the [official website](https://www.raspberrypi.com/software/).
2. Connect your microSD card to your laptop/PC.
3. Run Raspberry Pi Imager:
   - Select the appropriate Raspberry Pi device (e.g., Raspberry Pi 5).
   - Select the required operating system (e.g., Raspberry Pi OS (64-bit)).
   - Select the appropriate storage (your microSD card).
4. Press `Ctrl + Shift + X` to open Advanced Options:
   - Set a hostname (default: `raspberrypi`).
   - Enable SSH and set a username and password _(remember these)_.
   - Configure Wi-Fi settings (SSID, password, and country code).
   - Set the correct locale & keyboard layout.
     _To check your layout: press `Windows + Spacebar` or check your system settings._
   - Click Save.
5. Click Write to write the OS to the microSD card
   The Imager will automatically eject the card when done
6. Insert the microSD card into the Raspberry Pi and power it on

### Connect to Raspberry Pi 5 via SSH

1. Open Command Prompt (Windows) or Terminal (Mac/Linux).
2. Run the following command:

```
ssh <username>@<hostname>
```

- Example:

```
ssh eshan-sud@raspberrypi
```

### Increase swap space

- Swap space is increased for max performance from the raspberry pi 5

```
sudo nano /etc/dphys-swapfile
```

- Change swapsize to 4096

```
sudo systemctl restart dphys-swapfile
```

### Setup the Project (Execute in the project's folder)

```
cd ./scripts/
chmod +x setup.sh
./setup/setup.sh
```

### For Camera Calibration

- Use this checkerboard for calibration: <a href="https://markhedleyjones.com/projects/calibration-checkerboard-collection">checkerboard-patterns</a>
- To calibrate your camera and generate an ORB-SLAM3-compatible **.yaml** file:

```
./start_camera_calibration.sh
```

### For Downloading the Datasets

- TUM RGB-D

```
cd ~/ros2_test/scripts/tum/
./download_tum_sequences.sh
```

- EuRoC MAV

```
cd ~/ros2_test/scripts/euroc/
./download_euroc_sequences.sh
```

- KITTI Visual Odometry

```
cd ~/ros2_test/scripts/kitti/
./download_kitti_sequences.sh
```

### For Rosbag Handling

#### Record a Custom Rosbag using /camera/image_raw topic

- Monocular

```
ros2 bag record /camera/image_raw
ros2 run image_tools showimage --ros-args -r image:=/camera/image_raw
```

- RGB-D

```
ros2 bag record /camera/color/image_raw /camera/depth/image_raw
```

#### Converting Datasets to RosBag

- Convert any TUM dataset to a ROS2 bag:

```
cd ~/ros2_test/scripts/tum
python3 convert_tum_to_ros2_bag.py <tum_sequence_folder_path> <output_folder>
```

- Convert any euroc dataset to a ROS2 bag:

```
cd ~/ros2_test/scripts/euroc
python3 convert_euroc_to_ros2_bag.py <tum_sequence_folder_path> <output_folder>
```

- Example Usage:

```
cd ~/ros2_test/scripts/tum
python3 convert_tum_to_ros2_bag.py \
 /home/{your_username}/ros2_test/datasets/TUM/rgbd_dataset_freiburg1_desk \
 /home/{your_username}/tum_ros2_bag
```

#### Check Rosbag Contents

```
ros2 bag info ~/ros2_test/{path_to_rosbag}/{rosbag_name}
```

#### Execute Rosbag

```
ros2 bag play ~/ros2_test/{path_to_rosbag}/{rosbag_name}
```

### Execution

- Contains ROS2-based, pre-written sripts, & native ORB-SLAM3 execution scripts
- Executions will work only after successful setup of all libraries, packages, & datasets (if executing on them)
- Check for updates:

```
sudo apt update && sudo apt upgrade -y
```

- Before executing, execute these on each terminal(s) where you want to execute the 3D sparse mapping

```
export DISPLAY=:0
export LIBGL_ALWAYS_INDIRECT=1
export MESA_GL_VERSION_OVERRIDE=3.3
export MESA_GLSL_VERSION_OVERRIDE=330
export LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libGL.so
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/ros2_test/src/ORB_SLAM3/lib
export LD_LIBRARY_PATH=~/ros2_test/src/ORB_SLAM3/Thirdparty/DBoW2/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=~/ros2_test/src/ORB_SLAM3/Thirdparty/g2o/lib:$LD_LIBRARY_PATH
source ~/ros2_test/install/local_setup.bash
```

#### Execute using pre-written scripts

- Real-time SLAM (Monocular)

```bash
cd ~/ros2_test/
./start_real_time_slam.sh
```

- ## Dataset-based SLAM

  - In this case; first, we also need to play rosbags, & in separate terminals we can execute ROS2 execution on the datasets

  ```bash
  ros2 bag play ~/ros2_test/datasets/{path_to_rosbag}
  ```

  - TUM - Monocular :

  ```bash
  ./start_dataset_slam.sh tum_mono recorded
  ```

  - TUM - RGB-D:

  ```bash
  ./start_dataset_slam.sh tum_rgbd recorded
  ```

  - EuRoC - Monocular:

  ```bash
  ./start_dataset_slam.sh euroc_mono recorded
  ```

  - Custom ROS2 Bag (RGB-D):

  ```bash
  ./start_dataset_slam.sh custom_rgbd recorded
  ```

#### Native ORB-SLAM3 Executables (No ROS2)

- TUM RGB-D - Monocular

  - Usage:

  ```bash
  ./mono_tum path_to_vocabulary path_to_settings path_to_sequence [use_viewer=true|false]
  ```

  - Example Usage (With Viewer):

  ```bash
  cd ~/ros2_test/src/ORB_SLAM3/
  ./Examples/Monocular/mono_tum \
  ./Vocabulary/ORBvoc.txt \
  ./Examples/Monocular/TUM1.yaml \
  ~/ros2_test/datasets/TUM/rgbd_dataset_freiburg1_desk
  true
  ```

- TUM RGB-D - RGB-D

  - Usage:

  ```bash
  ./rgbd_tum path_to_vocabulary path_to_settings path_to_sequence path_to_association [use_viewer=true|false]
  ```

  - Example Usage (With Viewer):

  ```bash
  cd ~/ros2_test/src/ORB_SLAM3/
  ./Examples/RGB-D/rgbd_tum \
  ./Vocabulary/ORBvoc.txt \
  ./Examples/RGB-D/TUM1.yaml \
  ~/ros2_test/datasets/TUM/rgbd_dataset_freiburg1_desk \
  ~/ros2_test/datasets/TUM/rgbd_dataset_freiburg1_desk/associate.txt \
  true
  ```

- EuRoC MAV - Monocular

  - Usage:

  ```bash
  ./mono_euroc path_to_vocabulary path_to_settings path_to_sequence_folder path_to_times_file [bUseViewer=true|false]
  ```

  - Example Usage (With Viewer):

  ```bash
  cd ~/ros2_test/src/ORB_SLAM3/
  ./Examples/Monocular/mono_euroc \
  ./Vocabulary/ORBvoc.txt \
  ./Examples/Monocular/EuRoC.yaml \
  ~/ros2_test/datasets/EuRoC/MH01 \
  ./Examples/Monocular/EuRoC_TimeStamps/MH01.txt \
  true
  ```

- EuRoC MAV - Stereo

  - Usage:

  ```bash
  ./stereo_euroc path_to_vocabulary path_to_settings path_to_sequence_folder_1 path_to_times_file_1 (path_to_image_folder_2 path_to_times_file_2 ... path_to_image_folder_N path_to_times_file_N) (trajectory_file_name) [bUseviewer(true|false)]
  ```

  - Example Usage (With Viewer):

  ```bash
  cd ~/ros2_test/src/ORB_SLAM3/
  ./Examples/Stereo/stereo_euroc \
  ./Vocabulary/ORBvoc.txt \
  ./Examples/Stereo/EuRoC.yaml \
  ~/ros2_test/datasets/EuRoC/MH01 \
  ~/ros2_test/datasets/EuRoC/MH01/mav0/MH01.txt \
  true
  ```

- EuRoC MAV - Mono-Inertial

  - Usage:

  ```bash
  ./mono_inertial_euroc path_to_vocabulary path_to_settings path_to_sequence_folder_1 path_to_times_file_1 (path_to_image_folder_2 path_to_times_file_2 ... path_to_image_folder_N path_to_times_file_N) [bUseViewer(true|false)] [output_file]
  ```

  - Example Usage (With Viewer):

  ```bash
  cd ~/ros2_test/src/ORB_SLAM3/
  ./Examples/Monocular-Inertial/mono_inertial_euroc \
  ./Vocabulary/ORBvoc.txt \
  ./Examples/Monocular-Inertial/EuRoC.yaml \
  ~/ros2_test/datasets/EuRoC/MH01 \
  ./Examples/Monocular-Inertial/EuRoC_TimeStamps/MH01.txt \
  true
  ```

- EuRoC MAV - Stereo-Inertial

  - Usage:

  ```bash
  ./stereo_inertial_euroc path_to_vocabulary path_to_settings path_to_sequence_folder_1 path_to_times_file_1 (path_to_image_folder_2 path_to_times_file_2 ... path_to_image_folder_N path_to_times_file_N) [bUseViewer(true|false)] [output_file]
  ```

  - Example Usage (With Viewer):

  ```bash
  cd ~/ros2_test/src/ORB_SLAM3/
  ./Examples/Stereo-Inertial/stereo_inertial_euroc \
  ./Vocabulary/ORBvoc.txt \
  ./Examples/Stereo-Inertial/EuRoC.yaml \
  ~/ros2_test/datasets/EuRoC/MH01 \
  ./Examples/Stereo-Inertial/EuRoC_TimeStamps/MH01.txt \
  true
  ```

- KITTI Visual Odometry - Monocular

  - Usage:

  ```bash
  ./mono_kitti path_to_vocabulary path_to_settings path_to_sequence [bUseViewer(true|false)]
  ```

  - Example Usage (With Viewer):

  ```bash
  cd ~/ros2_test/src/ORB_SLAM3/
  ./Examples/Monocular/mono_kitti \
  ./Vocabulary/ORBvoc.txt \
  ./Examples/Monocular/KITTI00-02.yaml \
  ~/ros2_test/datasets/KITTI/dataset/sequences/00 \
  true
  ```

- KITTI Visual Odometry - Stereo

  - Usage:

  ```bash
  ./stereo_kitti path_to_vocabulary path_to_settings path_to_sequence [bUseviewer(true|false)]
  ```

  - Example Usage (With Viewer):

  ```bash
  cd ~/ros2_test/src/ORB_SLAM3/
  ./Examples/Stereo/stereo_kitti \
  ./Vocabulary/ORBvoc.txt \
  ./Examples/Stereo/KITTI00-02.yaml \
  ~/ros2_test/datasets/KITTI/dataset/sequences/00 \
  true
  ```

#### ROS2 Node Execution (real-time)

- Monocular Node

```bash
ros2 run ros2_orbslam3_wrapper monocular_node --ros-args -p input_mode:=live
```

- Camera Publisher with Calibration YAML

```bash
ros2 run ros2_orbslam3_wrapper camera_publisher_node \
 /home/{your_username}/ros2_test/scripts/common/my_camera.yaml
```

- RViz Launcher (from SSH, not VNC)
  > [!NOTE]
  > RViz may not launch under VNC. For proper OpenGL rendering, use an SSH terminal session instead.
  > Also, create a ros topic of map & set it to **ORB_SLAM3/map**

```bash
ros2 run ros2_orbslam3_wrapper rviz_launcher_node
```

#### ROS2 Node Execution (rosbag)

- Monocular Node

```bash
ros2 run ros2_orbslam3_wrapper monocular_node --ros-args -p input_mode:=recorded`
```

- RGB-D Node

```bash
ros2 run ros2_orbslam3_wrapper rgbd_node --ros-args -p input_mode:=recorded`
```

- Camera Publisher with Calibration YAML

```bash
ros2 run ros2_orbslam3_wrapper camera_publisher_node \
 /home/{your_username}/ros2_test/scripts/common/my_camera.yaml
```

- RViz Launcher (from SSH, not VNC)
  > [!NOTE]
  > RViz may not launch under VNC. For proper OpenGL rendering, use an SSH terminal session instead.
  > Also, create a ros topic of map & set it to **ORB_SLAM3/map**

```bash
ros2 run ros2_orbslam3_wrapper rviz_launcher_node
```

- Play Rosbag

```bash
ros2 bag play ~/ros2_test/{path_to_rosbag}/{rosbag_name}
```

> [!Important]  
> You should now see the sparse map being created on the pangolin viewer & on the RViz viewer as well

## Automated dataset evaluation (script)

From project root:

```bash
cd ~/ros2_test/
./start_dataset_slam.sh tum_rgbd
# supported args:
# tum_rgbd, tum_mono, euroc_mono, kitti_mono, custom_rgbd
```

Thermal evaluation (pipeline):
To run the dedicated thermal profiling shown in the paper:

```bash
cd ~/ros2_test/scripts/evaluation
chmod +x evaluate_thermal_conditions.sh
./evaluate_thermal_conditions.sh
```

`evaluate_thermal_conditions.sh` performs:

- runs ORB-SLAM3 deterministically over selected sequences,
- logs CPU temperature (vcgencmd measure_temp), vcgencmd get_throttled, CPU frequency and load, RAM usage, and per-process CPU usage at 1 Hz,
- writes CSV logs for each run to ~/ros2_test/results/<dataset>/<sequence>/<mode>/thermal_log.csv

## References (Repositories being used in this project):

1. <a href="https://github.com/opencv/opencv">OpenCV4</a>
2. <a href="https://github.com/opencv/opencv_contrib">opencv-contrib</a> (OpenCV dependency)
3. <a href="https://github.com/ros-perception/vision_opencv">vision-opencv</a> (ROS2-OpenCV dependency)
4. <a href="https://github.com/stevenlovegrove/Pangolin">Pangolin</a>
5. <a href="https://github.com/eshan-sud/ORB_SLAM3">ORB-SLAM3 [Forked]</a>
6. <a href="https://github.com/ozandmrz/ros2_raspberry_pi_5">ROS2</a>
7. <a href="https://github.com/ozandmrz/orb_slam3_ros2_mono_publisher">ROS2 ORB-SLAM3 Wrapper [Referenced from]</a>
8. <a href="https://github.com/ros2/rviz">rviz</a>
9. <a href="https://github.com/ros-perception/image_common">image-common</a>
10. <a href="https://github.com/ros2/message_filters">message-filters</a>
11. <a href="https://github.com/ros2/rclcpp">rclcpp</a>
12. <a href="https://github.com/OctoMap/octomap">octomap</a>
13. <a href="https://github.com/OctoMap/octomap_ros">octomap_ros</a>
14. <a href="https://github.com/ros2/geometry2">geometry2</a>
15. <a href="https://github.com/ros2/common_interfaces">common_Interfaces</a>

### Contact the author

[eshansud22@gmail.com](mailto:eshansud22_gmail.com)

---
