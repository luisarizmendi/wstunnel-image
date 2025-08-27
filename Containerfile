FROM debian:stable-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    nodejs \
    npm \
    bash \
    microsocks \
    socat \
    openssl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install the npm version of wstunnel (mhzed/wstunnel) which uses -s/-t syntax
RUN npm install -g wstunnel

# Environment variables with sensible defaults
ENV WSTUNNEL_MODE="client" \
    WSTUNNEL_REMOTE="" \
    WSTUNNEL_REMOTE_FORWARD="" \
    WSTUNNEL_LOCAL_FORWARD="" \
    WSTUNNEL_PORT="8080" \
    SOCKS5_PORT="1080" \
    WSTUNNEL_TLS_ENABLE="false" \
    WSTUNNEL_TLS_CERT="/etc/wstunnel/server.crt" \
    WSTUNNEL_TLS_KEY="/etc/wstunnel/server.key"

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]