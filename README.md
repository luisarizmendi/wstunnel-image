# wstunnel-container

A flexible container image for **wstunnel** that can function as a **server or client**, with support for **dynamic port forwarding** and an optional **SOCKS5 proxy** for browser traffic through the client machine.

---

## Features

- Run as **wstunnel server** or **client** via environment variables.
- Dynamic **remote (-R) and local (-L) port forwarding** from environment variables.
- Optional **SOCKS5 proxy** to route browser traffic through the client machine.
- Accepts command-line arguments directly, overriding environment variables.
- Minimal Alpine-based image with Node.js, npm, microsocks, and wstunnel installed.

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WSTUNNEL_MODE` | `client` | Mode: `server` or `client`. |
| `WSTUNNEL_REMOTE` | `""` | Remote server URL for client mode. |
| `WSTUNNEL_REMOTE_FORWARD` | `""` | Comma-separated `-R` port forwards (e.g., `tcp://[::]:22222:localhost:22`). |
| `WSTUNNEL_LOCAL_FORWARD` | `""` | Comma-separated `-L` port forwards. |
| `WSTUNNEL_PORT` | `8000` | Server listening port (for server mode). |
| `SOCKS5_PORT` | `1080` | Port for SOCKS5 proxy (client mode only). |

---

## Usage

### Server Mode

```bash
podman run -e WSTUNNEL_MODE=server \
           -e WSTUNNEL_PORT=8180 \
           -p 8180:8180 \
           my-wstunnel
```

### Client Mode with Port Forwarding and SOCKS5 Proxy

```bash
podman run -e WSTUNNEL_MODE=client \
           -e WSTUNNEL_REMOTE=wss://my.server.com:8180 \
           -e WSTUNNEL_REMOTE_FORWARD="tcp://[::]:22222:localhost:22" \
           -e SOCKS5_PORT=1080 \
           -p 1080:1080 \
           my-wstunnel
```

- Browser HTTP/SOCKS5 proxy → `<server_ip>:1080`
- All traffic will exit from the **client machine**.

### Direct Command Override

You can pass arguments directly to the container instead of using environment variables:

```bash
podman run my-wstunnel client -R 'tcp://[::]:22222:localhost:22' wss://my.server.com:8180
```

---

## Build

```bash
podman build -t my-wstunnel .
```


---

## Ready-to-use image

You can find this container image in [quay.io/luisarizmendi/wstunnel:latest](quay.io/luisarizmendi/wstunnel:latest)

---

## Notes

- `EXPOSE` statements are not required; container ports are mapped at runtime using `-p`.
- SOCKS5 proxy (`microsocks`) is optional and only started in client mode if `SOCKS5_PORT` is set.
- Multiple remote or local forwards can be set as **comma-separated lists** in environment variables.

