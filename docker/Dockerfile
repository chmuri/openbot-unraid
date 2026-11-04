# ==============================================================================
# OpenBot for Unraid OS - Production Multi-arch Dockerfile
# Supports: linux/amd64 and linux/arm64
# ==============================================================================

FROM python:3.11-slim-bookworm

LABEL maintainer="chmuri"
LABEL org.opencontainers.image.title="OpenBot Unraid"
LABEL org.opencontainers.image.description="OpenBot server and telemetry agent optimized for Unraid OS"
LABEL org.opencontainers.image.source="https://github.com/chmuri/openbot-unraid"
LABEL org.opencontainers.image.licenses="Apache-2.0"

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    OPENBOT_PORT=8080 \
    OPENBOT_CONFIG_DIR=/config \
    OPENBOT_DATA_DIR=/data \
    PUID=99 \
    PGID=100 \
    UMASK=022

# Install base packages, gosu privilege dropper, and hardware peripheral utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    gosu \
    procps \
    tzdata \
    v4l-utils \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Create application and volume directories
RUN mkdir -p /app /config /data

WORKDIR /app

# Copy application source
COPY src/ /app/src/

# Copy entrypoint and healthcheck scripts
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/healthcheck.sh /usr/local/bin/healthcheck.sh

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/healthcheck.sh

# Volumes compliant with Unraid user shares (/mnt/user/appdata/openbot)
VOLUME ["/config", "/data"]

# WebUI and API port
EXPOSE 8080

# Unraid Docker engine integrated healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["python3", "/app/src/app.py"]
