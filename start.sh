#!/bin/sh
export ENABLE_DEPRECATED_LEGACY_DNS_SERVERS=true
export ENABLE_DEPRECATED_SPECIAL_OUTBOUNDS=true

echo "[start.sh] Sing-Box Plus Docker Edition starting..."
echo "[start.sh] SING_BOX_PORT=${SING_BOX_PORT:-31080}"
echo "[start.sh] SING_BOX_HEALTH_PORT=${SING_BOX_HEALTH_PORT:-31081}"

echo "[start.sh] Using static config.json (generated at build time)"

echo "[start.sh] Step 1/2: Validating config..."
if sing-box check -c /app/config.json 2>/dev/null; then
    echo "[start.sh] Config validation passed"
else
    echo "[start.sh] WARNING: Config validation returned non-zero, starting anyway..."
fi

echo "[start.sh] Step 2/2: Starting sing-box..."
exec sing-box run -c /app/config.json
