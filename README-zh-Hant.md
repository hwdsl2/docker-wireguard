[English](README.md) | [简体中文](README-zh.md) | [繁體中文](README-zh-Hant.md) | [Русский](README-ru.md)

# 在 Docker 上運行 WireGuard VPN 伺服器

[![Build Status](https://github.com/hwdsl2/docker-wireguard/actions/workflows/main.yml/badge.svg)](https://github.com/hwdsl2/docker-wireguard/actions/workflows/main.yml) &nbsp;[![Docker Pulls](https://img.shields.io/docker/pulls/hwdsl2/wireguard-server)](https://hub.docker.com/r/hwdsl2/wireguard-server) &nbsp;[![License: MIT](docs/images/license.svg)](https://opensource.org/licenses/MIT)

一個用於運行 WireGuard VPN 伺服器的 Docker 映像檔。基於 Alpine Linux，整合 WireGuard。設計目標是簡單、現代且易於維護。

**功能特性：**

- 首次啟動時自動產生伺服器金鑰和客戶端設定
- 使用輔助腳本（`wg_manage`）進行客戶端管理
- 首次啟動時在日誌中顯示 QR 碼，便於行動裝置快速設定
- 支援核心 WireGuard（5.6+），並在不可用時自動退回至 `wireguard-go`（用戶空間實作）
- 為 VPN 客戶端提供雙協定棧 IPv4 和 IPv6 支援
- 透過 [GitHub Actions](https://github.com/hwdsl2/docker-wireguard/actions/workflows/main.yml) 自動建置和發布
- 使用 Docker 卷實現資料持久化
- 多架構支援：`linux/amd64`、`linux/arm64`、`linux/arm/v7`

**另提供：**

- 不使用 Docker：[WireGuard 安裝腳本](https://github.com/hwdsl2/wireguard-install/blob/master/README-zh-Hant.md)
- VPN：[OpenVPN](https://github.com/hwdsl2/docker-openvpn/blob/main/README-zh-Hant.md)、[IPsec VPN](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh-Hant.md)、[Headscale](https://github.com/hwdsl2/docker-headscale/blob/main/README-zh-Hant.md)
- AI：[自架 AI 套件](https://github.com/hwdsl2/docker-ai-stack/blob/main/README-zh-Hant.md)

## 快速開始

**步驟 1.** 啟動 WireGuard 伺服器：

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

首次啟動時，伺服器會自動產生金鑰、`wg0.conf` 以及名為 `client.conf` 的客戶端設定檔。同時還會在容器日誌中輸出 QR 碼，方便行動裝置快速設定。

**步驟 2.** 查看容器日誌以取得客戶端 QR 碼：

```bash
docker logs wireguard
```

使用手機上的 WireGuard 應用程式掃描 QR 碼即可立即連線。

**步驟 3.** （選用）將客戶端設定檔複製到本機：

```bash
docker cp wireguard:/etc/wireguard/clients/client.conf .
```

將 `client.conf` 匯入任意 WireGuard 客戶端即可連線。

另外，你也可以在不使用 Docker 的情況下[安裝 WireGuard VPN](https://github.com/hwdsl2/wireguard-install/blob/master/README-zh-Hant.md)。若要了解更多關於如何使用本映像檔的資訊，請繼續閱讀以下部分。

## 系統需求

- 具有公用 IP 位址或 DNS 名稱的 Linux 伺服器
- 已安裝 Docker
- 防火牆中已開放 WireGuard UDP 連接埠（預設 UDP 51820，或自訂連接埠）
- 主機核心 5.6+ 並支援 WireGuard（建議），**或** 使用內建的 `wireguard-go` 用戶空間退回方案（適用於任意核心）

## 下載

從 [Docker Hub 映像檔倉庫](https://hub.docker.com/r/hwdsl2/wireguard-server/)取得可信賴的建置版本：

```bash
docker pull hwdsl2/wireguard-server
```

或從 [Quay.io](https://quay.io/repository/hwdsl2/wireguard-server) 下載：

```bash
docker pull quay.io/hwdsl2/wireguard-server
docker image tag quay.io/hwdsl2/wireguard-server hwdsl2/wireguard-server
```

支援平台：`linux/amd64`、`linux/arm64` 和 `linux/arm/v7`。

## 環境變數

所有變數均為選用。未設定時將自動使用安全預設值。

此 Docker 映像檔使用以下變數，可以在 `env` 檔案中宣告（參見[範例](vpn.env.example)）：

| 變數 | 說明 | 預設值 |
|---|---|---|
| `VPN_DNS_NAME` | 伺服器的完整網域名稱 (FQDN) | 自動偵測公用 IP |
| `VPN_PUBLIC_IP` | 伺服器的公用 IPv4 位址 | 自動偵測 |
| `VPN_PUBLIC_IP6` | 伺服器的公用 IPv6 位址 | 自動偵測 |
| `VPN_PORT` | WireGuard UDP 連接埠（1–65535） | `51820` |
| `VPN_CLIENT_NAME` | 產生的第一個客戶端設定名稱 | `client` |
| `VPN_DNS_SRV1` | 推送給客戶端的主要 DNS 伺服器 | `8.8.8.8` |
| `VPN_DNS_SRV2` | 推送給客戶端的次要 DNS 伺服器 | `8.8.4.4` |

**注：** 在 `env` 檔案中，可以用單引號括住變數值，例如 `VAR='值'`。不要在 `=` 周圍加上空格。如果修改了 `VPN_PORT`，請相應更新 `docker run` 命令中的 `-p` 參數。

使用 `env` 檔案的範例：

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

env 檔案以綁定掛載方式掛載到容器中，因此每次重新啟動容器時都會讀取最新的變數，無需重新建立容器。

## 客戶端管理

使用 `docker exec` 配合 `wg_manage` 輔助腳本管理客戶端。

**新增客戶端：**

```bash
docker exec wireguard wg_manage --addclient alice
docker cp wireguard:/etc/wireguard/clients/alice.conf .
```

**顯示客戶端 QR 碼**（例如重新啟動後）：

```bash
docker exec wireguard wg_manage --showclientqr alice
```

**匯出客戶端設定**（輸出至標準輸出）：

```bash
docker exec wireguard wg_manage --showclientcfg alice > alice.conf
```

**列出客戶端：**

```bash
docker exec wireguard wg_manage --listclients
```

**移除客戶端**（將提示確認）：

```bash
docker exec -it wireguard wg_manage --removeclient alice
# 或不提示確認直接移除：
docker exec wireguard wg_manage --removeclient alice -y
```

## 核心模組與用戶空間實作

此映像檔支援兩種 WireGuard 後端，並在啟動時自動選擇：

1. **核心模組（建議）** — 適用於 Linux 核心 5.6+（Ubuntu 20.04+、Debian 11+ 及大多數現代發行版），提供最佳效能。

2. **`wireguard-go` 用戶空間實作（自動退回）** — 在核心模組不可用時使用，相容任意主機核心，效能略低但功能完整。

當 `wireguard-go` 處於活動狀態時，容器日誌中會顯示提示，無需額外設定——退回是透明的。

如需使用核心模組，請確保主機上已啟用：

```bash
# 檢查主機上是否已載入該模組
lsmod | grep wireguard
# 如需載入
sudo modprobe wireguard
```

`docker run` 命令中的 `--cap-add=SYS_MODULE` 參數允許容器載入核心模組。如果主機上已載入該模組，則不嚴格要求 `SYS_MODULE`。

## 持久化資料

所有伺服器和客戶端資料均存放於 Docker 卷（容器內的 `/etc/wireguard`）中：

```
/etc/wireguard/
├── wg0.conf            # WireGuard 伺服器設定（介面 + 所有客戶端）
└── clients/
    ├── client.conf     # 第一個客戶端設定檔
    └── alice.conf      # 其他客戶端
```

備份 Docker 卷以保存伺服器金鑰和所有客戶端設定檔。

## IPv6 支援

如果 Docker 宿主機擁有公用（全域單播）IPv6 位址並且滿足以下要求，IPv6 支援將在容器啟動時自動啟用，無需手動設定。

**要求：**
- Docker 宿主機必須擁有可路由的全域單播 IPv6 位址（以 `2` 或 `3` 開頭）。連結本地位址（`fe80::/10`）不滿足要求。
- 必須為 Docker 容器啟用 IPv6。參見[在 Docker 中啟用 IPv6 支援](https://docs.docker.com/engine/daemon/ipv6/)。

要為 Docker 容器啟用 IPv6，首先在 Docker 宿主機上將以下內容新增至 `/etc/docker/daemon.json`，然後重新啟動 Docker：

```json
{
  "ipv6": true,
  "fixed-cidr-v6": "fddd:1::/64"
}
```

然後重新建立容器。要驗證 IPv6 是否正常運作，請連線至 VPN，然後檢查你的 IPv6 位址，例如使用 [test-ipv6.com](https://test-ipv6.com)。

## 使用 docker-compose

```bash
cp vpn.env.example vpn.env
# 如需修改，請編輯 vpn.env，然後：
docker compose up -d
docker logs wireguard
```

範例 `docker-compose.yml`（已包含在內）：

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

## 更新 Docker 映像檔

要更新 Docker 映像檔和容器，請先[下載](#下載)最新版本：

```bash
docker pull hwdsl2/wireguard-server
```

如果 Docker 映像檔已是最新版本，將顯示：

```
Status: Image is up to date for hwdsl2/wireguard-server:latest
```

否則將下載最新版本。依照[快速開始](#快速開始)中的說明刪除並重新建立容器。資料保存在 `wireguard-data` 卷中。

## 技術細節

- 基礎映像檔：`alpine:3.23`
- WireGuard：來自 Alpine 套件的最新 `wireguard-tools`
- 用戶空間退回方案：來自 Alpine 套件的 `wireguard-go`
- VPN 子網路：`10.7.0.0/24`（伺服器：`10.7.0.1`，客戶端：`10.7.0.2`+）
- IPv6 VPN 子網路：`fddd:2c4:2c4:2c4::/64`（伺服器有 IPv6 時啟用）
- 預共用金鑰：為每個客戶端產生，提供額外的前向保密性
- 預設 keepalive：25 秒（確保行動客戶端的 NAT 穿透）
- 加密演算法：ChaCha20-Poly1305（WireGuard 預設，不可設定）

## 授權條款

**注：** 預建映像檔中的軟體元件（如 WireGuard 工具和 wireguard-go）遵循各自版權持有者所選擇的相應授權條款。對於任何預建映像檔的使用，映像檔使用者有責任確保其使用符合映像檔中所有軟體的相關授權條款。

Copyright (C) 2026 Lin Song   
本作品依據 [MIT 授權條款](https://opensource.org/licenses/MIT)授權。

本專案部分基於 [Nyr 和貢獻者](https://github.com/Nyr/wireguard-install)的工作，遵循 [MIT 授權條款](https://github.com/Nyr/wireguard-install/blob/master/LICENSE)。