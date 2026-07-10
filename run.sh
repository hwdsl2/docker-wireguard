#!/bin/bash
#
# Docker script to configure and start a WireGuard VPN server
#
# DO NOT RUN THIS SCRIPT ON YOUR PC OR MAC! THIS IS ONLY MEANT TO BE RUN
# IN A CONTAINER!
#
# This file is part of WireGuard Docker image, available at:
# https://github.com/hwdsl2/docker-wireguard
#
# Copyright (C) 2026 Lin Song <linsongui@gmail.com>
# Copyright (C) 2020 Nyr
#
# Based on the work of Nyr and contributors at:
# https://github.com/Nyr/wireguard-install
#
# This work is licensed under the MIT License
# See: https://opensource.org/licenses/MIT

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

exiterr()  { echo "Error: $1" >&2; exit 1; }
nospaces() { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }
noquotes() { printf '%s' "$1" | sed -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/"; }

check_ip() {
  IP_REGEX='^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'
  printf '%s' "$1" | tr -d '\n' | grep -Eq "$IP_REGEX"
}

check_ip6() {
  IP6_REGEX='^[0-9a-fA-F]{0,4}(:[0-9a-fA-F]{0,4}){1,7}$'
  printf '%s' "$1" | tr -d '\n' | grep -Eq "$IP6_REGEX"
}

check_dns_name() {
  FQDN_REGEX='^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$'
  printf '%s' "$1" | tr -d '\n' | grep -Eq "$FQDN_REGEX"
}

usage_arch() {
  local arch
  arch=$(uname -m 2>/dev/null || printf 'unknown')
  case "$arch" in
    x86_64|amd64) printf 'amd64' ;;
    aarch64|arm64) printf 'arm64' ;;
    armv7l|armv7|armhf) printf 'armv7' ;;
    *) printf 'other' ;;
  esac
}

write_usage_state() {
  local state_file version tmp_file
  state_file=$1
  version=$2
  mkdir -p "$USAGE_STATE_DIR" || return 1
  tmp_file=$(mktemp "$USAGE_STATE_DIR/.usage.XXXXXX") || return 1
  printf '%s\n' "$version" > "$tmp_file" || return 1
  chmod 0644 "$tmp_file" 2>/dev/null || true
  mv "$tmp_file" "$state_file"
}

fetch_usage_asset() {
  local asset base_url
  asset=$1
  base_url=${VPN_USAGE_BASE_URL:-https://github.com/hwdsl2/vpn-extras/releases/download/v1.1.0}
  base_url=${base_url%/}
  command -v wget >/dev/null 2>&1 || return 1
  wget -q -T 5 -O /dev/null "$base_url/$asset" >/dev/null 2>&1
}

read_state_value() {
  [ -r "$1" ] || return 0
  tr -d '[:space:]' < "$1"
}

report_usage_counts() {
  local current_version arch state_file last_version action

  [ "${VPN_DISABLE_USAGE_COUNTS:-0}" != "1" ] || return 0
  $data_mounted || return 0

  current_version="${IMAGE_FLAVOR:-unknown}-${IMAGE_VER:-unknown}"
  arch=$(usage_arch)
  state_file="$USAGE_STATE_DIR/wireguard.version"
  last_version=$(read_state_value "$state_file")
  action=

  if [ -z "$last_version" ]; then
    if $data_existing; then
      action=upgrade
    else
      action=deploy
    fi
  elif [ "$last_version" != "$current_version" ]; then
    action=upgrade
  fi

  if [ -n "$action" ]; then
    if fetch_usage_asset "vpn-v1-wireguard-$action-$arch"; then
      write_usage_state "$state_file" "$current_version" || true
    fi
  fi
}

# Source bind-mounted env file if present (takes precedence over --env-file)
if [ -f /vpn.env ]; then
  # shellcheck disable=SC1091
  . /vpn.env
fi

if [ ! -f "/.dockerenv" ] && [ ! -f "/run/.containerenv" ] \
  && [ -z "$KUBERNETES_SERVICE_HOST" ] \
  && ! head -n 1 /proc/1/sched 2>/dev/null | grep -q '^run\.sh '; then
  exiterr "This script ONLY runs in a container (e.g. Docker, Podman)."
fi

# Detect WireGuard backend (kernel module or userspace wireguard-go)
WG_BACKEND=""
if ip link add test-wg0 type wireguard 2>/dev/null; then
  ip link del test-wg0 2>/dev/null
  WG_BACKEND=kernel
elif modprobe -q wireguard 2>/dev/null; then
  WG_BACKEND=kernel
elif command -v wireguard-go >/dev/null 2>&1; then
  WG_BACKEND=userspace
else
  exiterr "WireGuard is not available on this host. Ensure the host kernel supports WireGuard (kernel 5.6+) or add '--cap-add=SYS_MODULE' to your docker run command."
fi

NET_IFACE=$(route 2>/dev/null | grep -m 1 '^default' | grep -o '[^ ]*$')
[ -z "$NET_IFACE" ] && NET_IFACE=$(ip -4 route list 0/0 2>/dev/null | grep -m 1 -o 'dev [^ ]*' | awk '{print $2}')
[ -z "$NET_IFACE" ] && NET_IFACE=eth0

# Read and sanitize environment variables
VPN_DNS_NAME=$(nospaces "$VPN_DNS_NAME")
VPN_DNS_NAME=$(noquotes "$VPN_DNS_NAME")
VPN_PUBLIC_IP=$(nospaces "$VPN_PUBLIC_IP")
VPN_PUBLIC_IP=$(noquotes "$VPN_PUBLIC_IP")
VPN_PORT=$(nospaces "$VPN_PORT")
VPN_PORT=$(noquotes "$VPN_PORT")
VPN_CLIENT_NAME=$(nospaces "$VPN_CLIENT_NAME")
VPN_CLIENT_NAME=$(noquotes "$VPN_CLIENT_NAME")
VPN_DNS_SRV1=$(nospaces "$VPN_DNS_SRV1")
VPN_DNS_SRV1=$(noquotes "$VPN_DNS_SRV1")
VPN_DNS_SRV2=$(nospaces "$VPN_DNS_SRV2")
VPN_DNS_SRV2=$(noquotes "$VPN_DNS_SRV2")
if [ -n "$VPN_PUBLIC_IP6" ]; then
  VPN_PUBLIC_IP6=$(nospaces "$VPN_PUBLIC_IP6")
  VPN_PUBLIC_IP6=$(noquotes "$VPN_PUBLIC_IP6")
fi

# Apply defaults
[ -z "$VPN_PORT" ]        && VPN_PORT=51820
[ -z "$VPN_CLIENT_NAME" ] && VPN_CLIENT_NAME=client
[ -z "$VPN_DNS_SRV1" ]    && VPN_DNS_SRV1=8.8.8.8
[ -z "$VPN_DNS_SRV2" ]    && VPN_DNS_SRV2=8.8.4.4

# Validate port
if ! printf '%s' "$VPN_PORT" | grep -Eq '^[0-9]+$' \
  || [ "$VPN_PORT" -lt 1 ] || [ "$VPN_PORT" -gt 65535 ]; then
  exiterr "VPN_PORT must be an integer between 1 and 65535."
fi

# Sanitize and validate client name
VPN_CLIENT_NAME=$(printf '%s' "$VPN_CLIENT_NAME" | \
  sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g')
if [ -z "$VPN_CLIENT_NAME" ]; then
  exiterr "VPN_CLIENT_NAME is invalid. Use one word only, no special characters except '-' and '_'."
fi

# Validate DNS servers
if [ -n "$VPN_DNS_SRV1" ] && ! check_ip "$VPN_DNS_SRV1"; then
  exiterr "VPN_DNS_SRV1 '$VPN_DNS_SRV1' is not a valid IPv4 address."
fi
if [ -n "$VPN_DNS_SRV2" ] && ! check_ip "$VPN_DNS_SRV2"; then
  exiterr "VPN_DNS_SRV2 '$VPN_DNS_SRV2' is not a valid IPv4 address."
fi

# Build DNS string for client configs
if [ -n "$VPN_DNS_SRV1" ] && [ -n "$VPN_DNS_SRV2" ]; then
  CLIENT_DNS="$VPN_DNS_SRV1, $VPN_DNS_SRV2"
elif [ -n "$VPN_DNS_SRV1" ]; then
  CLIENT_DNS="$VPN_DNS_SRV1"
else
  CLIENT_DNS="8.8.8.8, 8.8.4.4"
fi

# Determine server address for client configurations
if [ -n "$VPN_DNS_NAME" ]; then
  if ! check_dns_name "$VPN_DNS_NAME"; then
    exiterr "VPN_DNS_NAME '$VPN_DNS_NAME' is not a valid fully qualified domain name (FQDN)."
  fi
  server_addr="$VPN_DNS_NAME"
elif [ -n "$VPN_PUBLIC_IP" ]; then
  if ! check_ip "$VPN_PUBLIC_IP"; then
    exiterr "VPN_PUBLIC_IP '$VPN_PUBLIC_IP' is not a valid IPv4 address."
  fi
  server_addr="$VPN_PUBLIC_IP"
else
  echo
  echo "Trying to auto-detect public IP of this server..."
  public_ip=$(dig @resolver1.opendns.com -t A -4 myip.opendns.com +short 2>/dev/null)
  check_ip "$public_ip" || public_ip=$(wget -t 2 -T 10 -qO- http://ipv4.icanhazip.com 2>/dev/null)
  check_ip "$public_ip" || public_ip=$(wget -t 2 -T 10 -qO- http://ip1.dynupdate.no-ip.com 2>/dev/null)
  if ! check_ip "$public_ip"; then
    exiterr "Cannot detect this server's public IP. Define it in your 'env' file as 'VPN_PUBLIC_IP'."
  fi
  server_addr="$public_ip"
fi

# Detect IPv6
ip6=""
if [ -n "$VPN_PUBLIC_IP6" ]; then
  ip6="$VPN_PUBLIC_IP6"
  check_ip6 "$ip6" || { echo "Warning: Invalid IPv6 address in 'VPN_PUBLIC_IP6'. Detecting IPv6..." >&2; ip6=""; }
fi
if [ -z "$ip6" ]; then
  ip6=$(ip -6 addr 2>/dev/null | awk '/inet6 [23]/ {print $2}' | cut -d'/' -f1 | head -n1)
  check_ip6 "$ip6" || ip6=""
  if [ -z "$ip6" ] && ip -6 addr 2>/dev/null | grep 'inet6' | grep -qv 'inet6 \(::1\|fe80\)'; then
    ip6=$(wget -t 2 -T 10 -qO- https://ipv6.icanhazip.com 2>/dev/null)
    check_ip6 "$ip6" || ip6=""
  fi
fi

WG_CONF="/etc/wireguard/wg0.conf"
USAGE_STATE_DIR="/etc/wireguard/.wireguard-usage"
data_mounted=false
data_existing=false
if grep -q " /etc/wireguard " /proc/mounts 2>/dev/null; then
  data_mounted=true
fi
if $data_mounted && find /etc/wireguard -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null | grep -q .; then
  data_existing=true
fi

mkdir -p /etc/wireguard/clients

echo
echo "WireGuard Docker - https://github.com/hwdsl2/docker-wireguard"

if ! grep -q " /etc/wireguard " /proc/mounts; then
  echo
  echo "Note: /etc/wireguard is not mounted. Server data (keys and client"
  echo "      configs) will be lost on container removal."
  echo "      Mount a Docker volume at /etc/wireguard to persist data."
fi

if [ ! -f "$WG_CONF" ]; then
  echo
  echo "Starting WireGuard setup..."
  echo "Server address: $server_addr"
  echo "Port: UDP/$VPN_PORT"
  echo "First client: $VPN_CLIENT_NAME"
  echo "DNS for clients: $CLIENT_DNS"
  if [ -n "$ip6" ]; then
    echo "IPv6: enabled"
  fi
  echo

  # Generate server keypair
  server_priv=$(wg genkey)
  server_pub=$(printf '%s' "$server_priv" | wg pubkey)

  # Set server interface address (include IPv6 if available)
  if [ -n "$ip6" ]; then
    wg_server_addr="10.7.0.1/24, fddd:2c4:2c4:2c4::1/64"
  else
    wg_server_addr="10.7.0.1/24"
  fi

  # Write server config
  cat > "$WG_CONF" <<EOF
# Do not alter the commented lines
# They are used by docker-wireguard
# ENDPOINT $server_addr

[Interface]
Address = $wg_server_addr
PrivateKey = $server_priv
ListenPort = $VPN_PORT

EOF
  chmod 600 "$WG_CONF"

  # Generate first client keypair and preshared key
  client_priv=$(wg genkey)
  client_psk=$(wg genpsk)
  client_pub=$(printf '%s' "$client_priv" | wg pubkey)
  client_octet=2

  # Set client allowed IPs and interface address (include IPv6 if available)
  if [ -n "$ip6" ]; then
    client_allowed_ips="10.7.0.$client_octet/32, fddd:2c4:2c4:2c4::$client_octet/128"
    client_iface_addr="10.7.0.$client_octet/24, fddd:2c4:2c4:2c4::$client_octet/64"
  else
    client_allowed_ips="10.7.0.$client_octet/32"
    client_iface_addr="10.7.0.$client_octet/24"
  fi

  # Append client block to server config
  cat >> "$WG_CONF" <<EOF
# BEGIN_CLIENT $VPN_CLIENT_NAME
[Peer]
PublicKey = $client_pub
PresharedKey = $client_psk
AllowedIPs = $client_allowed_ips
# END_CLIENT $VPN_CLIENT_NAME
EOF

  # Write client config
  mkdir -p /etc/wireguard/clients
  cat > "/etc/wireguard/clients/${VPN_CLIENT_NAME}.conf" <<EOF
[Interface]
Address = $client_iface_addr
DNS = $CLIENT_DNS
PrivateKey = $client_priv

[Peer]
PublicKey = $server_pub
PresharedKey = $client_psk
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $server_addr:$VPN_PORT
PersistentKeepalive = 25
EOF
  chmod 600 "/etc/wireguard/clients/${VPN_CLIENT_NAME}.conf"

  echo "Setup complete."
  echo
  echo "Client configuration: /etc/wireguard/clients/$VPN_CLIENT_NAME.conf"
  echo "Use 'docker cp <container>:/etc/wireguard/clients/$VPN_CLIENT_NAME.conf .' to download it."
  echo "Use 'docker exec <container> wg_manage --addclient <name>' to add more clients."
  echo
  echo "QR code for $VPN_CLIENT_NAME (scan with your WireGuard mobile app):"
  echo
  qrencode -t ansiutf8 < "/etc/wireguard/clients/${VPN_CLIENT_NAME}.conf"
  echo
else
  echo
  echo "Found existing WireGuard configuration, starting server..."
  echo
fi

# Bring up WireGuard interface
# Remove any stale interface first
ip link del wg0 2>/dev/null || true

if [ "$WG_BACKEND" = "userspace" ]; then
  echo "Starting wireguard-go (userspace WireGuard)..."
  wireguard-go wg0
  # Wait for the interface to become available (up to 5 seconds)
  wg_up=0
  for _ in $(seq 1 10); do
    ip link show wg0 >/dev/null 2>&1 && wg_up=1 && break
    sleep 0.5
  done
  if [ "$wg_up" -ne 1 ]; then
    exiterr "Failed to create WireGuard interface via wireguard-go."
  fi
  echo "Note: Using wireguard-go (userspace WireGuard). For best performance,"
  echo "      ensure the host kernel (5.6+) has built-in WireGuard support."
  echo
else
  ip link add wg0 type wireguard
fi

# Apply WireGuard configuration (strip Address line - handled separately)
wg setconf wg0 <(grep -v '^Address ' "$WG_CONF")

# Assign server VPN IP addresses and bring up the interface
ip address add 10.7.0.1/24 dev wg0
if grep -q 'fddd:2c4:2c4:2c4::1' "$WG_CONF" 2>/dev/null; then
  ip address add fddd:2c4:2c4:2c4::1/64 dev wg0
fi
ip link set wg0 up

# Update sysctl settings
syt='/sbin/sysctl -e -q -w'
$syt net.ipv4.ip_forward=1 2>/dev/null
$syt net.ipv4.conf.all.accept_redirects=0 2>/dev/null
$syt net.ipv4.conf.all.send_redirects=0 2>/dev/null
$syt net.ipv4.conf.all.rp_filter=0 2>/dev/null
$syt net.ipv4.conf.default.accept_redirects=0 2>/dev/null
$syt net.ipv4.conf.default.send_redirects=0 2>/dev/null
$syt net.ipv4.conf.default.rp_filter=0 2>/dev/null
$syt "net.ipv4.conf.$NET_IFACE.send_redirects=0" 2>/dev/null
$syt "net.ipv4.conf.$NET_IFACE.rp_filter=0" 2>/dev/null
if [ -n "$ip6" ]; then
  $syt net.ipv6.conf.all.forwarding=1 2>/dev/null
fi

# Set up iptables rules for NAT and forwarding
modprobe -q ip_tables 2>/dev/null
if ! iptables -t nat -C POSTROUTING -s 10.7.0.0/24 -o "$NET_IFACE" -j MASQUERADE 2>/dev/null; then
  iptables -t nat -A POSTROUTING -s 10.7.0.0/24 -o "$NET_IFACE" -j MASQUERADE
  iptables -I INPUT -p udp --dport "$VPN_PORT" -j ACCEPT
  iptables -I FORWARD -s 10.7.0.0/24 -j ACCEPT
  iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
fi

if [ -n "$ip6" ] && grep -qs 'fddd:2c4:2c4:2c4::1' "$WG_CONF" 2>/dev/null; then
  modprobe -q ip6_tables 2>/dev/null
  if ip6tables -t nat -L >/dev/null 2>&1; then
    if ! ip6tables -t nat -C POSTROUTING -s fddd:2c4:2c4:2c4::/64 \
        -o "$NET_IFACE" -j MASQUERADE 2>/dev/null; then
      ip6tables -t nat -A POSTROUTING -s fddd:2c4:2c4:2c4::/64 -o "$NET_IFACE" -j MASQUERADE
      ip6tables -I FORWARD -s fddd:2c4:2c4:2c4::/64 -j ACCEPT
      ip6tables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
    fi
  fi
fi

echo "WireGuard server started. Listening on UDP port $VPN_PORT."
echo
report_usage_counts

cleanup() {
  echo
  echo "Shutting down WireGuard..."
  ip link del wg0 2>/dev/null || true
  iptables -t nat -D POSTROUTING -s 10.7.0.0/24 -o "$NET_IFACE" -j MASQUERADE 2>/dev/null || true
  iptables -D INPUT -p udp --dport "${VPN_PORT:-51820}" -j ACCEPT 2>/dev/null || true
  iptables -D FORWARD -s 10.7.0.0/24 -j ACCEPT 2>/dev/null || true
  iptables -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
  ip6tables -t nat -D POSTROUTING -s fddd:2c4:2c4:2c4::/64 -o "$NET_IFACE" -j MASQUERADE 2>/dev/null || true
  ip6tables -D FORWARD -s fddd:2c4:2c4:2c4::/64 -j ACCEPT 2>/dev/null || true
  ip6tables -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
  exit 0
}
trap cleanup INT TERM

# Keep the container running
while true; do
  sleep 3600 &
  wait $!
done
