from __future__ import annotations

import ipaddress
import socket
from urllib.parse import urlparse


def validate_public_http_url(url: str) -> None:
    parsed = urlparse(url)
    if parsed.scheme not in {"http", "https"}:
        raise ValueError("Only http:// and https:// URLs are allowed")
    if parsed.username or parsed.password:
        raise ValueError("URLs containing embedded credentials are not allowed")
    hostname = parsed.hostname
    if not hostname:
        raise ValueError("URL must include a hostname")
    try:
        infos = socket.getaddrinfo(hostname, None, type=socket.SOCK_STREAM)
    except socket.gaierror as exc:
        raise ValueError(f"Could not resolve hostname: {hostname}") from exc
    addresses = {ipaddress.ip_address(info[4][0]) for info in infos}
    if not addresses:
        raise ValueError("Hostname did not resolve to an address")
    # ``is_global`` is deliberately stricter than a deny-list of known private
    # ranges.  It also rejects carrier-grade NAT and special-purpose address
    # space, which must not be reachable through a public-web research tool.
    blocked = [str(ip) for ip in addresses if not ip.is_global]
    if blocked:
        raise ValueError("Non-public, loopback, link-local, multicast, reserved, or unspecified hosts are blocked")
