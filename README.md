<p align="center">
  <img src="https://raw.githubusercontent.com/blackoutsecure/docker-dump978/main/logo.png" alt="dump978 logo" width="200">
</p>

# docker-dump978

[![GitHub Stars](https://img.shields.io/github/stars/blackoutsecure/docker-dump978?style=flat-square&color=E7931D&logo=github)](https://github.com/blackoutsecure/docker-dump978/stargazers)
[![Docker Pulls](https://img.shields.io/docker/pulls/blackoutsecure/dump978?style=flat-square&color=E7931D&logo=docker&logoColor=FFFFFF)](https://hub.docker.com/r/blackoutsecure/dump978)
[![GitHub Release](https://img.shields.io/github/release/blackoutsecure/docker-dump978.svg?style=flat-square&color=E7931D&logo=github&logoColor=FFFFFF)](https://github.com/blackoutsecure/docker-dump978/releases)
[![Release CI](https://img.shields.io/github/actions/workflow/status/blackoutsecure/docker-dump978/release.yml?style=flat-square&label=release%20ci&color=E7931D)](https://github.com/blackoutsecure/docker-dump978/actions/workflows/release.yml)
[![Publish CI](https://img.shields.io/github/actions/workflow/status/blackoutsecure/docker-dump978/publish.yml?style=flat-square&label=publish%20ci&color=E7931D)](https://github.com/blackoutsecure/docker-dump978/actions/workflows/publish.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](https://opensource.org/licenses/MIT)

Containerized [dump978](https://github.com/flightaware/dump978) for decoding 978 MHz UAT ADS-B with RTL-SDR or SoapySDR on Linux.

Sponsored and maintained by [Blackout Secure](https://blackoutsecure.app).

> [!IMPORTANT]
> This repository is not an official LinuxServer.io image release.

## Overview

This project packages upstream [flightaware/dump978](https://github.com/flightaware/dump978) into a containerized build for decoding 978 MHz UAT ADS-B with RTL-SDR or SoapySDR on Linux.

Quick links:

- Docker Hub listing: [blackoutsecure/dump978](https://hub.docker.com/r/blackoutsecure/dump978)
- Balena block listing: [dump978 block on Balena Hub](https://hub.balena.io/blocks/2354279/dump978)
- GitHub repository: [blackoutsecure/docker-dump978](https://github.com/blackoutsecure/docker-dump978)
- Upstream application: [flightaware/dump978](https://github.com/flightaware/dump978)

[![balena deploy button](https://www.balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/blackoutsecure/docker-dump978&configUrl=https://raw.githubusercontent.com/blackoutsecure/docker-dump978/main/balena.yml)

---

## Table of Contents

- [docker-dump978](#docker-dump978)
  - [Overview](#overview)
  - [Table of Contents](#table-of-contents)
  - [Quick Start](#quick-start)
  - [Image Availability](#image-availability)
  - [About The dump978 Application](#about-the-dump978-application)
  - [Supported Architectures](#supported-architectures)
  - [Usage](#usage)
    - [docker-compose (recommended, click here for more info)](#docker-compose-recommended-click-here-for-more-info)
    - [docker-compose paired with readsb](#docker-compose-paired-with-readsb)
    - [docker-cli (click here for more info)](#docker-cli-click-here-for-more-info)
    - [Balena Deployment](#balena-deployment)
  - [Parameters](#parameters)
    - [Ports](#ports)
    - [Environment Variables](#environment-variables)
      - [Feed Profile](#feed-profile)
      - [Core Settings](#core-settings)
      - [SDR Advanced Tuning](#sdr-advanced-tuning)
      - [Location \& Statistics](#location--statistics)
      - [faup978 FlightAware Reporter](#faup978-flightaware-reporter)
      - [skyaware978 Tuning](#skyaware978-tuning)
      - [SkyAware Web UI Customization](#skyaware-web-ui-customization)
    - [Storage Mounts](#storage-mounts)
  - [Volume Details](#volume-details)
    - [`/config` — Configuration \& Persistence](#config--configuration--persistence)
    - [`/run/dump978-fa` — Decoder Output](#rundump978-fa--decoder-output)
  - [Configuration](#configuration)
    - [Feed Profiles](#feed-profiles)
    - [dump978-fa Options](#dump978-fa-options)
    - [skyaware978 Options](#skyaware978-options)
    - [faup978 Options (FlightAware Reporter)](#faup978-options-flightaware-reporter)
    - [Custom Configuration via Volume Mount](#custom-configuration-via-volume-mount)
  - [Application Setup](#application-setup)
    - [SDR Device Access](#sdr-device-access)
  - [Troubleshooting](#troubleshooting)
    - [No SDR device found](#no-sdr-device-found)
    - [No data / empty web UI](#no-data--empty-web-ui)
    - [Port conflict](#port-conflict)
    - [View logs](#view-logs)
    - [Check service status](#check-service-status)
    - [Getting help](#getting-help)
  - [Release \& Versioning](#release--versioning)
  - [Support \& Getting Help](#support--getting-help)
  - [Sponsor \& Credits](#sponsor--credits)
  - [References](#references)
    - [Project Resources](#project-resources)
    - [Upstream \& Related](#upstream--related)
    - [Technical Resources](#technical-resources)
  - [License](#license)

---

## Quick Start

```bash
docker run -d \
  --name=dump978 \
  --restart unless-stopped \
  -e TZ=Etc/UTC \
  -e DUMP978_SDR=driver=rtlsdr \
  -e DUMP978_LAT=47.6062 \
  -e DUMP978_LON=-122.3321 \
  -p 8978:8978 \
  -p 30978:30978 \
  -p 30979:30979 \
  -v dump978-config:/config \
  -v /run/dump978-fa:/run/dump978-fa \
  --device /dev/bus/usb:/dev/bus/usb \
  blackoutsecure/dump978:latest
```

Access the SkyAware978 web UI at `http://<host-ip>:8978/`.

For compose files, balena, and more examples, see [Usage](#usage) below.

---

## Image Availability

**Docker Hub (Recommended):**

- All images published to [Docker Hub](https://hub.docker.com/r/blackoutsecure/dump978)
- Simple pull command: `docker pull blackoutsecure/dump978:latest`
- Multi-arch support: amd64, arm64
- No registry prefix needed (defaults to Docker Hub)

```bash
# Pull latest
docker pull blackoutsecure/dump978

# Pull specific version
docker pull blackoutsecure/dump978:10.2

# Pull architecture-specific (rarely needed)
docker pull blackoutsecure/dump978:latest@amd64
```

---

## About The dump978 Application

[dump978-fa](https://github.com/flightaware/dump978) is FlightAware's 978 MHz UAT (Universal Access Transceiver) decoder. It demodulates UAT signals from an RTL-SDR or other SoapySDR-compatible receiver and provides decoded ADS-B data as raw messages or JSON-formatted output on network ports. The companion `skyaware978` writes JSON files suitable for the SkyAware web map.

Author and maintenance credits (upstream):

- Primary upstream maintainer: [FlightAware](https://github.com/flightaware)
- Original implementation: [mutability/dump978](https://github.com/mutability/dump978)
- Upstream repository and documentation: [flightaware/dump978](https://github.com/flightaware/dump978)

---

## Supported Architectures

This image is published as a multi-arch manifest. Pulling `blackoutsecure/dump978:latest` retrieves the correct image for your host architecture.

The architectures supported by this image are:

| Architecture | Tag |
| :----: | --- |
| x86-64 | amd64-latest |
| arm64 | arm64v8-latest |

---

## Usage

### docker-compose (recommended, [click here for more info](https://docs.linuxserver.io/general/docker-compose))

```yaml
---
services:
  dump978:
    image: blackoutsecure/dump978:latest
    container_name: dump978
    environment:
      - TZ=Etc/UTC
      - DUMP978_SDR=driver=rtlsdr
    volumes:
      - config:/config
      - dump978-run:/run/dump978-fa
    ports:
      - 8978:8978    # SkyAware978 Web UI (HTTP)
      - 30978:30978  # Raw UAT messages
      - 30979:30979  # Decoded JSON messages
    devices:
      - /dev/bus/usb:/dev/bus/usb
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - DAC_OVERRIDE
      - FOWNER
      - SETUID
      - SETGID
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /tmp
      - /run:exec
    restart: unless-stopped

volumes:
  config:
  dump978-run:
```

### docker-compose paired with readsb

```yaml
---
services:
  readsb:
    image: blackoutsecure/readsb:latest
    container_name: readsb
    environment:
      - TZ=Etc/UTC
    volumes:
      - readsb-config:/config
      - readsb-run:/run/readsb
    devices:
      - /dev/bus/usb:/dev/bus/usb
    tmpfs:
      - /tmp
      - /run:exec
    restart: unless-stopped

  dump978:
    image: blackoutsecure/dump978:latest
    container_name: dump978
    environment:
      - TZ=Etc/UTC
      - DUMP978_SDR=driver=rtlsdr
    volumes:
      - dump978-config:/config
      - dump978-run:/run/dump978-fa
    ports:
      - 8978:8978
      - 30978:30978
      - 30979:30979
    devices:
      - /dev/bus/usb:/dev/bus/usb
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - DAC_OVERRIDE
      - FOWNER
      - SETUID
      - SETGID
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /tmp
      - /run:exec
    restart: unless-stopped

volumes:
  readsb-config:
  readsb-run:
  dump978-config:
  dump978-run:
```

### docker-cli ([click here for more info](https://docs.docker.com/engine/reference/commandline/cli/))

```bash
docker run -d \
  --name=dump978 \
  -e TZ=Etc/UTC \
  -e DUMP978_SDR=driver=rtlsdr \
  -p 8978:8978 \
  -p 30978:30978 \
  -p 30979:30979 \
  -v /path/to/dump978/config:/config \
  -v /run/dump978-fa:/run/dump978-fa \
  --device /dev/bus/usb:/dev/bus/usb \
  --restart unless-stopped \
  blackoutsecure/dump978:latest
```

### Balena Deployment

This image can be deployed to Balena-powered IoT devices using the included `docker-compose.yml` file (which contains the required Balena labels):

- Balena block listing: [https://hub.balena.io/blocks/dump978](https://hub.balena.io/blocks/dump978)

```bash
balena push <your-app-slug>
```

For deployment via the web interface, use the deploy button in this repository. See [Balena documentation](https://docs.balena.io/) for details.

## Parameters

### Ports

| Parameter | Function |
| :----: | --- |
| `-p 8978:8978` | SkyAware978 Web UI (HTTP) |
| `-p 30978:30978` | Raw UAT messages |
| `-p 30979:30979` | Decoded JSON messages |

### Environment Variables

#### Feed Profile

| Parameter | Function | Required |
| :----: | --- | :---: |
| `-e DUMP978_PROFILE=adsbexchange` | Feed profile: `flightaware` or `adsbexchange`. Controls default branding, feeder behavior, and TIS-B filtering. See [Feed Profiles](#feed-profiles). | Optional |
| `-e DUMP978_TISB_FILTER=` | Filter out TIS-B traffic. Default depends on profile: `false` for `flightaware`, `true` for `adsbexchange`. | Optional |
| `-e DUMP978_ENABLE_FAUP978=` | Enable faup978 FlightAware reporter. Default depends on profile: `true` for `flightaware`, `false` for `adsbexchange`. | Optional |

#### Core Settings

| Parameter | Function | Required |
| :----: | --- | :---: |
| `-e TZ=Etc/UTC` | Timezone ([TZ database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List)) | Optional |
| `-e DUMP978_SDR=driver=rtlsdr` | SoapySDR device string for the SDR receiver | Optional |
| `-e DUMP978_SDR_GAIN=` | Manual SDR gain setting (overrides auto-gain if set) | Optional |
| `-e DUMP978_SDR_AUTO_GAIN=true` | Enable automatic gain control (`true`/`false`) | Optional |
| `-e DUMP978_RAW_PORT=30978` | TCP port for raw UAT messages | Optional |
| `-e DUMP978_JSON_PORT=30979` | TCP port for decoded JSON messages | Optional |
| `-e DUMP978_EXTRA_ARGS=` | Additional arguments passed to dump978-fa | Optional |
| `-e DUMP978_WEB_PORT=8978` | HTTP port for the SkyAware978 web UI | Optional |
| `-e DUMP978_USER=abc` | Runtime user | Optional |
| `-e PUID=911` | User ID for file ownership | Optional |
| `-e PGID=911` | Group ID for file ownership | Optional |

#### SDR Advanced Tuning

| Parameter | Function | Required |
| :----: | --- | :---: |
| `-e DUMP978_SDR_PPM=` | Frequency correction in PPM (critical for many RTL-SDR dongles) | Optional |
| `-e DUMP978_SDR_ANTENNA=` | SDR antenna name (for multi-antenna devices) | Optional |
| `-e DUMP978_SDR_DEVICE_SETTINGS=` | SoapySDR device key-value settings | Optional |
| `-e DUMP978_SDR_STREAM_SETTINGS=` | SoapySDR stream key-value settings | Optional |
| `-e DUMP978_FORMAT=` | Sample format: `CU8`, `CS8`, `CS16H`, `CF32H` | Optional |
| `-e DUMP978_RAW_LEGACY_PORT=` | TCP port for raw messages without metadata header (legacy clients) | Optional |
| `-e DUMP978_STRATUX=` | Stratux v3 serial device path (e.g. `/dev/ttyUSB0`); replaces SDR input | Optional |

#### Location & Statistics

| Parameter | Function | Required |
| :----: | --- | :---: |
| `-e DUMP978_LAT=` | Receiver latitude (e.g. `47.6062`) — enables site marker and range rings | Optional |
| `-e DUMP978_LON=` | Receiver longitude (e.g. `-122.3321`) — enables site marker and range rings | Optional |
| `-e DUMP978_AUTO_LOCATION=true` | Auto-detect location via IP geolocation when LAT/LON not set | Optional |
| `-e DUMP978_FA_STATS_URL=` | FlightAware stats page URL (e.g. `https://flightaware.com/adsb/stats/user/yourname`). Used when profile is `flightaware`. | Optional |
| `-e DUMP978_ADSBX_STATS_URL=` | ADS-B Exchange stats page URL (e.g. `https://www.adsbexchange.com/myip/`). Used when profile is `adsbexchange`. | Optional |
| `-e DUMP978_STATS_URL=` | Generic stats URL fallback — used if the profile-specific URL above is empty | Optional |

#### faup978 FlightAware Reporter

| Parameter | Function | Required |
| :----: | --- | :---: |
| `-e DUMP978_ENABLE_FAUP978=` | Enable faup978 FlightAware UAT data reporter (`true`/`false`). Default depends on profile. | Optional |
| `-e FAUP978_CONNECT=` | Override host:port to connect to (default: `localhost:30978`) | Optional |

#### skyaware978 Tuning

| Parameter | Function | Required |
| :----: | --- | :---: |
| `-e SKYAWARE978_RECONNECT_INTERVAL=30` | Seconds to wait before reconnecting on connection failure | Optional |
| `-e SKYAWARE978_HISTORY_COUNT=120` | Number of history JSON files to maintain | Optional |
| `-e SKYAWARE978_HISTORY_INTERVAL=30` | Seconds between history file captures | Optional |
| `-e SKYAWARE978_CONNECT=` | Override host:port to connect to (default: `localhost:30978`) | Optional |
| `-e SKYAWARE978_WRITE_DIR=` | Override JSON output directory (default: `/run/skyaware978`) | Optional |
| `-e SKYAWARE978_EXTRA_ARGS=` | Additional arguments passed to skyaware978 | Optional |

#### SkyAware Web UI Customization

Settings can be configured via environment variables, or by placing a complete custom `config.js` file at `/config/skyaware978-config.js` (takes priority over env vars). The active [feed profile](#feed-profiles) sets default values for `SKYAWARE_PAGE_NAME` and `SKYAWARE_SITE_NAME`; explicit env vars override them.

| Parameter | Function | Required |
| :----: | --- | :---: |
| `-e SKYAWARE_PAGE_NAME=` | Browser title and page header. Default: `SkyAware978` (FlightAware) or `ADS-B Exchange UAT` (ADSBx) | Optional |
| `-e SKYAWARE_SITE_NAME=` | Tooltip text for the site marker. Default: `FlightAware UAT` or `ADS-B Exchange` | Optional |
| `-e SKYAWARE_DISPLAY_UNITS=` | Default units: `nautical`, `metric`, or `imperial` | Optional |
| `-e SKYAWARE_DEFAULT_CENTER_LAT=` | Default map center latitude | Optional |
| `-e SKYAWARE_DEFAULT_CENTER_LON=` | Default map center longitude | Optional |
| `-e SKYAWARE_DEFAULT_ZOOM=` | Default map zoom level (0–16) | Optional |
| `-e SKYAWARE_SITE_CIRCLES=` | Show range rings (`true`/`false`) | Optional |
| `-e SKYAWARE_SITE_CIRCLES_COUNT=` | Number of range rings (default: `3`) | Optional |
| `-e SKYAWARE_SITE_CIRCLES_BASE=` | Base distance for first ring | Optional |
| `-e SKYAWARE_SITE_CIRCLES_INTERVAL=` | Distance between rings | Optional |
| `-e SKYAWARE_SHOW_FLAGS=` | Show country flags (`true`/`false`) | Optional |
| `-e SKYAWARE_CHARTBUNDLE=` | Enable ChartBundle US sectional chart layers (`true`/`false`) | Optional |
| `-e SKYAWARE_BING_API_KEY=` | Bing Maps API key for satellite imagery | Optional |
| `-e SKYAWARE_EXTENDED_DATA=` | Show extended Mode S EHS / ADS-B v2 data (`true`/`false`) | Optional |
| `-e SKYAWARE_PLANE_COUNT_IN_TITLE=` | Show aircraft count in page title (`true`/`false`) | Optional |
| `-e SKYAWARE_MSG_RATE_IN_TITLE=` | Show message rate in page title (`true`/`false`) | Optional |

### Storage Mounts

| Parameter | Function | Required |
| :----: | --- | :---: |
| `-v /config` | Persistent configuration | Recommended |
| `-v /run/dump978-fa` | Decoder output directory | Recommended |

---

## Volume Details

The container uses two volumes:

### `/config` — Configuration & Persistence

- **Purpose**: Stores persistent configuration files (`dump978-fa`, `skyaware978`)
- **Example**: `-v /path/to/dump978/config:/config` or `-v dump978-config:/config`

### `/run/dump978-fa` — Decoder Output

- **Purpose**: Runtime output directory for dump978-fa data accessible by other containers
- **Example**: `-v /run/dump978-fa:/run/dump978-fa` or `-v dump978-run:/run/dump978-fa`

---

## Configuration

Environment variables are set using `-e` flags in `docker run` or the `environment:` section in docker-compose.

Configuration files are stored in `/config` inside the container. On first run, default configuration files are created at `/config/dump978-fa` and `/config/skyaware978`.

### Feed Profiles

Set `DUMP978_PROFILE` to switch between preconfigured defaults for different ADS-B networks. The profile controls branding, feeder behavior, and filtering — every default can still be overridden with explicit env vars.

| | `flightaware` | `adsbexchange` (default) |
| --- | --- | --- |
| **Web UI page name** | SkyAware978 | ADS-B Exchange UAT |
| **Site name** | FlightAware UAT | ADS-B Exchange |
| **faup978 feeder** | Enabled | Disabled |
| **TIS-B filtering** | Off (`false`) | On (`true`) |
| **Stats URL source** | `DUMP978_FA_STATS_URL` | `DUMP978_ADSBX_STATS_URL` |
| **status.json radio type** | `dump978-fa` | `dump978-fa (ADS-B Exchange)` |

Example — switch to FlightAware profile:

```yaml
environment:
  DUMP978_PROFILE: "flightaware"
  DUMP978_FA_STATS_URL: "https://flightaware.com/adsb/stats/user/yourname"
```

Example — ADS-B Exchange profile (default):

```yaml
environment:
  DUMP978_PROFILE: "adsbexchange"
  DUMP978_ADSBX_STATS_URL: "https://www.adsbexchange.com/myip/"
```

You can set both stats URLs and switch profiles at will — only the active profile's URL is used.

### dump978-fa Options

| Variable | Default | Description |
| --- | --- | --- |
| `DUMP978_SDR` | `driver=rtlsdr` | SoapySDR device string |
| `DUMP978_SDR_GAIN` | *(blank)* | Manual SDR gain setting (overrides auto-gain if set) |
| `DUMP978_SDR_AUTO_GAIN` | `true` | Enable automatic gain control |
| `DUMP978_SDR_PPM` | *(blank)* | Frequency correction in PPM |
| `DUMP978_SDR_ANTENNA` | *(blank)* | SDR antenna name |
| `DUMP978_SDR_DEVICE_SETTINGS` | *(blank)* | SoapySDR device key-value settings |
| `DUMP978_SDR_STREAM_SETTINGS` | *(blank)* | SoapySDR stream key-value settings |
| `DUMP978_FORMAT` | *(auto-detect)* | Sample format: `CU8`, `CS8`, `CS16H`, `CF32H` |
| `DUMP978_STRATUX` | *(blank)* | Stratux v3 serial device (replaces SDR input) |
| `DUMP978_RAW_PORT` | `30978` | TCP port for raw UAT messages |
| `DUMP978_JSON_PORT` | `30979` | TCP port for decoded JSON messages |
| `DUMP978_RAW_LEGACY_PORT` | *(blank)* | TCP port for raw messages without metadata header |
| `DUMP978_EXTRA_ARGS` | *(blank)* | Additional dump978-fa command-line arguments |

To select a specific RTL-SDR dongle by serial number: `DUMP978_SDR=driver=rtlsdr,serial=01234567`

### skyaware978 Options

| Variable | Default | Description |
| --- | --- | --- |
| `SKYAWARE978_CONNECT` | `localhost:30978` | dump978-fa raw port to connect to |
| `SKYAWARE978_WRITE_DIR` | `/run/skyaware978` | Directory for JSON output files |
| `SKYAWARE978_RECONNECT_INTERVAL` | `30` | Seconds to wait before reconnecting on failure |
| `SKYAWARE978_HISTORY_COUNT` | `120` | Number of history JSON files to maintain |
| `SKYAWARE978_HISTORY_INTERVAL` | `30` | Seconds between history file captures |
| `SKYAWARE978_EXTRA_ARGS` | *(blank)* | Additional skyaware978 command-line arguments |

### faup978 Options (FlightAware Reporter)

The `faup978` binary re-encodes UAT messages into FlightAware's format for stats collection. It is **enabled by default with the `flightaware` profile** and **disabled by default with the `adsbexchange` profile**. Override with `DUMP978_ENABLE_FAUP978`.

| Variable | Default | Description |
| --- | --- | --- |
| `DUMP978_ENABLE_FAUP978` | Profile-dependent | Enable faup978 service (`true`/`false`) |
| `FAUP978_CONNECT` | `localhost:30978` | Override host:port to connect to |

### Custom Configuration via Volume Mount

You can supply custom config files via volume mounts:

```yaml
volumes:
  - ./my-dump978-config:/config/dump978-fa:ro
  - ./my-skyaware978-config:/config/skyaware978:ro
  - ./my-skyaware-config.js:/config/skyaware978-config.js:ro
```

---

## Application Setup

The container runs four services under s6-overlay:

1. **dump978-fa** — the main 978 MHz UAT decoder that talks to the SDR hardware via SoapySDR, demodulates UAT data, and provides raw and JSON-decoded messages on TCP ports
2. **skyaware978** — connects to dump978-fa and writes JSON files suitable for the SkyAware web map interface
3. **nginx** — serves the SkyAware978 HTML interface and live aircraft JSON data
4. **faup978** *(optional, profile-dependent)* — re-encodes UAT messages and reports to FlightAware for stats collection. Enabled by default with the `flightaware` profile; override with `DUMP978_ENABLE_FAUP978=true`

### SDR Device Access

The container requires access to the USB SDR device. Pass `--device /dev/bus/usb:/dev/bus/usb` to grant USB access, or pass only the specific device node.

If using multiple RTL-SDR dongles (e.g., one for 1090 MHz and one for 978 MHz), use the serial number to select the correct dongle:

```bash
-e DUMP978_SDR=driver=rtlsdr,serial=978
```

Assign serial numbers to dongles using `rtl_eeprom -s 978`.

---

## Troubleshooting

### No SDR device found

1. Verify USB device passthrough is configured:

   ```bash
   docker exec dump978 lsusb
   docker exec dump978 SoapySDRUtil --find
   ```

2. If the device is not visible:
   - Ensure `--device /dev/bus/usb:/dev/bus/usb` is set
   - Check that no other process (e.g., kernel DVB driver) is claiming the device
   - Blacklist the kernel DVB driver: `echo 'blacklist dvb_usb_rtl28xxu' | sudo tee /etc/modprobe.d/blacklist-rtlsdr.conf`

### No data / empty web UI

1. Check that dump978-fa is running and connected to the SDR:

   ```bash
   docker exec dump978 s6-svstat /run/service/svc-dump978-fa
   docker logs dump978 --tail 50
   ```

2. Verify you are in an area with 978 MHz UAT traffic (US only — UAT is not used outside the United States)

### Port conflict

Map to different host ports:

```bash
docker run ... -p 9978:8978 -p 31978:30978 -p 31979:30979 ...
```

### View logs

```bash
docker logs dump978
docker logs dump978 --tail 100 -f
```

### Check service status

```bash
docker exec dump978 s6-svstat /run/service/svc-dump978-fa
docker exec dump978 s6-svstat /run/service/svc-skyaware978
docker exec dump978 s6-svstat /run/service/svc-nginx
```

### Getting help

- Check [upstream dump978 documentation](https://github.com/flightaware/dump978)
- Review container logs: `docker logs -f dump978`
- Open an issue on [GitHub](https://github.com/blackoutsecure/docker-dump978/issues)

---

## Release & Versioning

This project uses [semantic versioning](https://semver.org/):

- Releases published on [GitHub Releases](https://github.com/blackoutsecure/docker-dump978/releases)
- Multi-arch images (amd64, arm64v8) built automatically
- Docker Hub tags: version-specific, `latest`, and architecture-specific

**Update to latest:**

```bash
docker pull blackoutsecure/dump978:latest
docker-compose up -d  # if using compose
```

**Check image version:**

```bash
docker inspect -f '{{ index .Config.Labels "build_version" }}' blackoutsecure/dump978:latest
```

---

## Support & Getting Help

- **Questions:** [GitHub Issues](https://github.com/blackoutsecure/docker-dump978/issues)
- **Bug Reports:** Include Docker version, container logs, and reproduction steps
- **Upstream Documentation:** [dump978 on GitHub](https://github.com/flightaware/dump978)

**Get help:**

```bash
docker logs dump978                          # View container logs
docker exec -it dump978 /bin/bash           # Access container shell
docker inspect blackoutsecure/dump978          # Check image details
```

---

## Sponsor & Credits

Sponsored and maintained by [Blackout Secure](https://blackoutsecure.app)

Upstream project: [flightaware/dump978](https://github.com/flightaware/dump978)
Container patterns: [LinuxServer.io](https://linuxserver.io/)

---

## References

### Project Resources

| Resource | Link |
| --- | --- |
| **Docker Hub** | [blackoutsecure/dump978](https://hub.docker.com/r/blackoutsecure/dump978) |
| **GitHub Issues** | [Report bugs or request features](https://github.com/blackoutsecure/docker-dump978/issues) |
| **GitHub Releases** | [Download releases](https://github.com/blackoutsecure/docker-dump978/releases) |

### Upstream & Related

| Project | Link |
| --- | --- |
| **dump978** | [flightaware/dump978](https://github.com/flightaware/dump978) |
| **readsb** | [wiedehopf/readsb](https://github.com/wiedehopf/readsb) |
| **LinuxServer.io** | [linuxserver.io](https://linuxserver.io/) |

### Technical Resources

- [ADS-B Overview](https://en.wikipedia.org/wiki/Automatic_Dependent_Surveillance%E2%80%93Broadcast)
- [UAT Overview](https://en.wikipedia.org/wiki/Universal_access_transceiver)
- [Docker Documentation](https://docs.docker.com/)
- [SoapySDR Documentation](https://github.com/pothosware/SoapySDR/wiki)

---

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/blackoutsecure/docker-dump978/blob/main/LICENSE) file for details.

The upstream dump978 application is licensed under the BSD 2-Clause License. For more information, see the [dump978 repository](https://github.com/flightaware/dump978).

Made with confidence by [Blackout Secure](https://blackoutsecure.app)
