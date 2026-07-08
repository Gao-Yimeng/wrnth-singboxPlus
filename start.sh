#!/bin/sh
export ENABLE_DEPRECATED_LEGACY_DNS_SERVERS=true
export ENABLE_DEPRECATED_SPECIAL_OUTBOUNDS=true

echo "[start.sh] Sing-Box Plus Docker Edition starting..."
echo "[start.sh] SING_BOX_PORT=${SING_BOX_PORT:-31080}"
echo "[start.sh] SING_BOX_HEALTH_PORT=${SING_BOX_HEALTH_PORT:-31081}"

# Generate TLS certificate if not exists
CERT_DIR="/app/cert"
mkdir -p "$CERT_DIR"
CRT="$CERT_DIR/fullchain.pem"
KEY="$CERT_DIR/key.pem"
REALITY_SERVER="${SING_BOX_REALITY_SERVER:-www.microsoft.com}"

if [ ! -s "$CRT" ] || [ ! -s "$KEY" ]; then
    echo "[start.sh] Generating self-signed TLS certificate..."
    openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
        -days 36500 -nodes \
        -keyout "$KEY" -out "$CRT" \
        -subj "/CN=${REALITY_SERVER}" \
        -addext "subjectAltName=DNS:${REALITY_SERVER}" \
        >/dev/null 2>&1
    echo "[start.sh] Certificate generated"
fi

echo "[start.sh] Using static config.json"

echo "[start.sh] Step 1/2: Validating config..."
if sing-box check -c /app/config.json 2>/dev/null; then
    echo "[start.sh] Config validation passed"
else
    echo "[start.sh] WARNING: Config validation returned non-zero"
fi

echo "[start.sh] Step 2/2: Starting sing-box..."
exec sing-box run -c /app/config.json
