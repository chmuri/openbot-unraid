#!/usr/bin/env bash
set -e

# ==============================================================================
# OpenBot Unraid Container Entrypoint
# Automatically fixes Unraid appdata volume ownership and drops privileges
# ==============================================================================

# Running as root: make /data usable by the openbot user, then drop privileges.
# The writability test must run as openbot - root can write anywhere, so testing
# as root would always succeed and skip the ownership repair.
if [ "$(id -u)" -eq 0 ]; then
    install -d -m 0755 /data 2>/dev/null || true

    if ! gosu openbot test -w /data 2>/dev/null \
        || [ -n "$(find /data ! -user openbot -print -quit 2>/dev/null)" ]; then
        echo "[OPENBOT-INIT] Fixing ownership on /data for openbot (1000:1000)..."
        chown -R openbot:openbot /data
    fi

    # Ensure runtime directory exists with proper permissions
    install -d -o openbot -g openbot -m 0700 /run/openbot
fi

# Execute openbot-container dropping privileges to openbot user
exec gosu openbot /opt/OpenBot/app/resources/hosting/openbot-container "$@"
