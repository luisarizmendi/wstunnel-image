FROM debian:stable-slim

RUN apt-get update && apt-get install -y \
    nodejs \
    npm \
    bash \
    microsocks \
    socat \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install wstunnel globally
RUN npm install -g wstunnel

# Environment variables with sensible defaults
ENV WSTUNNEL_MODE="client" \
    WSTUNNEL_REMOTE="" \
    WSTUNNEL_REMOTE_FORWARD="" \
    WSTUNNEL_LOCAL_FORWARD="" \
    WSTUNNEL_PORT="8000" \
    SOCKS5_PORT="1080"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
