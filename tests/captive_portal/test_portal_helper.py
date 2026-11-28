import importlib.util
import pathlib
import sys
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    "portal_helper",
    pathlib.Path(__file__).resolve().parents[2] / "assets" / "captive-portal" / "portal_helper.py"
)
portal = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(portal)


class PortalBrowserLaunchTests(unittest.TestCase):
    def test_connected_wifi_only(self):
        with patch.object(portal, "output", return_value=(
            "wlan0:wifi:connected\neth0:ethernet:connected\nwlan1:wifi:disconnected\n"
        )):
            self.assertEqual(portal.wifi_devices(), ["wlan0"])

    def test_uses_wifi_interface_dhcp_configuration(self):
        def output(args, timeout=8):
            if args[:3] == ["ip", "-j", "addr"]:
                return '[{"addr_info":[{"family":"inet","local":"192.168.44.102"}]}]'
            if "IP4.GATEWAY" in args:
                return "192.168.44.1"
            if "IP4.DNS" in args:
                return "192.168.44.1\n1.1.1.1"
            if "IP6." in " ".join(args):
                return ""
            raise AssertionError(args)
        with patch.object(portal, "output", side_effect=output):
            addresses, gateways, dns = portal.wifi_config("wlan0")
        self.assertEqual(addresses, ["192.168.44.102"])
        self.assertEqual(gateways, ["192.168.44.1"])
        self.assertEqual(dns, ["192.168.44.1", "1.1.1.1"])

    def test_ipv6_only_wifi_configuration(self):
        def output(args, timeout=8):
            if args[:3] == ["ip", "-j", "addr"]:
                return '[{"addr_info":[{"family":"inet6","local":"2001:db8::42"},' \
                       '{"family":"inet6","local":"fe80::beef"}]}]'
            if "IP6.GATEWAY" in args:
                return "fe80\\:\\:1"
            if "IP6.DNS" in args:
                return "fe80\\:\\:53"
            return ""
        with patch.object(portal, "output", side_effect=output):
            addresses, gateways, dns = portal.wifi_config("wlan0")
        self.assertEqual(addresses, ["2001:db8::42", "fe80::beef"])
        self.assertEqual(gateways, ["fe80::1"])
        self.assertEqual(dns, ["fe80::53"])

    def test_ipv6_only_wifi_can_launch(self):
        url = "https://[2001:db8::10]/login"
        with patch.object(portal, "wifi_devices", return_value=["wlan0"]), \
             patch.object(portal, "wifi_config", return_value=(
                 ["2001:db8::42"], ["fe80::1"], ["fe80::53"]
             )), \
             patch.object(portal, "launch_isolated", return_value=True) as launch, \
             patch.object(sys, "argv", ["helper", "browser", url, "wlan0"]):
            self.assertEqual(portal.main(), 0)
        launch.assert_called_once_with(url, "wlan0", ["fe80::53"])

    def test_reject_unsafe_urls(self):
        for url in (
            "javascript:alert(1)", "file:///etc/passwd",
            "http://user:pass@example.org/", "https://example.org/\r\nHeader: bad",
            "ftp://example.org/", "", "http://",
        ):
            with self.subTest(url=url):
                self.assertEqual(portal.safe_url(url), "")
        self.assertEqual(portal.safe_url("https://portal.example.org/login?challenge=123"),
                         "https://portal.example.org/login?challenge=123")

    def test_launch_binds_selected_wifi(self):
        with patch.object(portal, "wifi_devices", return_value=["wlan0"]), \
             patch.object(portal, "wifi_config", return_value=(
                 ["192.168.44.102"], ["192.168.44.1"], ["192.168.44.1"]
             )), \
             patch.object(portal, "launch_isolated", return_value=True) as launch, \
             patch.object(sys, "argv", ["helper", "browser", "https://portal.example.org/login", "wlan0"]):
            self.assertEqual(portal.main(), 0)
        launch.assert_called_once_with("https://portal.example.org/login", "wlan0", ["192.168.44.1"])

    def test_reject_unconnected_interface(self):
        with patch.object(portal, "wifi_devices", return_value=["wlan0"]), \
             patch.object(portal, "launch_isolated") as launch, \
             patch.object(sys, "argv", ["helper", "browser", "https://portal.example.org/login", "eth0"]):
            self.assertEqual(portal.main(), 2)
        launch.assert_not_called()

    def test_reject_missing_wifi_addresses(self):
        with patch.object(portal, "wifi_devices", return_value=["wlan0"]), \
             patch.object(portal, "wifi_config", return_value=([], [], [])), \
             patch.object(portal, "launch_isolated") as launch, \
             patch.object(sys, "argv", ["helper", "browser", "https://portal.example.org/login", "wlan0"]):
            self.assertEqual(portal.main(), 2)
        launch.assert_not_called()


if __name__ == "__main__":
    unittest.main()
