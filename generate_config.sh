#!/bin/sh
# ================================================================
#  generate_config.sh — Generate config.json from environment
#  Inspired by Sing-Box-Plus write_config() jq template pattern
#  Reads env vars → generates a complete sing-box config
# ================================================================

set -e

# ---- Defaults (mirrors Sing-Box-Plus constants) ----
: "${SING_BOX_PORT:=31080}"
: "${SING_BOX_UUID:=524bd2ea-9579-4b31-b4ed-480ab6068578}"
: "${SING_BOX_PROTOCOL:=vless}"
: "${SING_BOX_WS_PATH:=/chat}"
: "${SING_BOX_REALITY_SERVER:=www.microsoft.com}"
: "${SING_BOX_LOG_LEVEL:=info}"
: "${CERT_DIR:=/app/cert}"
: "${DATA_DIR:=/app/data}"

# ---- Ensure directories exist ----
mkdir -p "$CERT_DIR" "$DATA_DIR"

# ---- Generate self-signed certificate (mirrors Sing-Box-Plus mk_cert()) ----
CRT="$CERT_DIR/fullchain.pem"
KEY="$CERT_DIR/key.pem"

if [ ! -s "$CRT" ] || [ ! -s "$KEY" ]; then
    echo "[generate_config] Generating self-signed TLS certificate..."
    openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
        -days 36500 -nodes \
        -keyout "$KEY" -out "$CRT" \
        -subj "/CN=${SING_BOX_REALITY_SERVER}" \
        -addext "subjectAltName=DNS:${SING_BOX_REALITY_SERVER}" \
        >/dev/null 2>&1
    echo "[generate_config] Certificate generated: $CRT"
fi

# ---- Determine protocol type from SING_BOX_PROTOCOL ----
PROTO="$(echo "$SING_BOX_PROTOCOL" | tr '[:upper:]' '[:lower:]')"  # lowercase

# ---- Build config using jq (mirrors Sing-Box-Plus write_config jq pattern) ----
jq -n \
  --arg port "$SING_BOX_PORT" \
  --arg uuid "$SING_BOX_UUID" \
  --arg proto "$PROTO" \
  --arg ws_path "$SING_BOX_WS_PATH" \
  --arg cert "$CRT" \
  --arg key "$KEY" \
  --arg log_level "$SING_BOX_LOG_LEVEL" \
  --arg reality_server "$SING_BOX_REALITY_SERVER" \
  '
  # Helper: define VLESS inbound with WebSocket + TLS
  def inbound_vless_ws($port): {
    type: "vless",
    tag: "vless-ws-in",
    listen: "::",
    listen_port: ($port | tonumber),
    sniff: true,
    sniff_override_destination: true,
    users: [{ uuid: $uuid }],
    tls: {
      enabled: true,
      certificate_path: $cert,
      key_path: $key
    },
    transport: {
      type: "ws",
      path: $ws_path,
      max_early_data: 2048,
      early_data_header_name: "Sec-WebSocket-Protocol"
    }
  };

  {
    log: {
      disabled: false,
      level: $log_level,
      timestamp: true
    },
    dns: {
      servers: [
        {
          tag: "dns-direct",
          address: "223.5.5.5",
          strategy: "ipv4_only",
          detour: "direct"
        },
        {
          tag: "dns-proxy",
          address: "tls://8.8.8.8",
          strategy: "ipv4_only",
          detour: "direct"
        }
      ],
      rules: [
        {
          outbound: "any",
          server: "dns-direct"
        }
      ],
      final: "dns-proxy",
      strategy: "ipv4_only"
    },
    inbounds: [
      inbound_vless_ws($port)
    ],
    outbounds: [
      { type: "direct", tag: "direct" },
      { type: "dns", tag: "dns-out" }
    ],
    route: {
      rules: [
        {
          protocol: "dns",
          outbound: "dns-out"
        }
      ],
      final: "direct"
    },
    experimental: {
      v2ray_api: {
        listen: "127.0.0.1:10085",
        stats: {
          enabled: true
        }
      }
    }
  }
  ' > /app/config.json

echo "[generate_config] config.json written successfully"
echo "[generate_config] Listening on port: $SING_BOX_PORT"
echo "[generate_config] UUID: $SING_BOX_UUID"
echo "[generate_config] WS Path: $SING_BOX_WS_PATH"
