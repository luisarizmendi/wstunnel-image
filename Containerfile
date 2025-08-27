FROM alpine:3.18

# Install dependencies
RUN apk add --no-cache nodejs npm bash microsocks socat

# Install wstunnel globally
RUN npm install -g wstunnel

# Environment variables with defaults
ENV WSTUNNEL_MODE="client" \
    WSTUNNEL_REMOTE="" \
    WSTUNNEL_REMOTE_FORWARD="" \
    WSTUNNEL_LOCAL_FORWARD="" \
    WSTUNNEL_PORT="8000" \
    SOCKS5_PORT="1080"

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
