#!/usr/bin/env python3
import ipaddress
import json
import os
import select
import subprocess
import sys
from urllib.parse import urlparse


def run(args, timeout=8):
    try:
        return subprocess.run(args, capture_output=True, text=True,
                              timeout=timeout, check=False)
    except (OSError, subprocess.TimeoutExpired):
        return None



def output(args, timeout=8):
    result = run(args, timeout)
    if result is None or result.returncode != 0:
        return ""
    return result.stdout.strip()



def wifi_devices():
    listing = output(["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status"])
    devices = []
    for line in listing.splitlines():
        parts = line.split(":")
        if len(parts) >= 3 and parts[1] == "wifi" and parts[2].startswith("connected"):
            devices.append(parts[0])
    return devices



def wifi_config(device):
    result = output(["ip", "-j", "addr", "show", "dev", device])
    addresses = []
    try:
        for interface in json.loads(result or "[]"):
            for entry in interface.get("addr_info", []):
                if entry.get("family") in ("inet", "inet6"):
                    address = entry.get("local", "")
                    try:
                        ipaddress.ip_address(address)
                        addresses.append(address)
                    except ValueError:
                        pass
    except (ValueError, TypeError):
        pass

    gateways = []
    dns = []
    for field, destination in (("IP4.GATEWAY", gateways), ("IP6.GATEWAY", gateways),
                               ("IP4.DNS", dns), ("IP6.DNS", dns)):
        for entry in output(["nmcli", "-g", field, "device", "show", device]).splitlines():
            address = entry.strip().replace("\\:", ":")
            try:
                ipaddress.ip_address(address.split("%", 1)[0])
            except ValueError:
                continue
            if address not in destination:
                destination.append(address)
    return addresses, gateways, dns


def safe_url(url):
    if not url or len(url) > 4096 or any(ord(c) < 32 for c in url):
        return ""
    try:
        parsed = urlparse(url)
        if parsed.scheme not in ("http", "https") or not parsed.hostname:
            return ""
        if parsed.username or parsed.password:
            return ""
        return url
    except ValueError:
        return ""



def launch_isolated(url, device, dns):
    browser_helper = os.path.join(os.path.dirname(__file__), "portal_browser.py")
    try:
        proc = subprocess.Popen(
            [sys.executable, browser_helper, "--interface", device,
             "--url", url, "--dns", ",".join(dns)],
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL, text=True, start_new_session=True)
        readable, _, _ = select.select([proc.stdout], [], [], 6)
        launched = bool(readable and proc.stdout.readline().strip() == "READY")
        proc.stdout.close()
        if not launched and proc.poll() is None:
            proc.terminate()
        return launched
    except (OSError, ValueError):
        return False


def main():
    if len(sys.argv) != 4 or sys.argv[1] != "browser":
        print("Usage: portal_helper.py browser URL WIFI_DEVICE", file=sys.stderr)
        return 2
    url = safe_url(sys.argv[2])
    device = sys.argv[3]
    if not url or device not in wifi_devices():
        return 2
    addresses, _gateways, dns = wifi_config(device)
    if not addresses:
        return 2
    return 0 if launch_isolated(url, device, dns) else 1


if __name__ == "__main__":
    raise SystemExit(main())
