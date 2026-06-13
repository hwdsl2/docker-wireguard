---
name: Bug report
about: Tell us about a problem you are experiencing
title: ''
labels: ''
assignees: ''

---
**Checklist**

- [ ] I read the [README](https://github.com/hwdsl2/docker-wireguard/blob/main/README.md) or the relevant section
- [ ] I searched existing [Issues](https://github.com/hwdsl2/docker-wireguard/issues?q=is%3Aissue)
- [ ] This issue is about the WireGuard Docker image/config, not only WireGuard itself or a client app

<!---
If this is a client app or VPN protocol issue rather than this Docker image/config, please check the relevant upstream/client support resources.
--->

**Describe the issue**
A clear and concise description of the problem.

**To Reproduce**
Steps to reproduce the behavior:

1. ...
2. ...

**Expected behavior**
A clear and concise description of what you expected to happen.

**Server environment**
- Docker host OS: [e.g. Ubuntu 24.04]
- Hosting provider (if applicable): [e.g. AWS, GCP, home server]
- CPU architecture: [e.g. amd64, arm64, arm/v7]
- Image/tag: [e.g. `hwdsl2/wireguard-server:latest`]
- Start method: [docker run / docker compose / other]
- VPN port/protocol: [51820/udp by default]
- Public IP/DNS setup:

**Configuration**
Remove secrets, keys and public client configs before posting.

- Env file or variables changed: [vpn.env / `-e` / compose `environment`]
- Docker run or compose changes:
- `docker exec wireguard wg_manage --help` output or related `wg_manage` command output:

**Client information**
- Device: [e.g. iPhone 15, Windows laptop]
- OS: [e.g. iOS 17, Windows 11]
- Client app/version: [WireGuard app]
- Client config involved: [client.conf]

**Logs**
Add relevant logs with secrets removed.

```bash
docker logs wireguard
```

If using Docker Compose, you can also include:

```bash
docker compose logs wireguard
```

**Additional context**
Add any other context about the problem here.
