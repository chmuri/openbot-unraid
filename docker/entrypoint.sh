#!/usr/bin/env bash
set -e

# ==============================================================================
# OpenBot Unraid Container Entrypoint
# Automatically fixes Unraid appdata volume ownership and drops privileges
# ==============================================================================

# Ensure /data volume is writable by user openbot (UID 1000)
if [ -d "/data" ] && [ ! -w "/data" ]; then
    echo "[OPENBOT-INIT] Fixing ownership on /data for openbot (1000:1000)..."
    chown -R openbot:openbot /data
fi

# Ensure runtime directory exists with proper permissions
install -d -o openbot -g openbot -m 0700 /run/openbot

# Execute openbot-container dropping privileges to openbot user
exec gosu openbot /opt/OpenBot/app/resources/hosting/openbot-container "$@"
