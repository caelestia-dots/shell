import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2] / "assets" / "captive-portal"
DETECT = ROOT / "check"
FAKE_NMCLI = r'''#!/bin/sh
case "$*" in
    "-t -f DEVICE,TYPE,STATE device status") echo "wlan0:wifi:connected";;
    "-g GENERAL.CONNECTION device show wlan0") echo "Test Hotspot";;
    "-f DHCP4.OPTION,DHCP6.OPTION device show wlan0") if [ "$SIMULATED_CAPTIVE_MODE" = "ipv6_capport" ] || [ "$SIMULATED_CAPTIVE_MODE" = "capport_bad_url" ] || [ "$SIMULATED_CAPTIVE_MODE" = "capport_false" ]; then echo 'DHCP6.OPTION[1]: captive_portal = https://[fd00::10]/capport'; fi;;
    "networking connectivity") echo "${SIMULATED_CAPTIVE_NM_STATE:-limited}";;
esac
'''
FAKE_IP = r'''#!/bin/sh
case "$*" in
  "-o -4 addr show dev wlan0") if [ "$SIMULATED_IPV6_ONLY" != "1" ]; then echo "wlan0 inet 192.0.2.42/24"; fi;;
  "-o -6 addr show dev wlan0") echo "wlan0 inet6 fe80::42/64";;
esac
'''


FAKE_CURL = r'''#!/usr/bin/env python3
import os, sys
from pathlib import Path
args = sys.argv[1:]
if "--interface" in args:
    with open(os.environ["SIMULATED_INTERFACE_LOG"], "a") as log:
        log.write(args[args.index("--interface") + 1] + "\n")
if "-6" in args:
    with open(os.environ["SIMULATED_IPV6_FLAG_LOG"], "a") as log:
        log.write("ipv6\n")
mode = os.environ["SIMULATED_CAPTIVE_MODE"]
url = args[-1]
def outarg(name):
    return args[args.index(name)+1] if name in args else None
code = 0
body = b""
location = ""
if mode != "offline":
    if "cloudflare.com/cdn-cgi/trace" in url:
        code = 200 if mode == "healthy" else 0
    elif "generate_204" in url or "/status/204" in url:
        code = 204
    else:
        code = 200
        if "firefox.com/success.txt" in url:
            body = b"success"
        elif "apple.com/hotspot" in url:
            body = b"<html>Success</html>"
        elif "archlinux.org" in url:
            body = b"NetworkManager is online"
        elif "msftconnecttest.com" in url:
            body = b"Microsoft Connect Test"
    if mode in ("redirect", "mixed") and "detectportal.firefox.com" in url:
        code, body, location = 302, b"", "http://127.0.0.1:8081/login"
    if mode == "injected" and ("detectportal.firefox.com" in url or "captive.apple.com" in url):
        code, body = 200, b"<html>Sign in to hotspot</html>"
    if mode == "ipv6_redirect" and "detectportal.firefox.com" in url:
        code, body, location = 302, b"", "http://[fd00::9]/login"
    if "[fd00::10]" in url:
        if mode == "ipv6_capport":
            code, body = 200, b'{"captive":true,"user-portal-url":"http://[fd00::11]/login"}'
        elif mode == "capport_bad_url":
            code, body = 200, b'{"captive":true,"user-portal-url":"javascript:alert(1)"}'
        elif mode == "capport_false":
            code, body = 200, b'{"captive":false,"user-portal-url":"http://[fd00::11]/login"}'
header = f"HTTP/1.1 {code} Reply\r\n"
if location:
    header += f"Location: {location}\r\n"
header += "\r\n"
if (name := outarg("-D")) is not None:
    Path(name).write_bytes(header.encode())
if (name := outarg("-o")) is not None and name != "/dev/null":
    Path(name).write_bytes(body)
if "-w" in args:
    sys.stdout.write(str(code if code else "000"))
'''


class DetectorIntegrationTests(unittest.TestCase):
    def run_detector(self, mode, nm_state="limited", ipv6_only=False):
        with tempfile.TemporaryDirectory(prefix="captive-detector-test-") as directory:
            temp = Path(directory)
            for name, body in (("nmcli", FAKE_NMCLI), ("curl", FAKE_CURL), ("ip", FAKE_IP)):
                path = temp / name
                path.write_text(body)
                path.chmod(path.stat().st_mode | stat.S_IXUSR)
            env = {**os.environ, "PATH": f"{directory}:{os.environ.get('PATH', '')}",
                   "SIMULATED_CAPTIVE_MODE": mode, "SIMULATED_CAPTIVE_NM_STATE": nm_state, "TMPDIR": directory,
                   "SIMULATED_IPV6_ONLY": "1" if ipv6_only else "0",
                   "SIMULATED_IPV6_FLAG_LOG": str(temp / "ipv6.log"),
                   "SIMULATED_INTERFACE_LOG": str(temp / "interface.log")}
            result = subprocess.run(["bash", str(DETECT)], env=env, capture_output=True, text=True, timeout=15)
            self.assertEqual(result.returncode, 0, result.stderr)
            interfaces = (temp / "interface.log").read_text().splitlines()
            self.assertTrue(interfaces)
            self.assertTrue(all(item == "if!wlan0" for item in interfaces), interfaces)
            if ipv6_only:
                self.assertTrue((temp / "ipv6.log").exists(), "Expected curl -6 on IPv6-only Wi-Fi")
            else:
                self.assertFalse((temp / "ipv6.log").exists(), "Unexpected curl -6 on dual-stack Wi-Fi")
            return result.stdout.strip()

    def test_captive_redirect_from_one_vendor_wins(self):
        self.assertEqual(self.run_detector("mixed"), "portal\thttp://127.0.0.1:8081/login")

    def test_open_internet_is_full(self):
        self.assertEqual(self.run_detector("healthy"), "full")

    def test_ipv6_only_captive_redirect_url(self):
        self.assertEqual(self.run_detector("ipv6_redirect", ipv6_only=True), "portal\thttp://[fd00::9]/login")

    def test_ipv6_dhcp6_capport_advertisement(self):
        self.assertEqual(self.run_detector("ipv6_capport", ipv6_only=True), "portal\thttp://[fd00::11]/login")

    def test_capport_ignores_unsafe_login_url(self):
        self.assertEqual(self.run_detector("capport_bad_url"), "limited")

    def test_capport_does_not_open_non_captive_api(self):
        self.assertEqual(self.run_detector("capport_false"), "limited")

    def test_injected_login_html_is_portal(self):
        self.assertEqual(self.run_detector("injected"), "portal")

    def test_offline_is_not_invented_as_captive(self):
        self.assertEqual(self.run_detector("offline"), "limited")

    def test_http_only_is_not_auto_portal(self):
        self.assertEqual(self.run_detector("http_only"), "limited")

    def test_networkmanager_explicit_portal_is_respected(self):
        self.assertEqual(self.run_detector("offline", nm_state="portal"), "portal")


if __name__ == "__main__":
    unittest.main()
