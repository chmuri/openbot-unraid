# OpenBot for Unraid OS

<p align="center">
  <img src="docs/icon.png" width="128" height="128" alt="OpenBot Logo" />
</p>

<p align="center">
  <b>Official OpenBot integration for Unraid OS & Community Applications</b><br>
  Multi-architecture Docker container (amd64 / arm64) with automated CI/CD and hardware passthrough support.
</p>

<p align="center">
  <a href="https://github.com/chmuri/openbot-unraid/actions"><img src="https://github.com/chmuri/openbot-unraid/actions/workflows/build-and-release.yml/badge.svg" alt="CI/CD Status" /></a>
  <a href="https://github.com/chmuri/openbot-unraid/pkgs/container/openbot"><img src="https://img.shields.io/badge/GHCR-OpenBot-blue?logo=docker" alt="Docker Image" /></a>
  <a href="https://unraid.net"><img src="https://img.shields.io/badge/Unraid-Community%20Applications-orange" alt="Unraid CA" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-green.svg" alt="License" /></a>
</p>

---

## 🌟 Key Features

- 🤖 **Optimized for Unraid:** Dedicated XML template strictly compliant with Unraid Community Applications (CA) standards.
- 🔒 **Secure Permissions (PUID/PGID):** Native `nobody:users` (`99:100`) mapping to prevent permission conflicts across Unraid user shares (`/mnt/user/appdata`).
- ⚡ **Multi-Architecture:** Automated multi-arch builds for `linux/amd64` (standard x86-64 servers) and `linux/arm64`.
- 🔌 **Hardware Passthrough Support:**
  - USB Serial ports (`/dev/ttyUSB*`, `/dev/ttyACM*`) for Arduino / ESP32 microcontrollers.
  - V4L2 Video Cameras (`/dev/video*`).
  - GPU Hardware Acceleration (`/dev/dri` - Intel QuickSync / VAAPI).
  - Bluetooth Low Energy (BLE) via D-Bus system socket mounting.
- 🔄 **Fully Automated CI/CD:** Linting, multi-arch builds, SHA256 checksum generation, and automatic GitHub Releases with Semantic Versioning.

---

## 🚀 Quick Start in Unraid

### Method 1: Add Template Repository (Development / Testing)
1. In your Unraid WebGUI, navigate to the **Docker** tab.
2. Scroll down to the **Template repositories** section and enter:
   ```text
   https://github.com/chmuri/openbot-unraid
   ```
3. Click **Save**.
4. Click **Add Container** and select **OpenBot** from the *Template* dropdown.

### Method 2: Installation via Community Applications (CA)
Once indexed in the official Unraid CA feed, search for **OpenBot** in the **Apps** tab and click **Install**.

---

## ⚙️ Container Configuration

| Parameter / Variable | Unraid Default Value | Description |
| :--- | :--- | :--- |
| **Network Port** | `8080/tcp` | Web UI, REST API, and WebSocket server |
| `/config` | `/mnt/user/appdata/openbot/config` | Persistent configuration files and robot database |
| `/data` | `/mnt/user/appdata/openbot/data` | ML models, telemetry logs, and video recordings |
| `PUID` | `99` | Unraid user ID (`nobody`) |
| `PGID` | `100` | Unraid group ID (`users`) |
| `UMASK` | `022` | File creation mask |
| `OPENBOT_PORT` | `8080` | Internal listening port |

---

## 🔌 Hardware Passthrough Setup

### 1. Microcontroller (Arduino, ESP32)
Instead of `/dev/ttyUSB0` (which can change between reboots), use the persistent hardware ID path in Unraid:
```text
Type: Device
Value: /dev/serial/by-id/usb-Silicon_Labs_CP2102_USB_to_UART_Bridge_Controller_0001-if00-port0
```

### 2. USB Video Camera (V4L2)
```text
Type: Device
Value: /dev/video0
```

### 3. Intel QuickSync / VAAPI Hardware Acceleration
```text
Type: Device
Value: /dev/dri
```

### 4. Bluetooth / BLE Support
Add the following to the container's **Extra Parameters**:
```text
--net=host -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket
```

---

## 🛠️ Repository Architecture

```text
.
├── .github/
│   └── workflows/
│       └── build-and-release.yml   # CI/CD: linting, multi-arch build, release workflow
├── docker/
│   ├── Dockerfile                  # Multi-arch base image (Python 3.11 slim)
│   ├── entrypoint.sh               # Runtime initialization: PUID/PGID, gosu, device permissions
│   └── healthcheck.sh              # Container healthcheck probe
├── templates/
│   └── openbot.xml                 # Official Unraid Community Applications template
├── src/
│   └── app.py                      # OpenBot server & telemetry agent
├── docs/
│   ├── icon.png                    # Icon for Unraid WebGUI and CA feed
│   └── banner.png                  # Banner image for the template
├── LICENSE                         # Apache-2.0 License
└── README.md
```

---

## 📦 Release Workflow (SemVer)

Releases are triggered automatically using Git tags:

```bash
# Tag a new release
git tag -a v1.0.0 -m "Release v1.0.0 for Unraid OS"
git push origin v1.0.0
```

The GitHub Actions workflow will:
1. Validate source code, shell scripts, and the XML template.
2. Build and push multi-architecture images to `ghcr.io/chmuri/openbot:v1.0.0` and `latest`.
3. Compute SHA256 checksums for the build digest and template.
4. Publish a GitHub Release containing release notes and the XML template.

---

## 📄 License

Distributed under the **Apache-2.0** License. See [LICENSE](LICENSE) for details.
