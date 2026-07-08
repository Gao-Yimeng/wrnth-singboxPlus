FROM alpine:3.20

# Install dependencies
RUN apk add --no-cache wget tar jq openssl

# Sing-box version
ARG SING_BOX_VERSION=1.13.14

WORKDIR /app

# Download sing-box (verbose to catch errors)
RUN wget "https://github.com/SagerNet/sing-box/releases/download/v${SING_BOX_VERSION}/sing-box-${SING_BOX_VERSION}-linux-amd64.tar.gz" \
    && ls -la sing-box-${SING_BOX_VERSION}-linux-amd64.tar.gz \
    && tar -xzf sing-box-${SING_BOX_VERSION}-linux-amd64.tar.gz \
    && ls -la sing-box-${SING_BOX_VERSION}-linux-amd64/ \
    && mv sing-box-${SING_BOX_VERSION}-linux-amd64/sing-box ./sing-box \
    && chmod +x sing-box \
    && rm -rf sing-box-${SING_BOX_VERSION}-linux-amd64*

# Copy NOTICE
COPY NOTICE.txt .

# Copy scripts
COPY start.sh .
COPY generate_config.sh .
RUN chmod +x /app/start.sh /app/generate_config.sh

# Create runtime dirs
RUN mkdir -p /app/data /app/cert

# Create non-root user
RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup && \
    chown -R appuser:appgroup /app

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
