#!/bin/sh
# start.sh - Launch sing-box and a simple health check HTTP server

# Start a minimal health-check HTTP server on port 8081
# Using socat to create a simple TCP listener that responds with HTTP 200
(socat TCP-LISTEN:8081,reuseaddr,fork SYSTEM:"echo -e 'HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\nOK'; sleep 1" &)

# Wait a moment for health check server to start
sleep 1

# Start sing-box in foreground (this keeps the container alive)
exec ./sing-box run -c config.json
