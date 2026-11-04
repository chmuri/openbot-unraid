#!/usr/bin/env bash
# ==============================================================================
# OpenBot - Container Healthcheck Script
# ==============================================================================

PORT=${OPENBOT_PORT:-8080}

# 1. Check HTTP response from /health endpoint
if curl -sf --max-time 3 "http://127.0.0.1:${PORT}/health" > /dev/null; then
    exit 0
fi

# 2. Fallback: check if the OpenBot Python process is active
if pgrep -f "app.py" > /dev/null 2>&1; then
    exit 0
fi

exit 1
