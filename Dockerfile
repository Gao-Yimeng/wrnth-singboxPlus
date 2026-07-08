FROM debian:bookworm-slim

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    socat openssl curl tini jq \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -g 1000 appgroup && \
    useradd -u 1000 -g appgroup -s /bin/false appuser

WORKDIR /app

# Copy sing-box binary
COPY sing-box /usr/local/bin/sing-box
RUN chmod +x /usr/local/bin/sing-box

# Copy NOTICE
COPY NOTICE.txt .

# Copy scripts
COPY config.json .
COPY start.sh .
COPY generate_config.sh .
RUN chmod +x /app/start.sh /app/generate_config.sh

# Create runtime dirs
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

EXPOSE ${SING_BOX_PORT}
EXPOSE ${SING_BOX_HEALTH_PORT}

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD wget -q --spider http://localhost:${SING_BOX_HEALTH_PORT}/health || exit 1

CMD ["/app/start.sh"]
