import contextlib
import io
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import dgpu_generator as gen

FIXTURES = Path(__file__).resolve().parent / "fixtures"
SOURCE_DIR = FIXTURES / "source"
REGISTRY_DIR = FIXTURES / "registry"
EXPECTED_DIR = FIXTURES / "expected"

OFFLOAD_PREFIX = "env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only"


class DgpuGeneratorTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.apps_dir = self.root / "applications"
        self.source_dir = self.root / "source"
        self.source_dir.mkdir()
        for entry in SOURCE_DIR.glob("*.desktop"):
            shutil.copy(entry, self.source_dir / entry.name)
        self.apps_dir.mkdir()

    def tearDown(self):
        self.tmp.cleanup()

    def run_generator(self, registry_name, *extra_args):
        registry = REGISTRY_DIR / registry_name
        args = [
            "--registry",
            str(registry),
            "--applications-dir",
            str(self.apps_dir),
            "--source-dirs",
            str(self.source_dir),
            *extra_args,
        ]
        stderr = io.StringIO()
        with contextlib.redirect_stderr(stderr):
            code = gen.main(args)
        return code, stderr.getvalue()

    def wrapper(self, entry_id):
        return self.apps_dir / gen.wrapper_filename(entry_id)

    def test_creates_wrapper_with_offload_exec_for_assigned_apps(self):
        code, stderr = self.run_generator("two-apps.json")
        self.assertEqual(code, 0, stderr)
        self.assertEqual(
            self.wrapper("com.visualstudio.code.desktop").read_text(),
            (EXPECTED_DIR / "com.visualstudio.code (dGPU).desktop").read_text(),
        )
        self.assertEqual(
            self.wrapper("com.valvesoftware.Steam.desktop").read_text(),
            (EXPECTED_DIR / "com.valvesoftware.Steam (dGPU).desktop").read_text(),
        )

    def test_wrapper_content_matches_golden(self):
        self.run_generator("one-app.json")
        golden = (EXPECTED_DIR / "com.visualstudio.code (dGPU).desktop").read_text()
        self.assertEqual(
            self.wrapper("com.visualstudio.code.desktop").read_text(), golden
        )
        self.assertIn(f"Exec={OFFLOAD_PREFIX} code %U", golden)
        self.assertIn("Name=Visual Studio Code (dGPU)", golden)
        self.assertIn("X-Caelestia-DGPU-Source=com.visualstudio.code.desktop", golden)

    def test_desktop_actions_left_untouched(self):
        self.run_generator("two-apps.json")
        content = self.wrapper("com.valvesoftware.Steam.desktop").read_text()
        self.assertIn("Name=Store", content)
        self.assertIn("Exec=steam steam://store", content)
        self.assertNotIn("Store (dGPU)", content)

    def test_idempotent_rerun_unchanged(self):
        self.run_generator("two-apps.json")
        before = {p.name: p.read_text() for p in self.apps_dir.iterdir()}
        code, stderr = self.run_generator("two-apps.json")
        self.assertEqual(code, 0, stderr)
        after = {p.name: p.read_text() for p in self.apps_dir.iterdir()}
        self.assertEqual(before, after)

    def test_unassigned_app_wrapper_removed(self):
        self.run_generator("two-apps.json")
        code, stderr = self.run_generator("one-app.json")
        self.assertEqual(code, 0, stderr)
        self.assertTrue(self.wrapper("com.visualstudio.code.desktop").exists())
        self.assertFalse(self.wrapper("com.valvesoftware.Steam.desktop").exists())

    def test_unrelated_entries_untouched(self):
        unrelated = self.apps_dir / "org.gimp.GIMP.desktop"
        unrelated.write_text("[Desktop Entry]\nName=GIMP\nExec=gimp %U\n")
        self.run_generator("two-apps.json")
        self.assertEqual(
            unrelated.read_text(), "[Desktop Entry]\nName=GIMP\nExec=gimp %U\n"
        )

    def test_missing_registry_is_noop(self):
        code, stderr = self.run_generator("does-not-exist.json")
        self.assertEqual(code, 0, stderr)
        self.assertEqual(list(self.apps_dir.iterdir()), [])

    def test_invalid_registry_errors(self):
        code, stderr = self.run_generator("invalid.json")
        self.assertEqual(code, 1)
        self.assertIn("cannot read registry", stderr)

    def test_stale_wrapper_removed_when_source_missing(self):
        stale = self.apps_dir / gen.wrapper_filename("com.visualstudio.code.desktop")
        stale.write_text(
            "[Desktop Entry]\nX-Caelestia-DGPU-Source=com.visualstudio.code.desktop\nName=Code\n"
        )
        self.run_generator("none.json")
        self.assertFalse(stale.exists())

    def test_user_applications_dir_takes_priority(self):
        override = self.apps_dir / "com.visualstudio.code.desktop"
        override.write_text("[Desktop Entry]\nName=Code\nExec=/opt/code/code %U\n")
        self.run_generator("one-app.json")
        content = self.wrapper("com.visualstudio.code.desktop").read_text()
        self.assertIn(f"Exec={OFFLOAD_PREFIX} /opt/code/code %U", content)

    def test_entry_already_env_prefixed_not_double_wrapped(self):
        self.source_dir.joinpath("com.visualstudio.code.desktop").write_text(
            "[Desktop Entry]\nName=Code\nExec=env FOO=1 code %U\n"
        )
        self.run_generator("one-app.json")
        content = self.wrapper("com.visualstudio.code.desktop").read_text()
        self.assertIn(f"Exec={OFFLOAD_PREFIX} FOO=1 code %U", content)
        self.assertEqual(content.count("env "), 1)

    def test_wrapper_filename(self):
        self.assertEqual(
            gen.wrapper_filename("com.visualstudio.code.desktop"),
            "com.visualstudio.code (dGPU).desktop",
        )
        self.assertEqual(gen.wrapper_filename("myapp"), "myapp (dGPU).desktop")

    def test_marker_only_in_main_group_is_owned(self):
        foreign = self.apps_dir / "Other (dGPU).desktop"
        foreign.write_text(
            "[Desktop Entry]\nName=Other\nExec=other\n\n[Desktop Action X]\n"
            "X-Caelestia-DGPU-Source=com.visualstudio.code.desktop\n"
        )
        self.run_generator("none.json")
        self.assertTrue(foreign.exists())

    def test_not_dgpu_assignment_ignored(self):
        registry = self.root / "igpu.json"
        registry.write_text('{"apps": {"com.visualstudio.code.desktop": "iGPU"}}')
        args = [
            "--registry",
            str(registry),
            "--applications-dir",
            str(self.apps_dir),
            "--source-dirs",
            str(self.source_dir),
        ]
        self.assertEqual(gen.main(args), 0)
        self.assertEqual(list(self.apps_dir.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
