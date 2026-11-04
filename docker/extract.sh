#!/usr/bin/env bash
set -euo pipefail

TARGETARCH="${1:-amd64}"
VERSION="${2:-latest}"

echo "[EXTRACT] Target architecture: ${TARGETARCH}, requested version: ${VERSION}"

if [ "$TARGETARCH" = "amd64" ]; then
    ARCH_SUFFIX="x86_64"
elif [ "$TARGETARCH" = "arm64" ]; then
    ARCH_SUFFIX="arm64"
else
    echo "[EXTRACT] ERROR: Unsupported architecture: $TARGETARCH" >&2
    exit 1
fi

if [ "$VERSION" = "latest" ]; then
    RELEASE_JSON=$(curl -fsSL https://api.github.com/repos/nightly-labs/openbot/releases/latest)
else
    RELEASE_JSON=$(curl -fsSL "https://api.github.com/repos/nightly-labs/openbot/releases/tags/${VERSION}")
fi

DOWNLOAD_URL=$(echo "$RELEASE_JSON" | jq -r ".assets[] | select(.name | test(\"OpenBot-.*-${ARCH_SUFFIX}\\\\.AppImage$\")) | .browser_download_url")

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
    echo "[EXTRACT] ERROR: Could not find AppImage URL for $ARCH_SUFFIX in release $VERSION" >&2
    exit 1
fi

echo "[EXTRACT] Downloading OpenBot AppImage from: $DOWNLOAD_URL"
curl -fsSL -o /tmp/OpenBot.AppImage "$DOWNLOAD_URL"
chmod 0755 /tmp/OpenBot.AppImage

echo "[EXTRACT] Extracting AppImage contents..."
cd /tmp
/tmp/OpenBot.AppImage --appimage-extract >/dev/null
chmod -R u+rwX,go=rX squashfs-root

if [ ! -x squashfs-root/resources/hosting/openbot-container ]; then
    echo "[EXTRACT] ERROR: squashfs-root/resources/hosting/openbot-container not executable" >&2
    exit 1
fi

echo "[EXTRACT] AppImage extracted successfully."
