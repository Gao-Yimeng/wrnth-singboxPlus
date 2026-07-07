# Sing-Box Plus — Docker Container Edition

A containerized deployment of [Sing-Box-Plus](https://github.com/Alvin9999-newpac/Sing-Box-Plus), inspired by the original 20-node proxy server project.

## 🚀 Features

- **Multi-architecture support**: amd64 / arm64 (mirrors Sing-Box-Plus `detect_goarch()`)
- **Two-stage Docker build**: smaller final image
- **Environment-driven config**: mirrors Sing-Box-Plus `env.conf` pattern
- **Self-signed TLS cert generation**: mirrors `mk_cert()` from Sing-Box-Plus
- **Health check endpoint**: required for Back4App Containers
- **Non-root user**: security best practice
- **Tini init system**: proper signal handling for graceful shutdown

## 📂 Project Structure

```
wrnth-singboxPlus/
├── Dockerfile            # Multi-stage build (builder + runtime)
├── config.json           # Static sing-box config (overridden by env)
├── generate_config.sh    # Dynamic config generator (env → JSON)
├── start.sh              # Entry point: validate + start all services
├── .env.example          # Environment variable reference
├── NOTICE.txt            # Copyright notice
└── README.md             # This file
```

## 🔧 Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SING_BOX_PORT` | `31080` | Proxy listening port (10000-65535) |
| `SING_BOX_UUID` | *(your UUID)* | VLESS user UUID |
| `SING_BOX_PROTOCOL` | `vless` | Protocol type |
| `SING_BOX_WS_PATH` | `/chat` | WebSocket path |
| `SING_BOX_REALITY_SERVER` | `www.microsoft.com` | SNI domain for reality/TLS |
| `SING_BOX_LOG_LEVEL` | `info` | Log verbosity |
| `SING_BOX_HEALTH_PORT` | `31081` | Health check HTTP port |

## 🐳 Local Testing

```bash
# Build
docker build -t singbox-plus .

# Run
docker run -d \
  -p 31080:31080 \
  -p 31081:31081 \
  -e SING_BOX_PORT=31080 \
  -e SING_BOX_UUID=your-uuid-here \
  --name singbox-plus \
  singbox-plus

# Check logs
docker logs -f singbox-plus

# Test health check
curl http://localhost:31081/health
```

## ☁️ Back4App Deployment

1. Connect your GitHub account to [Back4App Containers](https://www.back4app.com/)
2. Select this repository
3. Set environment variables in the Back4App dashboard:
   - `SING_BOX_PORT`: your chosen non-standard port
   - `SING_BOX_UUID`: your UUID
   - `SING_BOX_WS_PATH`: your WebSocket path
4. Deploy — Back4App will build the Docker image automatically

## 📡 Connection Info

Once deployed, your VLESS connection details:

- **Address**: `your-app.back4appcontainers.com`
- **Port**: `31080` (or whatever `SING_BOX_PORT` is set to)
- **UUID**: `524bd2ea-9579-4b31-b4ed-480ab6068578`
- **Network**: WebSocket
- **Path**: `/chat`
- **TLS**: Enabled (self-signed)

## 📜 License

This project includes sing-box (https://github.com/SagerNet/sing-box).

sing-box is licensed under GPL-3.0.

See `NOTICE.txt` for full copyright information.
