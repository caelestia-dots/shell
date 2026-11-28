import http.client
import http.server
import ipaddress
import struct
from unittest.mock import patch
import importlib.util
import pathlib
import socket
import socketserver
import tempfile
import threading
import unittest

SPEC = importlib.util.spec_from_file_location("portal_browser",
    pathlib.Path(__file__).resolve().parents[2] / "assets" / "captive-portal" / "portal_browser.py")
proxy = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(proxy)


class Reply(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        data = b"Wi-Fi proxy works"
        self.send_response(200)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)
    def log_message(self, *args):
        pass


class IPv6HTTPServer(http.server.ThreadingHTTPServer):
    address_family = socket.AF_INET6


class IPv6TCPServer(socketserver.ThreadingTCPServer):
    address_family = socket.AF_INET6


class Echo(socketserver.BaseRequestHandler):
    def handle(self):
        self.request.sendall(self.request.recv(4096))


class PortalBrowserTests(unittest.TestCase):
    def setUp(self):
        self.backend = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Reply)
        self.frontend = http.server.ThreadingHTTPServer(("127.0.0.1", 0), proxy.PortalProxy)
        self.frontend.wifi_device = "lo"
        self.frontend.wifi_dns = []
        self.threads = []
        for server in (self.backend, self.frontend):
            t = threading.Thread(target=server.serve_forever, daemon=True)
            t.start()
            self.threads.append(t)

    def tearDown(self):
        for server in (self.frontend, self.backend):
            server.shutdown()
            server.server_close()
        for thread in self.threads:
            thread.join(timeout=2)

    def test_http_proxy_binds_to_specific_interface(self):
        conn = http.client.HTTPConnection("127.0.0.1", self.frontend.server_port, timeout=4)
        try:
            url = "http://127.0.0.1:" + str(self.backend.server_port) + "/login"
            conn.request("GET", url)
            result = conn.getresponse()
            self.assertEqual(result.status, 200)
            self.assertEqual(result.read(), b"Wi-Fi proxy works")
        finally:
            conn.close()

    def test_tls_connect_tunnel_passes_bidirectional_bytes(self):
        echo = socketserver.ThreadingTCPServer(("127.0.0.1", 0), Echo)
        thread = threading.Thread(target=echo.serve_forever, daemon=True)
        thread.start()
        try:
            with socket.create_connection(("127.0.0.1", self.frontend.server_port), timeout=5) as client:
                client.sendall(("CONNECT 127.0.0.1:" + str(echo.server_address[1])
                                + " HTTP/1.1\r\nHost: test\r\n\r\n").encode())
                response = b""
                while b"\r\n\r\n" not in response:
                    response += client.recv(1024)
                self.assertIn(b"200 Connection established", response)
                client.sendall(b"test tunnel")
                self.assertEqual(client.recv(100), b"test tunnel")
        finally:
            echo.shutdown()
            echo.server_close()
            thread.join(timeout=2)

    def test_ipv6_http_proxy_to_loopback(self):
        with IPv6HTTPServer(("::1", 0), Reply) as backend:
            thread = threading.Thread(target=backend.serve_forever, daemon=True)
            thread.start()
            try:
                connection = http.client.HTTPConnection("127.0.0.1", self.frontend.server_port, timeout=5)
                try:
                    connection.request("GET", f"http://[::1]:{backend.server_port}/login")
                    reply = connection.getresponse()
                    self.assertEqual(reply.status, 200)
                    self.assertEqual(reply.read(), b"Wi-Fi proxy works")
                finally:
                    connection.close()
            finally:
                backend.shutdown()
                thread.join(timeout=2)

    def test_ipv6_connect_tunnel_to_loopback(self):
        with IPv6TCPServer(("::1", 0), Echo) as backend:
            thread = threading.Thread(target=backend.serve_forever, daemon=True)
            thread.start()
            try:
                with socket.create_connection(("127.0.0.1", self.frontend.server_port), timeout=5) as client:
                    client.sendall((f"CONNECT [::1]:{backend.server_address[1]} HTTP/1.1\r\n"
                                    "Host: [::1]\r\n\r\n").encode())
                    reply = b""
                    while b"\r\n\r\n" not in reply:
                        reply += client.recv(1024)
                    self.assertIn(b"200 Connection established", reply)
                    client.sendall(b"ipv6 tunnel")
                    self.assertEqual(client.recv(100), b"ipv6 tunnel")
            finally:
                backend.shutdown()
                thread.join(timeout=2)

    def test_ipv6_authority_and_link_local_scope(self):
        self.assertEqual(proxy.parse_authority("[2001:db8::42]:8443", 443), ("2001:db8::42", 8443))
        self.assertEqual(proxy.parse_authority("[fe80::1%25lo]", 443), ("fe80::1%25lo", 443))
        self.assertEqual(proxy.endpoint(proxy.parse_ip("fe80::1%25lo", "lo"), 80, "lo")[3],
                         socket.if_nametoindex("lo"))
        with self.assertRaises(ValueError):
            proxy.parse_authority("2001:db8::42:8443", 443)
        with self.assertRaises(ValueError):
            proxy.parse_ip("fe80::1%25other", "lo")

    def test_ipv6_dns_aaaa_via_wifi_dns_server(self):
        calls = []

        class DNS:
            flags = 0x8180
            def __init__(self, family, kind):
                self.family = family
            def __enter__(self):
                return self
            def __exit__(self, *_):
                pass
            def setsockopt(self, *_):
                pass
            def settimeout(self, *_):
                pass
            def connect(self, destination):
                self.destination = destination
            def sendall(self, query):
                self.query = query
                calls.append((self.family, self.destination, struct.unpack("!H", query[-4:-2])[0]))
            def recv(self, length):
                kind = struct.unpack("!H", self.query[-4:-2])[0]
                packed = (ipaddress.IPv6Address("2001:db8::99").packed if kind == 28
                          else ipaddress.IPv4Address("192.0.2.99").packed)
                response = (self.query[:2] + struct.pack("!HHHHH", type(self).flags, 1, 1, 0, 0)
                            + self.query[12:] + b"\xc0\x0c" + struct.pack("!HHIH", kind, 1, 60, len(packed))
                            + packed)
                return response

        with patch.object(proxy.socket, "socket", side_effect=DNS):
            answers = proxy.dns_addresses("portal.test", "lo", ["fd00::53"])
        self.assertEqual([str(item) for item in answers], ["2001:db8::99", "192.0.2.99"])
        self.assertEqual([item[0] for item in calls], [socket.AF_INET6, socket.AF_INET6])
        self.assertEqual([item[2] for item in calls], [28, 1])
        DNS.flags = 0x8380
        with patch.object(proxy.socket, "socket", side_effect=DNS):
            self.assertEqual(proxy.dns_addresses("portal.test", "lo", ["fd00::53"]), [])

    def test_isolated_firefox_profile_contains_proxy_settings(self):
        with tempfile.TemporaryDirectory() as directory:
            browser = proxy.choose_browser(directory, "http://192.168.44.1/", 34567)
            self.assertIsNotNone(browser)
            self.assertIn(directory, browser)
            if pathlib.Path(directory, "user.js").exists():
                config = pathlib.Path(directory, "user.js").read_text()
                self.assertIn("network.proxy.ssl_port", config)
                self.assertIn("network.trr.mode", config)
                self.assertIn("34567", config)

    def test_chromium_profile_disables_implicit_loopback_proxy_bypass(self):
        with tempfile.TemporaryDirectory() as directory:
            def resolve(name):
                return "/usr/bin/chromium" if name == "chromium" else None
            with patch.object(proxy.shutil, "which", side_effect=resolve):
                command = proxy.choose_browser(directory, "http://127.0.0.1/login", 34567)
        self.assertIn("--proxy-bypass-list=<-loopback>", command)
        self.assertIn("--proxy-server=http://127.0.0.1:34567", command)

    def test_interface_binding_unprivileged(self):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            proxy.bind_device(s, "lo")
            self.assertIsNotNone(s)


if __name__ == "__main__":
    unittest.main()
