# syntax=docker/dockerfile:1
# ==============================================================================
# OpenBot for Unraid OS - Multi-arch Automated Build
# Packages upstream nightly-labs/openbot releases for Unraid OS
# ==============================================================================

ARG BASE=ubuntu:24.04

FROM ${BASE} AS extractor
ARG TARGETARCH
ARG VERSION=latest
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    jq \
    file \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

# Download the corresponding upstream AppImage and extract squashfs
RUN set -euo pipefail; \
    if [ "$TARGETARCH" = "amd64" ]; then \
        ARCH_SUFFIX="x86_64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        ARCH_SUFFIX="arm64"; \
    else \
        echo "Unsupported architecture: $TARGETARCH" && exit 1; \
    fi; \
    if [ "$VERSION" = "latest" ]; then \
        RELEASE_JSON=$(curl -fsSL https://api.github.com/repos/nightly-labs/openbot/releases/latest); \
    else \
        RELEASE_JSON=$(curl -fsSL "https://api.github.com/repos/nightly-labs/openbot/releases/tags/${VERSION}"); \
    fi; \
    DOWNLOAD_URL=$(echo "$RELEASE_JSON" | jq -r ".assets[] | select(.name | test(\"OpenBot-.*-${ARCH_SUFFIX}\\\\.AppImage$\")) | .browser_download_url"); \
    echo "Downloading OpenBot AppImage for $TARGETARCH ($ARCH_SUFFIX) from: $DOWNLOAD_URL"; \
    curl -fsSL -o /tmp/OpenBot.AppImage "$DOWNLOAD_URL"; \
    chmod 0755 /tmp/OpenBot.AppImage; \
    /tmp/OpenBot.AppImage --appimage-extract >/dev/null; \
    chmod -R u+rwX,go=rX squashfs-root; \
    test -x squashfs-root/resources/hosting/openbot-container

FROM ${BASE}
ARG DEBIAN_FRONTEND=noninteractive

# Copy package requirements from the extracted upstream release
COPY --from=extractor /tmp/squashfs-root/resources/hosting/packages.txt /tmp/packages.txt

# Install packages required for OpenBot self-hosted server runtime
RUN apt-get update \
  && sed -e '/^#/d' -e '/^$/d' -e '/^apparmor$/d' /tmp/packages.txt \
    | xargs apt-get install --yes --no-install-recommends \
      git less openssh-client procps ripgrep tini unzip xz-utils ca-certificates curl \
  && rm -rf /var/lib/apt/lists/* /tmp/packages.txt

# Configure openbot user (UID 1000) and runtime folders
RUN userdel --remove ubuntu 2>/dev/null || true \
  && useradd --uid 1000 --user-group --home-dir /data --create-home --shell /bin/bash openbot \
  && install -d -o openbot -g openbot -m 0700 /run/openbot

RUN install -d -m 0755 /var/lib/openbot-update/requests /var/lib/openbot-update/status
COPY --from=extractor /tmp/squashfs-root /opt/OpenBot/app
RUN install -d -m 0755 /opt/OpenBot/hosted \
  && printf 'container\n' >/opt/OpenBot/hosted/mode \
  && ln -s /opt/OpenBot/app/resources/hosting/openbot /usr/local/bin/openbot

ARG VERSION=unknown
ARG REVISION=unknown

LABEL org.opencontainers.image.title="OpenBot" \
  org.opencontainers.image.description="OpenBot AI Workspace desktop server for Unraid OS" \
  org.opencontainers.image.source="https://github.com/chmuri/openbot-unraid" \
  org.opencontainers.image.licenses="PolyForm-Noncommercial-1.0.0" \
  org.opencontainers.image.version="${VERSION}" \
  org.opencontainers.image.revision="${REVISION}"

ENV LANG=C.UTF-8 \
    XDG_RUNTIME_DIR=/run/openbot

USER openbot
WORKDIR /data
VOLUME /data
STOPSIGNAL SIGTERM

ENTRYPOINT ["/usr/bin/tini", "--", "/opt/OpenBot/app/resources/hosting/openbot-container"]
