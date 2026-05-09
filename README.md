[English](README.md) | [简体中文](README-zh.md) | [繁體中文](README-zh-Hant.md) | [Русский](README-ru.md)

# WireGuard VPN Server on Docker

[![Build Status](https://github.com/hwdsl2/docker-wireguard/actions/workflows/main.yml/badge.svg)](https://github.com/hwdsl2/docker-wireguard/actions/workflows/main.yml) &nbsp;[![License: MIT](docs/images/license.svg)](https://opensource.org/licenses/MIT)

Docker image to run a WireGuard VPN server. Based on Alpine Linux with WireGuard. Designed to be simple, modern, and maintainable.

**Features:**

- Automatically generates server keys and a client config on first start
- Client management via a helper script (`wg_manage`)
- QR code displayed on first start for easy mobile setup
- Supports kernel WireGuard (5.6+) with automatic fallback to `wireguard-go` (userspace)
- Dual-stack IPv4 and IPv6 support for VPN clients
- Automatically built and published via [GitHub Actions](https://github.com/hwdsl2/docker-wireguard/actions/workflows/main.yml)
- Persistent data via a Docker volume
- Multi-arch: `linux/amd64`, `linux/arm64`, `linux/arm/v7`

**Also available:**

- Without Docker: [WireGuard install script](https://github.com/hwdsl2/wireguard-install)
- VPN: [OpenVPN](https://github.com/hwdsl2/docker-openvpn), [IPsec VPN](https://github.com/hwdsl2/docker-ipsec-vpn-server), [Headscale](https://github.com/hwdsl2/docker-headscale)
- AI/Audio: [Self-hosted AI Stack](https://github.com/hwdsl2/docker-ai-stack)

## Quick start

**Step 1.** Start the WireGuard server:

```bash
docker run \
    --name wireguard \
    --restart=always \
    -v wireguard-data:/etc/wireguard \
    -p 51820:51820/udp \
    -d --cap-add=NET_ADMIN \
    --cap-add=SYS_MODULE \
    --device=/dev/net/tun \
    --sysctl net.ipv4.ip_forward=1 \
    --sysctl net.ipv6.conf.all.forwarding=1 \
    hwdsl2/wireguard-server
```

On first start, the server automatically generates server keys, a `wg0.conf`, and a client configuration named `client.conf`. A QR code is also printed to the container logs for easy mobile setup.

**Step 2.** View the container logs to get the client QR code:

```bash
docker logs wireguard
```

Scan the QR code with the WireGuard app on your phone to connect instantly.

**Step 3.** Optionally, copy the client configuration to your local machine:

```bash
docker cp wireguard:/etc/wireguard/clients/client.conf .
```

Import `client.conf` into any WireGuard client to connect.

Alternatively, you may [set up WireGuard VPN without Docker](https://github.com/hwdsl2/wireguard-install). To learn more about how to use this image, read the sections below.

## Requirements

- A Linux server with a public IP address or DNS name
- Docker installed
- WireGuard UDP port open in your firewall (UDP 51820 by default, or your configured port)
- Host kernel 5.6+ with WireGuard support (recommended), **or** use the built-in `wireguard-go` userspace fallback (works on any kernel)

## Download

Get the trusted build from the [Docker Hub registry](https://hub.docker.com/r/hwdsl2/wireguard-server/):

```bash
docker pull hwdsl2/wireguard-server
```

Alternatively, you may download from [Quay.io](https://quay.io/repository/hwdsl2/wireguard-server):

```bash
docker pull quay.io/hwdsl2/wireguard-server
docker image tag quay.io/hwdsl2/wireguard-server hwdsl2/wireguard-server
```

Supported platforms: `linux/amd64`, `linux/arm64` and `linux/arm/v7`.

## Environment variables

All variables are optional. If not set, secure defaults are used automatically.

This Docker image uses the following variables, that can be declared in an `env` file (see [example](vpn.env.example)):

| Variable | Description | Default |
|---|---|---|
| `VPN_DNS_NAME` | Fully qualified domain name (FQDN) of the server | Auto-detected public IP |
| `VPN_PUBLIC_IP` | Public IPv4 address of the server | Auto-detected |
| `VPN_PUBLIC_IP6` | Public IPv6 address of the server | Auto-detected |
| `VPN_PORT` | WireGuard UDP port (1–65535) | `51820` |
| `VPN_CLIENT_NAME` | Name of the first client config generated | `client` |
| `VPN_DNS_SRV1` | Primary DNS server pushed to clients | `8.8.8.8` |
| `VPN_DNS_SRV2` | Secondary DNS server pushed to clients | `8.8.4.4` |

**Note:** In your `env` file, you may enclose values in single quotes, e.g. `VAR='value'`. Do not add spaces around `=`. If you change `VPN_PORT`, update the `-p` flag in the `docker run` command accordingly.

Example using an `env` file:

```bash
docker run \
    --name wireguard \
    --restart=always \
    -v wireguard-data:/etc/wireguard \
    -v ./vpn.env:/vpn.env:ro \
    -p 51820:51820/udp \
    -d --cap-add=NET_ADMIN \
    --cap-add=SYS_MODULE \
    --device=/dev/net/tun \
    --sysctl net.ipv4.ip_forward=1 \
    --sysctl net.ipv6.conf.all.forwarding=1 \
    hwdsl2/wireguard-server
```

The env file is bind-mounted into the container, so changes are picked up on every restart without recreating the container.

## Client management

Use `docker exec` to manage clients with the `wg_manage` helper script.

**Add a new client:**

```bash
docker exec wireguard wg_manage --addclient alice
docker cp wireguard:/etc/wireguard/clients/alice.conf .
```

**Show QR code for a client** (e.g. after restart):

```bash
docker exec wireguard wg_manage --showclientqr alice
```

**Export a client config** (prints to stdout):

```bash
docker exec wireguard wg_manage --showclientcfg alice > alice.conf
```

**List clients:**

```bash
docker exec wireguard wg_manage --listclients
```

**Remove a client** (will prompt for confirmation):

```bash
docker exec -it wireguard wg_manage --removeclient alice
# Or remove without confirmation prompt:
docker exec wireguard wg_manage --removeclient alice -y
```

## Kernel module vs. userspace

This image supports two WireGuard backends, selected automatically at startup:

1. **Kernel module** (preferred) — available on Linux kernel 5.6+ (Ubuntu 20.04+, Debian 11+, and most modern distributions). Provides the best performance.

2. **`wireguard-go` userspace** (automatic fallback) — used when the kernel module is unavailable. Works on any host kernel. Performance is slightly lower, but fully functional.

When `wireguard-go` is active, a note is printed to the container logs. No extra configuration is needed — the fallback is transparent.

To use the kernel module, ensure it is available on the host:

```bash
# Check if the module is loaded on the host
lsmod | grep wireguard
# Load it if needed
sudo modprobe wireguard
```

The `--cap-add=SYS_MODULE` flag in the `docker run` command allows the container to load the kernel module. If the module is already loaded on the host, `SYS_MODULE` is not strictly required.

## Persistent data

All server and client data is stored in the Docker volume (`/etc/wireguard` inside the container):

```
/etc/wireguard/
├── wg0.conf            # WireGuard server configuration (interface + all clients)
└── clients/
    ├── client.conf     # First client config
    └── alice.conf      # Additional clients
```

Back up the Docker volume to preserve your server keys and all client configurations.

## IPv6 support

If the Docker host has a public (global unicast) IPv6 address and the requirements below are met, IPv6 support is automatically enabled when the container starts. No manual configuration is needed.

**Requirements:**
- The Docker host must have a routable global unicast IPv6 address (starting with `2` or `3`). Link-local (`fe80::/10`) addresses are not sufficient.
- IPv6 must be enabled for the Docker container. See [Enable IPv6 support in Docker](https://docs.docker.com/engine/daemon/ipv6/).

To enable IPv6 for the Docker container, first enable IPv6 in the Docker daemon by adding the following to `/etc/docker/daemon.json` on the Docker host, then restart Docker:

```json
{
  "ipv6": true,
  "fixed-cidr-v6": "fddd:1::/64"
}
```

After that, re-create the Docker container. To verify that IPv6 is working, connect to the VPN and check your IPv6 address, e.g. using [test-ipv6.com](https://test-ipv6.com).

## Using docker-compose

```bash
cp vpn.env.example vpn.env
# Edit vpn.env if needed, then:
docker compose up -d
docker logs wireguard
```

Example `docker-compose.yml` (already included):

```yaml
services:
  wireguard:
    image: hwdsl2/wireguard-server
    container_name: wireguard
    restart: always
    ports:
      - "51820:51820/udp"
    volumes:
      - wireguard-data:/etc/wireguard
      - ./vpn.env:/vpn.env:ro
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    devices:
      - /dev/net/tun:/dev/net/tun
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv6.conf.all.forwarding=1

volumes:
  wireguard-data:
    name: wireguard-data
```

## Update Docker image

To update the Docker image and container, first [download](#download) the latest version:

```bash
docker pull hwdsl2/wireguard-server
```

If the Docker image is already up to date, you should see:

```
Status: Image is up to date for hwdsl2/wireguard-server:latest
```

Otherwise, it will download the latest version. Remove and re-create the container using instructions from [Quick start](#quick-start). Your data is preserved in the `wireguard-data` volume.

## Technical details

- Base image: `alpine:3.23`
- WireGuard: latest `wireguard-tools` from Alpine packages
- Userspace fallback: `wireguard-go` from Alpine packages
- VPN subnet: `10.7.0.0/24` (server: `10.7.0.1`, clients: `10.7.0.2`+)
- IPv6 VPN subnet: `fddd:2c4:2c4:2c4::/64` (when server has IPv6)
- Preshared keys: generated per client for additional forward secrecy
- Default keepalive: 25 seconds (ensures NAT traversal for mobile clients)
- Cipher: ChaCha20-Poly1305 (WireGuard default, not configurable)

## License

**Note:** The software components inside the pre-built image (such as WireGuard tools and wireguard-go) are under the respective licenses chosen by their respective copyright holders. As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

Copyright (C) 2026 Lin Song   
This work is licensed under the [MIT License](https://opensource.org/licenses/MIT).

This project is based in part on the work of [Nyr and contributors](https://github.com/Nyr/wireguard-install), licensed under the [MIT License](https://github.com/Nyr/wireguard-install/blob/master/LICENSE).