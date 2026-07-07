FROM alpine:3.20

# Install dependencies
RUN apk add --no-cache wget tar socat

# Create non-root user
RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

WORKDIR /app

COPY NOTICE.txt .
COPY start.sh .

# Sing-box version
ARG SING_BOX_VERSION=1.12.24

# Download and install sing-box binary
RUN wget -q https://github.com/SagerNet/sing-box/releases/download/v${SING_BOX_VERSION}/sing-box-${SING_BOX_VERSION}-linux-amd64.tar.gz && \
    tar -xzf sing-box-${SING_BOX_VERSION}-linux-amd64.tar.gz && \
    mv sing-box-${SING_BOX_VERSION}-linux-amd64/sing-box ./ && \
    rm -rf sing-box-${SING_BOX_VERSION}-linux-amd64* && \
    chmod +x sing-box && \
    apk del wget tar

# Copy configuration
COPY config.json .

# Make start.sh executable
RUN chmod +x start.sh

# Switch to non-root user
USER appuser

# Expose ports: 8080 for sing-box VLESS-WS, 8081 for health check
EXPOSE 8080
EXPOSE 8081

# Health check for Back4App (optional - platform may do its own)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q --spider http://localhost:8081/health || exit 1

# Start both sing-box and health check server
CMD ["./start.sh"]
