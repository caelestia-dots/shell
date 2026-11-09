from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
NETWORK = ROOT / "modules" / "bar" / "popouts" / "Network.qml"

class ShellIntegrationTests(unittest.TestCase):
    def test_signin_action_only_when_captive(self):
        source = NETWORK.read_text()
        self.assertIn('root.checkCaptivePortal && root.captiveState === "portal"', source)
        self.assertIn('root.captiveCheckNetwork !== currentWifiKey', source)
        self.assertIn('Quickshell.shellPath("assets/captive-portal/open")', source)
        self.assertIn('Tr.tr("Sign in to Wi-Fi")', source)

    def test_probe_tracks_access_point_identity(self):
        source = NETWORK.read_text()
        self.assertIn('Nmcli.active.ssid + "|" + Nmcli.active.bssid', source)
        self.assertIn("captiveCheckNetwork !== currentWifiKey", source)

    def test_no_direct_public_test_url_launch(self):
        source = NETWORK.read_text()
        self.assertNotIn('Qt.openUrlExternally', source)
        self.assertNotIn('neverssl.com', source.lower())

    def test_probe_only_runs_with_open_network_flyout(self):
        source = NETWORK.read_text()
        self.assertIn('root.popouts.hasCurrent && root.popouts.currentName === "network"', source)
        self.assertIn('running: root.checkCaptivePortal', source)

    def test_full_internet_polls_less_frequently(self):
        source = NETWORK.read_text()
        self.assertIn('interval: root.captiveState === "full" ? 60000 : 12000', source)

    def test_wifi_signin_available_when_ethernet_is_the_default_view(self):
        source = NETWORK.read_text()
        self.assertIn('root.popouts.hasCurrent && root.popouts.currentName === "network" && Nmcli.active !== null', source)
        self.assertNotIn('root.view === "wireless" && root.popouts.currentName === "network"', source)

    def test_browser_helper_path_is_sibling_of_opener(self):
        opener = (ROOT / "assets" / "captive-portal" / "open").read_text()
        self.assertIn('$(dirname "${BASH_SOURCE[0]}")" && pwd', opener)
        self.assertIn('$portal_root/portal_helper.py', opener)
