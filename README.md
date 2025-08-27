# Wstunnel Container Image

This repository contains a container image for **wstunnel** that supports:
- **Server mode**
- **Client mode**
- **SOCKS5 reverse proxy mode**
- **TLS (with optional self-signed certificates)**

## Features
- Configurable via **environment variables**
- Supports **dynamic port forwarding** (`-R` and `-L`)
- Can act as a **SOCKS5 reverse proxy** for browser use
- TLS support with optional self-signed certificates

## Environment Variables

### Common
- `WSTUNNEL_MODE`: `server` or `client`
- `WSTUNNEL_REMOTE`: WebSocket URL (`ws://` or `wss://`)
- `WSTUNNEL_REMOTE_FORWARD`: Reverse port forward, e.g. `tcp://[::]:22222:localhost:22`

### TLS
- `WSTUNNEL_TLS_ENABLE`: `true` to enable TLS (default: `false`)
- `WSTUNNEL_TLS_CERT`: Path to TLS certificate (default: `/etc/wstunnel/server.crt`)
- `WSTUNNEL_TLS_KEY`: Path to TLS key (default: `/etc/wstunnel/server.key`)

## Image Usage

### 1. Run Server and Client services

#### Server (outside FW/NAT)

This example starts the `wstunnel` server using **TLS** on port **8180** and exposes a **SOCKS5 proxy** on port **8080** once a client connects. Ports must be accessible from outside.

```bash
podman run -d \
  -e WSTUNNEL_MODE=server \
  -e WSTUNNEL_TLS_ENABLE=true \
  -e WSTUNNEL_SOCKS5_PORT=8080 \
  -p 8180:8180 \
  -p 8080:8080 \
  quay.io/luisarizmendi/wstunnel:latest
```

#### Client (inside FW/NAT)

Connects to the server at `my.server.com:8180` and establishes a **reverse port forward** from server port **22222** to client port 22.

```bash
podman run --rm \
  -e WSTUNNEL_MODE=client \
  -e WSTUNNEL_REMOTE=wss://my.server.com:8180 \
  -e WSTUNNEL_REMOTE_FORWARD="tcp://[::]:22222:localhost:22" \
  quay.io/luisarizmendi/wstunnel:latest
```

---

### 2. Use the tunnel

#### Connecting using SSH

Connect to the client through the tunnel using the Server's IP:

```bash
ssh -p 22222 <client-side user>@<server IP>
```

- Replace `<client-side user>` with a valid user on the client machine.
- Works even if the client is behind NAT or a firewall.

#### Using the SOCKS proxy

If SOCKS5 is enabled (`WSTUNNEL_SOCKS5_PORT=8080`), configure your applications to use:

- **SOCKS5 host:** `my.server.com`
- **Port:** `8080`

Example with `curl`:

```bash
curl --socks5 my.server.com:8080 https://ifconfig.me
```

This routes traffic through the encrypted WebSocket tunnel between client and server.


You can also make use of the [`proxy.pac`](proxy.pac) file to configure your Browser, you just need to addapt it to your needs, for example:

```javascript
function FindProxyForURL(url, host) {

    if (shExpMatch(host, "*.minismartfactory.com") ||
        shExpMatch(host, "*//10.*")) {
        return "SOCKS5 mypublicserver:8080";
    }

    // All other traffic goes direct (no proxy)
    return "DIRECT";
}

```
- Domains/IPs matching the rules go through the SOCKS5 proxy.  
- All other traffic goes direct.

In order to use the file:

- **Firefox:** Preferences → Network Settings → Automatic proxy configuration URL → select `proxy.pac`.  
- **Chrome:** Configure the PAC file in your OS network settings.

Use this to route only desired traffic through your wstunnel SOCKS5 proxy while other connections remain direct.

