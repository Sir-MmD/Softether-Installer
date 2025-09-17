# SoftEther VPN Server Auto Installer

![Shell Script](https://img.shields.io/badge/language-Shell%20Script-green.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

An all-in-one Bash script to automate the installation, configuration, and management of **SoftEther VPN Server** on Linux.

This script provides a clean, interactive menu and is designed for maximum compatibility, supporting both **systemd** and older **SysV init** systems.

---

## 🌟 Features

-   **Interactive Menu**: A simple, clean, and easy-to-navigate menu to manage your installation.
-   **Cross-Compatible**: Automatically detects and supports `systemd` and `SysV init` systems.
-   **Smart Dependency Check**: Identifies your OS package manager (`apt`, `dnf`, `yum`, `pacman`) and provides the correct installation command for dependencies.
-   **Auto-Detection**: Automatically detects system architecture (x64, ARM64) to download the correct server version.
-   **Always Up-to-Date**: Fetches the latest stable release directly from the official SoftEther GitHub repository.
-   **Clean Uninstaller**: Includes a robust option to completely and safely remove all related files and services.

---

## 📸 Screenshot

The script provides a clear overview of your system and the available options.

```bash
===================================================
  SoftEther VPN Server Auto Installer
===================================================
  OS:          Ubuntu 22.04
  Arch:        x86_64
  Init System: systemd
  System Time: Wednesday, September 17, 2025 10:05:00 AM EEST
---------------------------------------------------
  1. Install or Update Server
  2. Uninstall Server
  3. Exit Script
---------------------------------------------------
```

---

## ✅ Requirements

-   A Linux distribution (e.g., Ubuntu, Debian, CentOS, Fedora, Arch Linux).
-   **`sudo`** or **`root`** access.
-   The following packages must be installed:
    -   `curl`
    -   `jq`
    -   `build-essential` (on Debian/Ubuntu), `Development Tools` (on CentOS/Fedora), or `base-devel` (on Arch).
    *The script will detect your OS and tell you the exact command to run if dependencies are missing.*

---

## 🚀 Quick Start

You can download and run the script using one of the methods below.

### Method 1: Git Clone (Recommended)

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Sir-MmD/Softether-Installer.git
    ```

2.  **Navigate into the directory:**
    ```bash
    cd Softether-Installer
    ```

3.  **Make the script executable:**
    ```bash
    chmod +x softether-installer.sh
    ```

4.  **Run the script with sudo:**
    ```bash
    sudo ./softether-installer.sh
    ```

### Method 2: One-Liner Command (Curl or Wget)

1.  **Download the script:**

    *Using `curl`:*
    ```bash
    bash <(curl -Ls https://raw.githubusercontent.com/Sir-MmD/Softether-Installer/main/softether-installer.sh) 
    ```
    *or using `wget`:*
    ```bash
    wget -qO - https://raw.githubusercontent.com/Sir-MmD/Softether-Installer/main/softether-installer.sh | sudo bash
    ```
---

## ⚙️ Post-Installation

After the script successfully installs the server, you **must** set an administrator password.

1.  **Run the SoftEther command-line utility:**
    ```bash
    sudo /opt/softether/vpncmd
    ```

2.  Inside the utility, follow these steps:
    -   Select `1` to connect to the server administration.
    -   Press `Enter` to connect to `localhost`.
    -   Press `Enter` again when asked for a Hub name.
    -   Set the administrator password with the command: `ServerPasswordSet`

Your server is now secure and ready for further configuration!

---

## Acknowledgements

The Bash script and this README file were generated with the assistance of **Google's Gemini**.

---
