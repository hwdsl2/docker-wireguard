---
name: 错误报告
about: 请使用这个模板来提交 bug
title: ''
labels: ''
assignees: ''

---
**任务列表**

- [ ] 我已阅读[自述文件](https://github.com/hwdsl2/docker-wireguard/blob/main/README-zh.md)或相关章节
- [ ] 我搜索了已有的 [Issues](https://github.com/hwdsl2/docker-wireguard/issues?q=is%3Aissue)
- [ ] 这个问题是关于 WireGuard Docker 镜像/配置，而不只是 WireGuard 本身或客户端应用

<!---
如果这是客户端应用或 VPN 协议问题，而不是此 Docker 镜像/配置的问题，请查看相关上游或客户端支持资源。
--->

**问题描述**
使用清楚简明的语言描述这个问题。

**重现步骤**
重现该问题的步骤：

1. ...
2. ...

**期待的正确结果**
简要描述你期望发生的结果。

**服务器环境**
- Docker 主机操作系统: [例如 Ubuntu 24.04]
- 服务提供商（如果适用）: [例如 AWS, GCP, 家用服务器]
- CPU 架构: [例如 amd64, arm64, arm/v7]
- 镜像/标签: [例如 `hwdsl2/wireguard-server:latest`]
- 启动方式: [docker run / docker compose / 其它]
- VPN 端口/协议: [51820/udp by default]
- 公网 IP/DNS 配置：

**配置**
发布前请删除 secrets、密钥和公开客户端配置。

- 修改过的 env 文件或变量: [vpn.env / `-e` / compose `environment`]
- Docker run 或 compose 修改：
- `docker exec wireguard wg_manage --help` 输出或相关 `wg_manage` 命令输出：

**客户端信息**
- 设备: [例如 iPhone 15, Windows laptop]
- 操作系统: [例如 iOS 17, Windows 11]
- 客户端应用/版本: [WireGuard app]
- 涉及的客户端配置: [client.conf]

**日志**
请添加相关日志，并删除敏感信息。

```bash
docker logs wireguard
```

如果使用 Docker Compose，也可以包含：

```bash
docker compose logs wireguard
```

**其它信息**
添加关于该问题的其它信息。
