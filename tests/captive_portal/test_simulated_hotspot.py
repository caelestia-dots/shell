import http.server
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import threading
import unittest

ROOT = Path(__file__).resolve().parents[2]
DETECTOR = ROOT / "assets" / "captive-portal" / "check"

NMCLI = r'''#!/bin/sh
case "$*" in
  "-t -f DEVICE,TYPE,STATE device status") printf 'wlan0:wifi:connected\n';;
  "-g GENERAL.CONNECTION device show wlan0") printf 'Test Hotspot\n';;
  "-f DHCP4.OPTION,DHCP6.OPTION device show wlan0") :;;
  "networking connectivity") printf 'limited\n';;
esac
'''

CURL = r'''#!/usr/bin/env python3
import os
import subprocess
import sys
from urllib.parse import urlsplit

args = sys.argv[1:]
out = []
mapping = {
    "connectivitycheck.gstatic.com": "google",
    "detectportal.firefox.com": "firefox",
    "captive.apple.com": "apple",
    "ping.archlinux.org": "arch",
    "www.msftconnecttest.com": "msft",
    "httpbin.org": "canary",
    "httpbingo.org": "canary",
    "cp.cloudflare.com": "canary",
    "www.cloudflare.com": "https",
}
i = 0
while i < len(args):
    item = args[i]
    if item == "--interface":
        i += 2
        continue
    if item.startswith(("http://", "https://")):
        host = urlsplit(item).hostname
        item = os.environ["PORTAL_TEST_BASE"] + "/" + mapping.get(host, "other")
    out.append(item)
    i += 1
proc = subprocess.run(["/usr/bin/curl", *out], capture_output=True)
sys.stdout.buffer.write(proc.stdout)
sys.stderr.buffer.write(proc.stderr)
sys.exit(proc.returncode)
'''


class Hotspot(http.server.BaseHTTPRequestHandler):
    mode = "redirect"

    def do_GET(self):
        route = self.path.strip("/")
        if type(self).mode == "broken":
            self.send_response(503)
            self.end_headers()
            return
        if route == "firefox" and type(self).mode == "redirect":
            self.send_response(302)
            self.send_header("Location", f"http://127.0.0.1:{self.server.server_port}/login")
            self.end_headers()
            return
        if route in ("firefox", "apple") and type(self).mode == "inject":
            code, body = 200, b"<HTML><TITLE>Log in to Wi-Fi</TITLE></HTML>"
        elif route in ("google", "canary"):
            code, body = 204, b""
        elif route == "firefox":
            code, body = 200, b"success"
        elif route == "apple":
            code, body = 200, b"<HTML><TITLE>Success</TITLE></HTML>"
        elif route == "arch":
            code, body = 200, b"NetworkManager is online"
        elif route == "msft":
            code, body = 200, b"Microsoft Connect Test"
        else:
            code, body = 200, b"online"
        self.send_response(code)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if body:
            self.wfile.write(body)

    def log_message(self, *_):
        pass


class RealHttpDetectorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Hotspot)
        cls.worker = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.worker.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.worker.join(timeout=3)

    def run_detector(self, mode):
        Hotspot.mode = mode
        with tempfile.TemporaryDirectory(prefix="caelestia-http-fixture-") as tempdir:
            temp = Path(tempdir)
            for name, source in (("nmcli", NMCLI), ("curl", CURL)):
                path = temp / name
                path.write_text(source)
                path.chmod(path.stat().st_mode | stat.S_IXUSR)
            env = {
                **os.environ,
                "PATH": str(temp) + os.pathsep + os.environ["PATH"],
                "PORTAL_TEST_BASE": f"http://127.0.0.1:{self.server.server_port}",
                "TMPDIR": str(temp),
            }
            result = subprocess.run(["bash", str(DETECTOR)], env=env,
                                    capture_output=True, text=True, timeout=12)
            self.assertEqual(result.returncode, 0, result.stderr)
            return result.stdout.strip()

    def test_redirect_wins_over_successful_connectivity_checks(self):
        result = self.run_detector("redirect")
        self.assertEqual(
            result,
            f"portal\thttp://127.0.0.1:{self.server.server_port}/login",
        )

    def test_normal_http_and_https_returns_full(self):
        self.assertEqual(self.run_detector("healthy"), "full")

    def test_injected_html_from_two_vendors_is_portal(self):
        self.assertEqual(self.run_detector("inject"), "portal")

    def test_broken_uplink_remains_limited(self):
        self.assertEqual(self.run_detector("broken"), "limited")


if __name__ == "__main__":
    unittest.main()
