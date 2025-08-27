#!/usr/bin/env bash
set -e

# Default values
MODE="${WSTUNNEL_MODE:-client}"
REMOTE="${WSTUNNEL_REMOTE}"
REMOTE_FORWARD="${WSTUNNEL_REMOTE_FORWARD}"
LOCAL_FORWARD="${WSTUNNEL_LOCAL_FORWARD}"
PORT="${WSTUNNEL_PORT:-8000}"
SOCKS5_PORT="${SOCKS5_PORT:-1080}"
TLS_ENABLE="${WSTUNNEL_TLS_ENABLE:-false}"
TLS_CERT="${WSTUNNEL_TLS_CERT:-/etc/wstunnel/server.crt}"
TLS_KEY="${WSTUNNEL_TLS_KEY:-/etc/wstunnel/server.key}"

# TLS options
TLS_ARGS=""
if [[ "$TLS_ENABLE" == "true" ]]; then
    if [[ ! -f "$TLS_CERT" || ! -f "$TLS_KEY" ]]; then
        echo "Generating self-signed certificate for TLS..."
        mkdir -p "$(dirname "$TLS_CERT")"
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$TLS_KEY" -out "$TLS_CERT" \
            -subj "/CN=localhost"
    fi
    TLS_ARGS="--cert $TLS_CERT --key $TLS_KEY"
fi

# Run in the desired mode
case "$MODE" in
    server)
        echo "Starting wstunnel server on port $PORT..."
        exec wstunnel server -l "0.0.0.0:$PORT" $TLS_ARGS
        ;;
    client)
        if [[ -n "$REMOTE_FORWARD" ]]; then
            echo "Starting wstunnel client with remote forward: $REMOTE_FORWARD -> $REMOTE"
            exec wstunnel client -R "$REMOTE_FORWARD" $REMOTE $TLS_ARGS
        elif [[ -n "$LOCAL_FORWARD" ]]; then
            echo "Starting wstunnel client with local forward: $LOCAL_FORWARD -> $REMOTE"
            exec wstunnel client -L "$LOCAL_FORWARD" $REMOTE $TLS_ARGS
        else
            echo "No forward configuration provided. Exiting..."
            exit 1
        fi
        ;;
    socks5)
        echo "Starting SOCKS5 proxy on port $SOCKS5_PORT and tunneling to $REMOTE..."
        microsocks -p "$SOCKS5_PORT" &
        exec wstunnel client -R "tcp://[::]:$SOCKS5_PORT:localhost:$SOCKS5_PORT" $REMOTE $TLS_ARGS
        ;;
    *)
        echo "Unknown mode: $MODE"
        exit 1
        ;;
esac
