import argparse
import http.server
import ipaddress
import os
import select
import shutil
import socket
import struct
import subprocess
import sys
import tempfile
import time
import threading
from urllib.parse import urlsplit

MAX_TTL_SECONDS = 600
SO_BINDTODEVICE = getattr(socket, "SO_BINDTODEVICE", 25)


def bind_device(sock, device):
    if not device or "/" in device or "\x00" in device:
        raise ValueError("Invalid Wi-Fi interface")
    sock.setsockopt(socket.SOL_SOCKET, SO_BINDTODEVICE, device.encode("utf-8") + b"\x00")


def parse_ip(host, device):
    address = host
    zone = ""
    if "%" in address:
        address, zone = address.split("%", 1)
        if zone.startswith("25"):
            zone = zone[2:]
    parsed = ipaddress.ip_address(address)
    if zone and (not isinstance(parsed, ipaddress.IPv6Address)
                 or not parsed.is_link_local
                 or zone not in (device, str(socket.if_nametoindex(device)))):
        raise ValueError("Invalid IPv6 scope")
    return parsed


def endpoint(address, port, device):
    if isinstance(address, ipaddress.IPv6Address):
        scope = socket.if_nametoindex(device) if address.is_link_local else 0
        return (str(address), port, 0, scope)
    return (str(address), port)


def dns_addresses(host, device, dns_servers):
    try:
        literal = parse_ip(host, device)
        return [literal]
    except ValueError:
        if "%" in host:
            return []
    try:
        hostname = host.encode("idna").decode("ascii").rstrip(".")
    except UnicodeError:
        return []
    labels = hostname.split(".")
    if not hostname or any(not label or len(label) > 63 for label in labels):
        return []
    qname = b"".join(bytes([len(label)]) + label.encode("ascii") for label in labels) + b"\x00"
    answers = []
    for record_type in (28, 1):
        for server in dns_servers:
            try:
                address = parse_ip(server, device)
                family = socket.AF_INET6 if address.version == 6 else socket.AF_INET
                query_id = os.urandom(2)
                request = query_id + struct.pack("!HHHHH", 0x0100, 1, 0, 0, 0)
                request += qname + struct.pack("!HH", record_type, 1)
                with socket.socket(family, socket.SOCK_DGRAM) as sock:
                    bind_device(sock, device)
                    sock.settimeout(1.5)
                    sock.connect(endpoint(address, 53, device))
                    sock.sendall(request)
                    response = sock.recv(4096)
                if len(response) < 12 or response[:2] != query_id:
                    continue
                flags, questions, count = struct.unpack("!HHH", response[2:8])
                if not flags & 0x8000 or flags & 0x020F:
                    continue
                cursor = 12
                for _ in range(questions):
                    cursor = skip_name(response, cursor)
                    if cursor + 4 > len(response):
                        raise ValueError("DNS question truncated")
                    cursor += 4
                for _ in range(count):
                    cursor = skip_name(response, cursor)
                    if cursor + 10 > len(response):
                        raise ValueError("DNS record truncated")
                    kind, record_class, _, size = struct.unpack("!HHIH", response[cursor:cursor + 10])
                    cursor += 10
                    if cursor + size > len(response):
                        raise ValueError("DNS data truncated")
                    if kind == record_type and record_class == 1 and size == (16 if kind == 28 else 4):
                        value = ipaddress.ip_address(response[cursor:cursor + size])
                        if value not in answers:
                            answers.append(value)
                    cursor += size
            except (OSError, UnicodeError, ValueError, IndexError, struct.error):
                continue
    return answers


def skip_name(message, cursor):
    for _ in range(128):
        if cursor >= len(message):
            raise ValueError("DNS packet truncated")
        count = message[cursor]
        if count & 0xC0 == 0xC0:
            if cursor + 1 >= len(message):
                raise ValueError("DNS compression truncated")
            return cursor + 2
        if count == 0:
            return cursor + 1
        if count > 63:
            raise ValueError("Bad DNS label")
        cursor += 1 + count
    raise ValueError("DNS name too long")


def connect_wifi(host, port, device, dns_servers):
    addresses = dns_addresses(host, device, dns_servers)
    if not addresses:
        raise OSError("Wi-Fi DNS did not resolve " + host)
    last_error = None
    for address in addresses:
        family = socket.AF_INET6 if address.version == 6 else socket.AF_INET
        sock = socket.socket(family, socket.SOCK_STREAM)
        try:
            bind_device(sock, device)
            sock.settimeout(9)
            sock.connect(endpoint(address, port, device))
            return sock
        except OSError as error:
            last_error = error
            sock.close()
    raise OSError("Wi-Fi could not reach " + host) from last_error


class PortalProxy(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    daemon_threads = True
    timeout = 15

    def log_message(self, fmt, *args):
        return

    def do_CONNECT(self):
        authority = self.path.strip()
        try:
            host, port = parse_authority(authority, 443)
            with connect_wifi(host, port, self.server.wifi_device, self.server.wifi_dns) as remote:
                self.send_response(200, "Connection established")
                self.end_headers()
                self.connection.settimeout(90)
                remote.settimeout(90)
                relay(self.connection, remote)
        except (OSError, ValueError):
            try:
                self.send_error(502, "Wi-Fi hotspot unavailable")
            except OSError:
                pass
        self.close_connection = True

    def do_GET(self):
        self.forward_http()

    def do_POST(self):
        self.forward_http()

    def do_HEAD(self):
        self.forward_http()

    def do_OPTIONS(self):
        self.forward_http()

    def forward_http(self):
        try:
            parsed = urlsplit(self.path)
            if parsed.scheme != "http" or not parsed.hostname:
                self.send_error(400, "Expected HTTP proxy request")
                return
            host, port = parsed.hostname, parsed.port or 80
            path = parsed.path or "/"
            if parsed.query:
                path += "?" + parsed.query
            if self.headers.get("Transfer-Encoding"):
                self.send_error(501, "Unsupported portal upload encoding")
                return
            content_length = int(self.headers.get("Content-Length", "0"))
            if content_length < 0 or content_length > 2_000_000:
                self.send_error(413, "Request too large")
                return
            with connect_wifi(host, port, self.server.wifi_device, self.server.wifi_dns) as remote:
                method = self.command
                remote.sendall((method + " " + path + " HTTP/1.1\r\n").encode())
                for key, value in self.headers.items():
                    if key.lower() not in ("connection", "proxy-connection", "proxy-authorization"):
                        remote.sendall((key + ": " + value + "\r\n").encode("latin-1"))
                remote.sendall(b"Connection: close\r\n\r\n")
                remaining = content_length
                while remaining:
                    chunk = self.rfile.read(min(65536, remaining))
                    if not chunk:
                        break
                    remote.sendall(chunk)
                    remaining -= len(chunk)
                remote.settimeout(20)
                while True:
                    chunk = remote.recv(65536)
                    if not chunk:
                        break
                    self.connection.sendall(chunk)
            self.close_connection = True
        except (OSError, ValueError, UnicodeError):
            try:
                self.send_error(502, "Wi-Fi hotspot unavailable")
            except OSError:
                pass
            self.close_connection = True


def parse_authority(text, default_port):
    if not text or any(char.isspace() for char in text) or "/" in text or "@" in text:
        raise ValueError("Invalid proxy target")
    if text.startswith("["):
        host, closing, rest = text[1:].partition("]")
        if not closing or (rest and not rest.startswith(":")):
            raise ValueError("Malformed IPv6 authority")
        if not isinstance(ipaddress.ip_address(host.split("%", 1)[0]), ipaddress.IPv6Address):
            raise ValueError("Expected IPv6 authority")
        port = int(rest[1:]) if rest else default_port
    else:
        if text.count(":") > 1:
            raise ValueError("IPv6 authority must be bracketed")
        host, separator, value = text.partition(":")
        port = int(value) if separator else default_port
    if not host or not 1 <= port <= 65535:
        raise ValueError("Invalid proxy target")
    return host, port


def relay(client, remote):
    sockets = [client, remote]
    while True:
        readable, _, _ = select.select(sockets, [], [], 60)
        if not readable:
            return
        for source in readable:
            data = source.recv(65536)
            if not data:
                return
            (remote if source is client else client).sendall(data)


def choose_browser(profile, url, port):
    preferences = {
        "network.proxy.type": "1",
        "network.proxy.http": '"127.0.0.1"',
        "network.proxy.http_port": str(port),
        "network.proxy.ssl": '"127.0.0.1"',
        "network.proxy.ssl_port": str(port),
        "network.proxy.no_proxies_on": '""',
        "network.trr.mode": "5",
        "network.proxy.allow_hijacking_localhost": "true",
        "browser.shell.checkDefaultBrowser": "false",
        "browser.startup.homepage_override.mstone": '"ignore"',
    }
    with open(os.path.join(profile, "user.js"), "w", encoding="utf-8") as f:
        for name, value in preferences.items():
            f.write('user_pref("' + name + '", ' + value + ');\n')

    for browser in ("firefox", "librewolf"):
        executable = shutil.which(browser)
        if executable:
            return [executable, "--no-remote", "--profile", profile, "--new-window", url]
    for browser in ("chromium", "chromium-browser", "google-chrome", "brave-browser"):
        executable = shutil.which(browser)
        if executable:
            return [executable, "--user-data-dir=" + profile,
                    "--proxy-server=http://127.0.0.1:" + str(port),
                    "--proxy-bypass-list=<-loopback>",
                    "--no-first-run", "--new-window", url]
    return None


def serve(device, url, dns):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
        bind_device(probe, device)

    with tempfile.TemporaryDirectory(prefix="caelestia-wifi-login-") as profile:
        server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), PortalProxy)
        server.wifi_device = device
        server.wifi_dns = dns
        port = server.server_port
        browser_command = choose_browser(profile, url, port)
        if not browser_command:
            server.server_close()
            return 3

        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            browser = subprocess.Popen(browser_command, stdout=subprocess.DEVNULL,
                                       stderr=subprocess.DEVNULL)
            time.sleep(0.5)
            if browser.poll() is not None:
                print("ERROR: browser quit during startup", flush=True)
                return 4
            print("READY", flush=True)
            try:
                browser.wait(timeout=MAX_TTL_SECONDS)
            except subprocess.TimeoutExpired:
                pass
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=2)
    return 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--interface", required=True)
    parser.add_argument("--url", required=True)
    parser.add_argument("--dns", default="")
    args = parser.parse_args()
    if args.url.startswith(("http://", "https://")):
        try:
            return serve(args.interface, args.url, args.dns.split(",") if args.dns else [])
        except (OSError, ValueError) as exc:
            print("ERROR: " + str(exc), flush=True)
            return 4
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
