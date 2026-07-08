#!/bin/sh
# ================================================================
#  start.sh — Entry point for sing-box in Docker container
# ================================================================

# Set deprecated env var for sing-box v1.13.x compatibility
export ENABLE_DEPRECATED_LEGACY_DNS_SERVERS=true
export ENABLE_DEPRECATED_SPECIAL_OUTBOUNDS=true

echo "[start.sh] Sing-Box Plus Docker Edition starting..."
echo "[start.sh] SING_BOX_PORT=${SING_BOX_PORT:-31080}"
echo "[start.sh] SING_BOX_HEALTH_PORT=${SING_BOX_HEALTH_PORT:-31081}"

# ---- Step 1: Generate config from environment variables ----
echo "[start.sh] Step 1/4: Generating config..."
if [ -f /app/generate_config.sh ]; then
    /app/generate_config.sh
else
    echo "[start.sh] WARNING: generate_config.sh not found, using static config.json"
fi

# ---- Step 2: Validate config ----
echo "[start.sh] Step 2/4: Validating config..."
if sing-box check -c /app/config.json 2>/dev/null; then
    echo "[start.sh] Config validation passed"
else
    echo "[start.sh] WARNING: Config validation returned non-zero, attempting to start anyway..."
fi

# ---- Step 3: Start health check server on separate port ----
echo "[start.sh] Step 3/4: Starting health check server on port ${SING_BOX_HEALTH_PORT:-31081}..."

(while true; do
    echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\nOK" | \
    nc -l -p ${SING_BOX_HEALTH_PORT:-31081} -w 2 >/dev/null 2>&1 || true
done) &
HEALTH_PID=$!
echo "[start.sh] Health check server PID: $HEALTH_PID"

# ---- Step 4: Start sing-box in foreground ----
echo "[start.sh] Step 4/4: Starting sing-box..."
echo "[start.sh] Running: sing-box run -c /app/config.json"

exec sing-box run -c /app/config.json
