FROM alpine:3.20

# Install all dependencies including build tools
RUN apk add --no-cache wget tar jq socat openssl curl tini

# Create non-root user
RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

WORKDIR /app

# Sing-box version
ARG SING_BOX_VERSION=1.13.14

# Download and install sing-box binary
RUN wget -q "https://github.com/SagerNet/sing-box/releases/download/v${SING_BOX_VERSION}/sing-box-${SING_BOX_VERSION}-linux-amd64.tar.gz" \
    && tar -xzf "sing-box-${SING_BOX_VERSION}-linux-amd64.tar.gz" \
    && mv "sing-box-${SING_BOX_VERSION}-linux-amd64/sing-box" ./sing-box \
    && chmod +x sing-box \
    && rm -rf "sing-box-${SING_BOX_VERSION}-linux-amd64"*

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

# Environment variables
ENV SING_BOX_PORT=31080
ENV SING_BOX_UUID=524bd2ea-9579-4b31-b4ed-480ab6068578
ENV SING_BOX_PROTOCOL=vless
ENV SING_BOX_WS_PATH=/chat
ENV SING_BOX_HEALTH_PORT=31081
ENV SING_BOX_REALITY_SERVER=www.microsoft.com
ENV SING_BOX_LOG_LEVEL=info

# Expose ports
EXPOSE ${SING_BOX_PORT}
EXPOSE ${SING_BOX_HEALTH_PORT}

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -sf http://localhost:${SING_BOX_HEALTH_PORT}/health || exit 1

# Use tini for signal handling
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/app/start.sh"]
