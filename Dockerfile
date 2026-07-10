#
# Copyright (C) 2026 Lin Song <linsongui@gmail.com>
#
# This work is licensed under the MIT License
# See: https://opensource.org/licenses/MIT

FROM alpine:3.23

WORKDIR /opt/src

RUN set -x \
    && apk add --no-cache \
         bash bind-tools coreutils iproute2 iptables iptables-legacy ip6tables \
         wireguard-tools wireguard-go libqrencode-tools \
    && cd /sbin \
    && for fn in iptables iptables-save iptables-restore \
                 ip6tables ip6tables-save ip6tables-restore; do \
         ln -fs xtables-legacy-multi "$fn"; done

COPY ./run.sh /opt/src/run.sh
COPY ./manage.sh /opt/src/manage.sh
COPY ./LICENSE.md /opt/src/LICENSE.md
RUN chmod 755 /opt/src/run.sh /opt/src/manage.sh \
    && ln -s /opt/src/manage.sh /usr/local/bin/wg_manage

EXPOSE 51820/udp
CMD ["/opt/src/run.sh"]

ARG BUILD_DATE
ARG VERSION
ARG VCS_REF
ENV IMAGE_VER=$BUILD_DATE
ENV IMAGE_FLAVOR=$VERSION

LABEL maintainer="Lin Song <linsongui@gmail.com>" \
    org.opencontainers.image.created="$BUILD_DATE" \
    org.opencontainers.image.version="$VERSION" \
    org.opencontainers.image.revision="$VCS_REF" \
    org.opencontainers.image.authors="Lin Song <linsongui@gmail.com>" \
    org.opencontainers.image.title="WireGuard VPN Server on Docker" \
    org.opencontainers.image.description="Docker image to run a WireGuard VPN server, with clients managed via a helper script." \
    org.opencontainers.image.url="https://github.com/hwdsl2/docker-wireguard" \
    org.opencontainers.image.source="https://github.com/hwdsl2/docker-wireguard" \
    org.opencontainers.image.documentation="https://github.com/hwdsl2/docker-wireguard"
