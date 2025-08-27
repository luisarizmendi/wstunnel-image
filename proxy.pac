function FindProxyForURL(url, host) {

    if (shExpMatch(host, "*.<forwarded domain, example: mylocal.com>") ||
        shExpMatch(host, "*//<optional: Add IP addressing, example: 10.*>")) {
        return "SOCKS5 <server IP>:<server WSTUNNEL_SOCKS5_PORT>";
    }

    // All other traffic goes direct (no proxy)
    return "DIRECT";
}
