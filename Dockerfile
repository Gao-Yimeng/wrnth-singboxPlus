# ================================================================
#  Sing-Box Plus — Docker Container Edition
#  Inspired by: https://github.com/Alvin9999-newpac/Sing-Box-Plus
#  Target: Back4App Containers deployment
# ================================================================

# ---- Stage 1: Build ----
FROM alpine:3.20 AS builder

RUN apk add --no-cache wget tar jq openssl

ARG SING_BOX_VERSION=1.13.7
ARG TARGETARCH=amd64

WORKDIR /build

# Download sing-box binary matching the target architecture
RUN wget -q "https://github.com/SagerNet/sing-box/releases/download/v${SING_BOX_VERSION}/sing-box-${SING_BOX_VERSION}-linux-${TARGETARCH}.tar.gz" \
    && tar -xzf "sing-box-${SING_BOX_VERSION}-linux-${TARGETARCH}.tar.gz" \
    && mv "sing-box-${SING_BOX_VERSION}-linux-${TARGETARCH}/sing-box" ./sing-box \
    && chmod +x sing-box \
    && rm -rf "sing-box-${SING_BOX_VERSION}-linux-${TARGETARCH}"*

# ---- Stage 2: Runtime ----
FROM alpine:3.20 AS runtime

RUN apk add --no-cache socat openssl curl tini jq

# Create non-root user
RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

WORKDIR /app

# Copy sing-box binary from builder
COPY --from=builder /build/sing-box /usr/local/bin/sing-box
RUN chmod +x /usr/local/bin/sing-box

# Copy application files
COPY NOTICE.txt .
COPY start.sh .
COPY generate_config.sh .

# Make scripts executable
RUN chmod +x /app/start.sh /app/generate_config.sh

# Create runtime directories
RUN mkdir -p /app/data /app/cert && chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Environment variables (can be overridden by Back4App container settings)
ENV SING_BOX_PORT=31080
ENV SING_BOX_UUID=524bd2ea-9579-4b31-b4ed-480ab6068578
ENV SING_BOX_PROTOCOL=vless
ENV SING_BOX_WS_PATH=/chat
ENV SING_BOX_HEALTH_PORT=31081
ENV SING_BOX_REALITY_SERVER=www.microsoft.com
ENV SING_BOX_LOG_LEVEL=info

# Expose proxy port and health check port
EXPOSE ${SING_BOX_PORT}
EXPOSE ${SING_BOX_HEALTH_PORT}

# Health check for container orchestration
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -sf http://localhost:${SING_BOX_HEALTH_PORT}/health || exit 1

# Use tini as init system for proper signal handling
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/app/start.sh"]
