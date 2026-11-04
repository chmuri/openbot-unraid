#!/usr/bin/env bash
set -e

# ==============================================================================
# OpenBot - Unraid OS Container Entrypoint
# Handles dynamic PUID/PGID identity (Unraid standard: nobody:users - 99:100)
# ==============================================================================

PUID=${PUID:-99}
PGID=${PGID:-100}
UMASK=${UMASK:-022}

umask "$UMASK"

echo "[OPENBOT-INIT] Initializing OpenBot container for Unraid OS..."
echo "[OPENBOT-INIT] User identity: PUID=${PUID}, PGID=${PGID}, UMASK=${UMASK}"

# 1. Manage openbot group (match PGID)
if getent group openbot > /dev/null 2>&1; then
    CURRENT_GID=$(getent group openbot | cut -d: -f3)
    if [ "$CURRENT_GID" != "$PGID" ]; then
        groupmod -o -g "$PGID" openbot
    fi
else
    groupadd -o -g "$PGID" openbot
fi

# 2. Manage openbot user (match PUID)
if getent passwd openbot > /dev/null 2>&1; then
    CURRENT_UID=$(getent passwd openbot | cut -d: -f3)
    if [ "$CURRENT_UID" != "$PUID" ]; then
        usermod -o -u "$PUID" -g "$PGID" openbot
    fi
else
    useradd -o -u "$PUID" -g "$PGID" -d /config -s /bin/bash openbot
fi

# 3. Ensure required directories exist
mkdir -p /config /data

# 4. Synchronize ownership of mapped volumes
echo "[OPENBOT-INIT] Synchronizing permissions for /config and /data volumes..."
chown -R "$PUID:$PGID" /config /data

# 5. Hardware passthrough permissions (Serial, Camera, DRI)
# Ensure read/write access for non-root process if devices exist
for dev in /dev/ttyUSB* /dev/ttyACM* /dev/video* /dev/dri/*; do
    if [ -e "$dev" ]; then
        echo "[OPENBOT-INIT] Detected mapped device: $dev - ensuring permissions..."
        chmod 666 "$dev" 2>/dev/null || true
    fi
done

# D-Bus socket check for BLE/Bluetooth
if [ -S "/var/run/dbus/system_bus_socket" ]; then
    echo "[OPENBOT-INIT] Detected system D-Bus socket for BLE/Bluetooth operation."
fi

# 6. Execute application dropping root privileges via gosu
echo "[OPENBOT-INIT] Starting OpenBot process as user openbot ($PUID:$PGID)..."
exec gosu "$PUID:$PGID" "$@"
