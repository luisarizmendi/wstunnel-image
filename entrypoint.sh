#!/bin/bash
set -e

# Start SOCKS5 proxy if port is defined and mode is client
if [ "$WSTUNNEL_MODE" = "client" ] && [ -n "$SOCKS5_PORT" ]; then
    echo "Starting SOCKS5 server on port $SOCKS5_PORT..."
    microsocks -p "$SOCKS5_PORT" &
fi

# If command-line arguments are passed, run them directly
if [ $# -gt 0 ]; then
    exec wstunnel "$@"
fi

# Build wstunnel command from environment variables
if [ "$WSTUNNEL_MODE" = "server" ]; then
    CMD="wstunnel --server"
    [ -n "$WSTUNNEL_PORT" ] && CMD="$CMD :$WSTUNNEL_PORT"

elif [ "$WSTUNNEL_MODE" = "client" ]; then
    CMD="wstunnel --client"

    # Add remote URL
    [ -n "$WSTUNNEL_REMOTE" ] && CMD="$CMD $WSTUNNEL_REMOTE"

    # Add remote forwards (-R)
    if [ -n "$WSTUNNEL_REMOTE_FORWARD" ]; then
        IFS=',' read -ra FORWARDS <<< "$WSTUNNEL_REMOTE_FORWARD"
        for f in "${FORWARDS[@]}"; do
            CMD="$CMD -R $f"
        done
    fi

    # Add local forwards (-L)
    if [ -n "$WSTUNNEL_LOCAL_FORWARD" ]; then
        IFS=',' read -ra LFORWARDS <<< "$WSTUNNEL_LOCAL_FORWARD"
        for f in "${LFORWARDS[@]}"; do
            CMD="$CMD -L $f"
        done
    fi
else
    echo "Invalid WSTUNNEL_MODE: $WSTUNNEL_MODE"
    exit 1
fi

echo "Running: $CMD"
exec bash -c "$CMD"
