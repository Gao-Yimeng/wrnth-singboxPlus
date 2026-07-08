#!/bin/sh
export ENABLE_DEPRECATED_LEGACY_DNS_SERVERS=true
export ENABLE_DEPRECATED_SPECIAL_OUTBOUNDS=true

echo "[start.sh] Sing-Box Plus Docker Edition starting..."
echo "[start.sh] SING_BOX_PORT=${SING_BOX_PORT:-31080}"
echo "[start.sh] SING_BOX_HEALTH_PORT=${SING_BOX_HEALTH_PORT:-31081}"

echo "[start.sh] Step 1/4: Generating config..."
if [ -f /app/generate_config.sh ]; then
    /app/generate_config.sh
else
    echo "[start.sh] Using static config.json"
fi

echo "[start.sh] Step 2/4: Validating config..."
if sing-box check -c /app/config.json 2>/dev/null; then
    echo "[start.sh] Config validation passed"
else
    echo "[start.sh] WARNING: Config validation returned non-zero"
fi

echo "[start.sh] Step 3/4: Starting health check server on port ${SING_BOX_HEALTH_PORT:-31081}..."
(while true; do
    echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\nOK" | \
    nc -l -p ${SING_BOX_HEALTH_PORT:-31081} -w 2 >/dev/null 2>&1 || true
done) &
echo "[start.sh] Health check server PID: $!"

echo "[start.sh] Step 4/4: Starting sing-box..."
exec sing-box run -c /app/config.json
