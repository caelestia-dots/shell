from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]


class PackagingTests(unittest.TestCase):
    def test_nix_runtime_includes_portal_dependencies(self):
        nix = (ROOT / "nix" / "default.nix").read_text()
        dependencies = nix.split("runtimeDeps =", 1)[1].split("++ extraRuntimeDeps", 1)[0]
        for binary in ("networkmanager", "bash", "curl", "iproute2", "python3"):
            with self.subTest(binary=binary):
                self.assertIn(binary, dependencies)
