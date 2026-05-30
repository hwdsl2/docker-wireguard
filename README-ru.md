[English](README.md) | [简体中文](README-zh.md) | [繁體中文](README-zh-Hant.md) | [Русский](README-ru.md)

# Сервер WireGuard VPN на Docker

[![Build Status](https://github.com/hwdsl2/docker-wireguard/actions/workflows/main.yml/badge.svg)](https://github.com/hwdsl2/docker-wireguard/actions/workflows/main.yml) &nbsp;[![Docker Pulls](https://raw.githubusercontent.com/hwdsl2/badges/main/img/docker-pulls-wireguard-server.svg)](https://hub.docker.com/r/hwdsl2/wireguard-server) &nbsp;[![License: MIT](docs/images/license.svg)](https://opensource.org/licenses/MIT)

Docker-образ для запуска сервера WireGuard VPN. Основан на Alpine Linux с WireGuard. Разработан как простой, современный и легко поддерживаемый.

**Возможности:**

- Автоматическая генерация ключей сервера и конфигурации клиента при первом запуске
- Управление клиентами через вспомогательный скрипт (`wg_manage`)
- QR-код отображается при первом запуске для быстрой настройки мобильных устройств
- Поддержка ядрового WireGuard (5.6+) с автоматическим переключением на `wireguard-go` (пользовательское пространство)
- Поддержка двойного стека IPv4 и IPv6 для VPN-клиентов
- Автоматически собирается и публикуется через [GitHub Actions](https://github.com/hwdsl2/docker-wireguard/actions/workflows/main.yml)
- Постоянное хранение данных через Docker volume
- Поддержка нескольких архитектур: `linux/amd64`, `linux/arm64`, `linux/arm/v7`

**Также доступно:**

- Без Docker: [Скрипт установки WireGuard](https://github.com/hwdsl2/wireguard-install/blob/master/README-ru.md)
- VPN: [OpenVPN](https://github.com/hwdsl2/docker-openvpn/blob/main/README-ru.md), [IPsec VPN](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-ru.md), [Headscale](https://github.com/hwdsl2/docker-headscale/blob/main/README-ru.md)
- AI: [Стек ИИ на своём сервере](https://github.com/hwdsl2/docker-ai-stack/blob/main/README-ru.md)

## Быстрый старт

**Шаг 1.** Запустите сервер WireGuard:

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

При первом запуске сервер автоматически генерирует ключи сервера, файл `wg0.conf` и конфигурацию клиента с именем `client.conf`. В логи контейнера также выводится QR-код для быстрой настройки мобильных устройств.

**Шаг 2.** Просмотрите логи контейнера, чтобы получить QR-код клиента:

```bash
docker logs wireguard
```

Отсканируйте QR-код приложением WireGuard на телефоне для мгновенного подключения.

**Шаг 3.** По желанию, скопируйте конфигурацию клиента на локальную машину:

```bash
docker cp wireguard:/etc/wireguard/clients/client.conf .
```

Импортируйте `client.conf` в любой клиент WireGuard для подключения.

В качестве альтернативы вы можете [настроить WireGuard VPN без Docker](https://github.com/hwdsl2/wireguard-install/blob/master/README-ru.md). Чтобы узнать больше о том, как использовать этот образ, прочитайте разделы ниже.

## Сообщество

- 📬 [Подписаться на обновления проектов](https://selfhostedstack.beehiiv.com/subscribe?utm_campaign=vpn-ru) (1–2 письма в месяц) — получить бесплатные руководства по развёртыванию VPN и AI (PDF, на английском)
- 💬 Присоединяйтесь к сообществу [r/selfhostedstack](https://www.reddit.com/r/selfhostedstack/) для обсуждений и демонстрации проектов
- ⭐ Поставьте звезду репозиторию, если он вам полезен

## Требования

- Linux-сервер с публичным IP-адресом или DNS-именем
- Установленный Docker
- Открытый в файрволе UDP-порт WireGuard (по умолчанию UDP 51820, или настроенный порт)
- Ядро хоста 5.6+ с поддержкой WireGuard (рекомендуется), **или** используйте встроенный резервный вариант `wireguard-go` (работает на любом ядре)

## Загрузка

Получите образ из [реестра Docker Hub](https://hub.docker.com/r/hwdsl2/wireguard-server/):

```bash
docker pull hwdsl2/wireguard-server
```

Либо загрузите из [Quay.io](https://quay.io/repository/hwdsl2/wireguard-server):

```bash
docker pull quay.io/hwdsl2/wireguard-server
docker image tag quay.io/hwdsl2/wireguard-server hwdsl2/wireguard-server
```

Поддерживаемые платформы: `linux/amd64`, `linux/arm64` и `linux/arm/v7`.

## Переменные окружения

Все переменные необязательны. Если не заданы, автоматически используются безопасные значения по умолчанию.

Этот Docker-образ использует следующие переменные, которые можно задать в файле `env` (см. [пример](vpn.env.example)):

| Переменная | Описание | Значение по умолчанию |
|---|---|---|
| `VPN_DNS_NAME` | Полное доменное имя (FQDN) сервера | Автоопределение публичного IP |
| `VPN_PUBLIC_IP` | Публичный IPv4-адрес сервера | Автоопределение |
| `VPN_PUBLIC_IP6` | Публичный IPv6-адрес сервера | Автоопределение |
| `VPN_PORT` | UDP-порт WireGuard (1–65535) | `51820` |
| `VPN_CLIENT_NAME` | Имя первого сгенерированного конфига клиента | `client` |
| `VPN_DNS_SRV1` | Основной DNS-сервер, передаваемый клиентам | `8.8.8.8` |
| `VPN_DNS_SRV2` | Резервный DNS-сервер, передаваемый клиентам | `8.8.4.4` |

**Примечание:** В файле `env` можно заключать значения в одинарные кавычки, например `VAR='значение'`. Не добавляйте пробелы вокруг `=`. Если вы изменили `VPN_PORT`, соответственно обновите флаг `-p` в команде `docker run`.

Пример использования файла `env`:

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

Файл env монтируется в контейнер через bind mount, поэтому изменения применяются при каждом перезапуске контейнера без его пересоздания.

## Управление клиентами

Используйте `docker exec` для управления клиентами с помощью вспомогательного скрипта `wg_manage`.

**Добавить нового клиента:**

```bash
docker exec wireguard wg_manage --addclient alice
docker cp wireguard:/etc/wireguard/clients/alice.conf .
```

**Показать QR-код клиента** (например, после перезапуска):

```bash
docker exec wireguard wg_manage --showclientqr alice
```

**Экспортировать конфигурацию клиента** (выводится в stdout):

```bash
docker exec wireguard wg_manage --showclientcfg alice > alice.conf
```

**Список клиентов:**

```bash
docker exec wireguard wg_manage --listclients
```

**Удалить клиента** (будет запрошено подтверждение):

```bash
docker exec -it wireguard wg_manage --removeclient alice
# Или удалить без запроса подтверждения:
docker exec wireguard wg_manage --removeclient alice -y
```

## Модуль ядра и пользовательское пространство

Этот образ поддерживает два бэкенда WireGuard, которые выбираются автоматически при запуске:

1. **Модуль ядра** (предпочтительно) — доступен на ядре Linux 5.6+ (Ubuntu 20.04+, Debian 11+ и большинстве современных дистрибутивов). Обеспечивает наилучшую производительность.

2. **`wireguard-go` в пользовательском пространстве** (автоматический резерв) — используется, когда модуль ядра недоступен. Работает на любом ядре хоста. Производительность несколько ниже, но полностью функционален.

При активном `wireguard-go` в логи контейнера выводится соответствующее сообщение. Дополнительная настройка не требуется — переключение прозрачно.

Чтобы использовать модуль ядра, убедитесь, что он доступен на хосте:

```bash
# Проверить, загружен ли модуль на хосте
lsmod | grep wireguard
# Загрузить при необходимости
sudo modprobe wireguard
```

Флаг `--cap-add=SYS_MODULE` в команде `docker run` позволяет контейнеру загружать модуль ядра. Если модуль уже загружен на хосте, `SYS_MODULE` строго не требуется.

## Постоянные данные

Все данные сервера и клиентов хранятся в Docker volume (`/etc/wireguard` внутри контейнера):

```
/etc/wireguard/
├── wg0.conf            # Конфигурация сервера WireGuard (интерфейс + все клиенты)
└── clients/
    ├── client.conf     # Конфигурация первого клиента
    └── alice.conf      # Дополнительные клиенты
```

Сделайте резервную копию Docker volume для сохранения ключей сервера и всех конфигураций клиентов.

## Поддержка IPv6

Если Docker-хост имеет публичный (глобальный одноадресный) IPv6-адрес и выполнены приведённые ниже требования, поддержка IPv6 автоматически включается при запуске контейнера. Никакой дополнительной настройки не требуется.

**Требования:**
- Docker-хост должен иметь маршрутизируемый глобальный одноадресный IPv6-адрес (начинающийся с `2` или `3`). Локальные адреса канала (`fe80::/10`) не подходят.
- Для Docker-контейнера должна быть включена поддержка IPv6. См. [Enable IPv6 support in Docker](https://docs.docker.com/engine/daemon/ipv6/).

Чтобы включить IPv6 для Docker-контейнера, сначала включите IPv6 в демоне Docker, добавив следующее в файл `/etc/docker/daemon.json` на Docker-хосте, затем перезапустите Docker:

```json
{
  "ipv6": true,
  "fixed-cidr-v6": "fddd:1::/64"
}
```

После этого пересоздайте Docker-контейнер. Чтобы проверить работу IPv6, подключитесь к VPN и проверьте ваш IPv6-адрес, например, с помощью [test-ipv6.com](https://test-ipv6.com).

## Использование docker-compose

```bash
cp vpn.env.example vpn.env
# При необходимости отредактируйте vpn.env, затем:
docker compose up -d
docker logs wireguard
```

Пример `docker-compose.yml` (уже включён):

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

## Обновление Docker-образа

Для обновления Docker-образа и контейнера сначала [загрузите](#загрузка) последнюю версию:

```bash
docker pull hwdsl2/wireguard-server
```

Если Docker-образ уже актуален, вы увидите:

```
Status: Image is up to date for hwdsl2/wireguard-server:latest
```

В противном случае будет загружена последняя версия. Удалите и пересоздайте контейнер, следуя инструкциям из раздела [Быстрый старт](#быстрый-старт). Ваши данные сохранены в volume `wireguard-data`.

## Технические детали

- Базовый образ: `alpine:3.23`
- WireGuard: последняя версия `wireguard-tools` из пакетов Alpine
- Резервный вариант в пользовательском пространстве: `wireguard-go` из пакетов Alpine
- Подсеть VPN: `10.7.0.0/24` (сервер: `10.7.0.1`, клиенты: `10.7.0.2`+)
- Подсеть VPN IPv6: `fddd:2c4:2c4:2c4::/64` (при наличии IPv6 на сервере)
- Предварительно общие ключи: генерируются для каждого клиента для дополнительной прямой секретности
- Keepalive по умолчанию: 25 секунд (обеспечивает NAT traversal для мобильных клиентов)
- Шифр: ChaCha20-Poly1305 (стандарт WireGuard, не настраивается)

## Лицензия

**Примечание:** Программные компоненты внутри предсобранного образа (такие как WireGuard tools и wireguard-go) распространяются под соответствующими лицензиями, выбранными их правообладателями. При использовании любого предсобранного образа пользователь несёт ответственность за соблюдение всех соответствующих лицензий на программное обеспечение, содержащееся в образе.

Copyright (C) 2026 Lin Song   
Эта работа распространяется под [лицензией MIT](https://opensource.org/licenses/MIT).

Этот проект частично основан на работе [Nyr и участников проекта](https://github.com/Nyr/wireguard-install), распространяемой под [лицензией MIT](https://github.com/Nyr/wireguard-install/blob/master/LICENSE).
