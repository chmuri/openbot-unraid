#!/usr/bin/env bash
set -euo pipefail

TARGETARCH="${1:-amd64}"
VERSION="${2:-latest}"

# Optional token (build secret) - raises GitHub API rate limits and avoids
# transient 5xx errors on shared CI IPs.
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [ -z "$TARGETARCH" ] || [ "$TARGETARCH" = "amd64" ] || [ "$TARGETARCH" = "x86_64" ]; then
    ARCH_SUFFIX="x86_64"
elif [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "aarch64" ]; then
    ARCH_SUFFIX="arm64"
else
    echo "[EXTRACT] ERROR: Unsupported architecture: $TARGETARCH" >&2
    exit 1
fi

if [ "$VERSION" = "latest" ]; then
    RELEASE_API="https://api.github.com/repos/nightly-labs/openbot/releases/latest"
else
    RELEASE_API="https://api.github.com/repos/nightly-labs/openbot/releases/tags/${VERSION}"
fi

CURL_OPTS=(
    --fail
    --silent
    --show-error
    --location
    --retry 10
    --retry-all-errors
    --retry-delay 5
    --max-time 300
)

# Authenticate only requests to api.github.com so the token is never forwarded
# to the asset CDN host.
API_OPTS=("${CURL_OPTS[@]}")
if [ -n "$GITHUB_TOKEN" ]; then
    API_OPTS+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
    API_OPTS+=(-H "Accept: application/vnd.github+json")
fi

echo "[EXTRACT] Fetching release metadata: ${RELEASE_API}"
RELEASE_JSON=$(curl "${API_OPTS[@]}" "$RELEASE_API")

DOWNLOAD_URL=$(echo "$RELEASE_JSON" | jq -r ".assets[] | select(.name | test(\"OpenBot-.*-${ARCH_SUFFIX}\\\\.AppImage$\")) | .browser_download_url")

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
    echo "[EXTRACT] ERROR: Could not find AppImage URL for $ARCH_SUFFIX in release $VERSION" >&2
    exit 1
fi

echo "[EXTRACT] Downloading OpenBot AppImage from: $DOWNLOAD_URL"
curl "${CURL_OPTS[@]}" -o /tmp/OpenBot.AppImage "$DOWNLOAD_URL"
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
