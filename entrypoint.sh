#!/usr/bin/env bash
set -e

# Default values
MODE="${WSTUNNEL_MODE:-client}"
REMOTE="${WSTUNNEL_REMOTE}"
REMOTE_FORWARD="${WSTUNNEL_REMOTE_FORWARD}"
LOCAL_FORWARD="${WSTUNNEL_LOCAL_FORWARD}"
PORT="${WSTUNNEL_PORT:-8080}"
SOCKS5_PORT="${SOCKS5_PORT:-1080}"
TLS_ENABLE="${WSTUNNEL_TLS_ENABLE:-false}"
TLS_CERT="${WSTUNNEL_TLS_CERT:-/etc/wstunnel/server.crt}"
TLS_KEY="${WSTUNNEL_TLS_KEY:-/etc/wstunnel/server.key}"

# TLS options for server mode (npm wstunnel supports HTTPS via normal cert setup)
if [[ "$TLS_ENABLE" == "true" && "$MODE" == "server" ]]; then
    if [[ ! -f "$TLS_CERT" || ! -f "$TLS_KEY" ]]; then
        echo "Generating self-signed certificate for TLS..."
        mkdir -p "$(dirname "$TLS_CERT")"
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$TLS_KEY" -out "$TLS_CERT" \
            -subj "/CN=localhost"
    fi
fi

# Run in the desired mode
case "$MODE" in
    server)
        echo "Starting wstunnel server on port $PORT..."
        # npm wstunnel syntax: wstunnel -s PORT
        exec wstunnel -s "$PORT"
        ;;
    client)
        if [[ -z "$REMOTE" ]]; then
            echo "Error: WSTUNNEL_REMOTE must be set for client mode"
            exit 1
        fi
        
        if [[ -n "$REMOTE_FORWARD" ]]; then
            echo "Starting wstunnel client with remote forward: $REMOTE_FORWARD -> $REMOTE"
            # For remote forward, we need to parse the format tcp://port:host:port
            # and use -t local_port for the tunnel
            LOCAL_PORT=$(echo "$REMOTE_FORWARD" | sed -n 's/.*:\/\/.*:\([0-9]*\):.*/\1/p')
            if [[ -z "$LOCAL_PORT" ]]; then
                echo "Error: Could not parse local port from REMOTE_FORWARD: $REMOTE_FORWARD"
                exit 1
            fi
            exec wstunnel -t "$LOCAL_PORT" "$REMOTE"
        elif [[ -n "$LOCAL_FORWARD" ]]; then
            echo "Starting wstunnel client with local forward: $LOCAL_FORWARD -> $REMOTE"
            # For local forward, parse tcp://port:host:port format
            LOCAL_PORT=$(echo "$LOCAL_FORWARD" | sed -n 's/.*:\/\/.*:\([0-9]*\):.*/\1/p')
            if [[ -z "$LOCAL_PORT" ]]; then
                echo "Error: Could not parse local port from LOCAL_FORWARD: $LOCAL_FORWARD"
                exit 1
            fi
            exec wstunnel -t "$LOCAL_PORT" "$REMOTE"
        else
            echo "Error: Either WSTUNNEL_REMOTE_FORWARD or WSTUNNEL_LOCAL_FORWARD must be set"
            exit 1
        fi
        ;;
    socks5)
        if [[ -z "$REMOTE" ]]; then
            echo "Error: WSTUNNEL_REMOTE must be set for socks5 mode"
            exit 1
        fi
        echo "Starting SOCKS5 proxy on port $SOCKS5_PORT and tunneling to $REMOTE..."
        # Start microsocks in background
        microsocks -i 0.0.0.0 -p "$SOCKS5_PORT" &
        MICROSOCKS_PID=$!
        
        # Function to cleanup on exit
        cleanup() {
            echo "Cleaning up..."
            kill $MICROSOCKS_PID 2>/dev/null || true
            exit 0
        }
        trap cleanup SIGTERM SIGINT
        
        # Use wstunnel to tunnel the SOCKS5 proxy port
        exec wstunnel -t "$SOCKS5_PORT" "$REMOTE"
        ;;
    *)
        echo "Unknown mode: $MODE"
        echo "Supported modes: server, client, socks5"
        exit 1
        ;;
esac