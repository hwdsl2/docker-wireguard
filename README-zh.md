[English](README.md) | [简体中文](README-zh.md) | [繁體中文](README-zh-Hant.md) | [Русский](README-ru.md)

# 在 Docker 上运行 WireGuard VPN 服务器

[![Build Status](https://github.com/hwdsl2/docker-wireguard/actions/workflows/main.yml/badge.svg)](https://github.com/hwdsl2/docker-wireguard/actions/workflows/main.yml) &nbsp;[![Docker Pulls](https://raw.githubusercontent.com/hwdsl2/badges/main/img/docker-pulls-wireguard-server.svg)](https://hub.docker.com/r/hwdsl2/wireguard-server) &nbsp;[![License: MIT](docs/images/license.svg)](https://opensource.org/licenses/MIT)

一个用于运行 WireGuard VPN 服务器的 Docker 镜像。基于 Alpine Linux，集成 WireGuard。设计目标是简单、现代且易于维护。

**功能特性：**

- 首次启动时自动生成服务器密钥和客户端配置
- 使用辅助脚本（`wg_manage`）进行客户端管理
- 首次启动时在日志中显示二维码，便于移动设备快速配置
- 支持内核 WireGuard（5.6+），并在不可用时自动回退到 `wireguard-go`（用户态实现）
- 为 VPN 客户端提供双栈 IPv4 和 IPv6 支持
- 通过 [GitHub Actions](https://github.com/hwdsl2/docker-wireguard/actions/workflows/main.yml) 自动构建和发布
- 使用 Docker 卷实现数据持久化
- 多架构支持：`linux/amd64`、`linux/arm64`、`linux/arm/v7`

**另提供：**

- 不使用 Docker：[WireGuard 安装脚本](https://github.com/hwdsl2/wireguard-install/blob/master/README-zh.md)
- VPN：[OpenVPN](https://github.com/hwdsl2/docker-openvpn/blob/main/README-zh.md)、[IPsec VPN](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh.md)、[Headscale](https://github.com/hwdsl2/docker-headscale/blob/main/README-zh.md)
- AI：[自托管 AI 套件](https://github.com/hwdsl2/docker-ai-stack/blob/main/README-zh.md)

## 快速开始

**步骤 1.** 启动 WireGuard 服务器：

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

首次启动时，服务器会自动生成密钥、`wg0.conf` 以及名为 `client.conf` 的客户端配置文件。同时还会在容器日志中输出二维码，方便移动设备快速配置。

**步骤 2.** 查看容器日志以获取客户端二维码：

```bash
docker logs wireguard
```

使用手机上的 WireGuard 应用扫描二维码即可立即连接。

**步骤 3.** （可选）将客户端配置文件复制到本机：

```bash
docker cp wireguard:/etc/wireguard/clients/client.conf .
```

将 `client.conf` 导入任意 WireGuard 客户端即可连接。

另外，你也可以在不使用 Docker 的情况下[安装 WireGuard VPN](https://github.com/hwdsl2/wireguard-install/blob/master/README-zh.md)。要了解更多有关如何使用本镜像的信息，请继续阅读以下部分。

## 系统要求

- 具有公网 IP 地址或 DNS 名称的 Linux 服务器
- 已安装 Docker
- 防火墙中已开放 WireGuard UDP 端口（默认 UDP 51820，或自定义端口）
- 主机内核 5.6+ 并支持 WireGuard（推荐），**或** 使用内置的 `wireguard-go` 用户态回退（适用于任意内核）

## 下载

从 [Docker Hub 镜像仓库](https://hub.docker.com/r/hwdsl2/wireguard-server/)获取可信构建：

```bash
docker pull hwdsl2/wireguard-server
```

或从 [Quay.io](https://quay.io/repository/hwdsl2/wireguard-server) 下载：

```bash
docker pull quay.io/hwdsl2/wireguard-server
docker image tag quay.io/hwdsl2/wireguard-server hwdsl2/wireguard-server
```

支持平台：`linux/amd64`、`linux/arm64` 和 `linux/arm/v7`。

## 环境变量

所有变量均为可选项。未设置时将自动使用安全默认值。

此 Docker 镜像使用以下变量，可以在 `env` 文件中声明（参见[示例](vpn.env.example)）：

| 变量 | 说明 | 默认值 |
|---|---|---|
| `VPN_DNS_NAME` | 服务器的完全限定域名 (FQDN) | 自动检测公网 IP |
| `VPN_PUBLIC_IP` | 服务器的公网 IPv4 地址 | 自动检测 |
| `VPN_PUBLIC_IP6` | 服务器的公网 IPv6 地址 | 自动检测 |
| `VPN_PORT` | WireGuard UDP 端口（1–65535） | `51820` |
| `VPN_CLIENT_NAME` | 生成的第一个客户端配置名称 | `client` |
| `VPN_DNS_SRV1` | 推送给客户端的主 DNS 服务器 | `8.8.8.8` |
| `VPN_DNS_SRV2` | 推送给客户端的备用 DNS 服务器 | `8.8.4.4` |

**注：** 在 `env` 文件中，可以用单引号括住变量值，例如 `VAR='值'`。不要在 `=` 周围添加空格。如果修改了 `VPN_PORT`，请相应更新 `docker run` 命令中的 `-p` 参数。

使用 `env` 文件的示例：

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

env 文件以绑定挂载方式挂载到容器中，因此每次重启容器时都会读取最新的变量，无需重新创建容器。

## 客户端管理

使用 `docker exec` 配合 `wg_manage` 辅助脚本管理客户端。

**添加新客户端：**

```bash
docker exec wireguard wg_manage --addclient alice
docker cp wireguard:/etc/wireguard/clients/alice.conf .
```

**显示客户端二维码**（例如重启后）：

```bash
docker exec wireguard wg_manage --showclientqr alice
```

**导出客户端配置**（输出到标准输出）：

```bash
docker exec wireguard wg_manage --showclientcfg alice > alice.conf
```

**列出客户端：**

```bash
docker exec wireguard wg_manage --listclients
```

**删除客户端**（将提示确认）：

```bash
docker exec -it wireguard wg_manage --removeclient alice
# 或不提示确认直接删除：
docker exec wireguard wg_manage --removeclient alice -y
```

## 内核模块与用户态实现

该镜像支持两种 WireGuard 后端，并在启动时自动选择：

1. **内核模块（推荐）** — 适用于 Linux 内核 5.6+（Ubuntu 20.04+、Debian 11+ 及大多数现代发行版），性能最佳。

2. **`wireguard-go` 用户态实现（自动回退）** — 在内核模块不可用时使用，兼容任意主机内核，性能略低但功能完整。

当 `wireguard-go` 处于活动状态时，容器日志中会显示提示，无需额外配置——回退是透明的。

如需使用内核模块，请确保主机上已启用：

```bash
# 检查主机上是否已加载该模块
lsmod | grep wireguard
# 如需加载
sudo modprobe wireguard
```

`docker run` 命令中的 `--cap-add=SYS_MODULE` 参数允许容器加载内核模块。如果主机上已加载该模块，则不严格要求 `SYS_MODULE`。

## 持久化数据

所有服务器和客户端数据均存储在 Docker 卷（容器内的 `/etc/wireguard`）中：

```
/etc/wireguard/
├── wg0.conf            # WireGuard 服务器配置（接口 + 所有客户端）
└── clients/
    ├── client.conf     # 第一个客户端配置
    └── alice.conf      # 其他客户端
```

备份 Docker 卷以保存服务器密钥和所有客户端配置。

## IPv6 支持

如果 Docker 宿主机拥有公共（全局单播）IPv6 地址并且满足以下要求，IPv6 支持将在容器启动时自动启用，无需手动配置。

**要求：**
- Docker 宿主机必须拥有可路由的全局单播 IPv6 地址（以 `2` 或 `3` 开头）。链路本地地址（`fe80::/10`）不满足要求。
- 必须为 Docker 容器启用 IPv6。参见[在 Docker 中启用 IPv6 支持](https://docs.docker.com/engine/daemon/ipv6/)。

要为 Docker 容器启用 IPv6，首先在 Docker 宿主机上将以下内容添加到 `/etc/docker/daemon.json`，然后重启 Docker：

```json
{
  "ipv6": true,
  "fixed-cidr-v6": "fddd:1::/64"
}
```

然后重新创建容器。要验证 IPv6 是否正常工作，请连接到 VPN，然后检查你的 IPv6 地址，例如使用 [test-ipv6.com](https://test-ipv6.com)。

## 使用 docker-compose

```bash
cp vpn.env.example vpn.env
# 如需修改，请编辑 vpn.env，然后：
docker compose up -d
docker logs wireguard
```

示例 `docker-compose.yml`（已包含在内）：

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

## 更新 Docker 镜像

要更新 Docker 镜像和容器，首先[下载](#下载)最新版本：

```bash
docker pull hwdsl2/wireguard-server
```

如果 Docker 镜像已是最新版本，将显示：

```
Status: Image is up to date for hwdsl2/wireguard-server:latest
```

否则将下载最新版本。按照[快速开始](#快速开始)中的说明删除并重新创建容器。数据保存在 `wireguard-data` 卷中。

## 技术细节

- 基础镜像：`alpine:3.23`
- WireGuard：来自 Alpine 软件包的最新 `wireguard-tools`
- 用户态回退：来自 Alpine 软件包的 `wireguard-go`
- VPN 子网：`10.7.0.0/24`（服务器：`10.7.0.1`，客户端：`10.7.0.2`+）
- IPv6 VPN 子网：`fddd:2c4:2c4:2c4::/64`（服务器有 IPv6 时启用）
- 预共享密钥：为每个客户端生成，提供额外的前向保密性
- 默认 keepalive：25 秒（确保移动客户端的 NAT 穿透）
- 加密算法：ChaCha20-Poly1305（WireGuard 默认，不可配置）

## 授权协议

**注：** 预构建镜像中的软件组件（如 WireGuard 工具和 wireguard-go）遵循各自版权持有者所选择的相应许可证。对于任何预构建镜像的使用，镜像用户有责任确保其使用符合镜像中所包含的所有软件的相关许可证。

Copyright (C) 2026 Lin Song   
本作品依据 [MIT 许可证](https://opensource.org/licenses/MIT)授权。

本项目部分基于 [Nyr 和贡献者](https://github.com/Nyr/wireguard-install)的工作，遵循 [MIT 许可证](https://github.com/Nyr/wireguard-install/blob/master/LICENSE)。