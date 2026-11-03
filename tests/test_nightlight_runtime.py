"""Isolated Quickshell/Hyprsunset IPC regression tests; no host display mutations."""

import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


SOURCE = Path(__file__).resolve().parents[1] / "services"


def run_case(case: str) -> None:
    with tempfile.TemporaryDirectory(prefix="caelestia-nightlight-") as directory:
        root = Path(directory)
        bin_dir = root / "bin"
        bin_dir.mkdir()
        (root / "state").write_text("off" if case == "enable-change" else "on")
        service = (SOURCE / "NightLight.qml").read_text()
        service = service.replace("pragma Singleton\n", "")
        service = service.replace("import Caelestia.Config\n", "")
        service = service.replace("Singleton {", "Item {", 1)
        service = service.replace("    id: root\n", "    id: root\n    property int testTemperature: 4500\n", 1)
        service = service.replace("GlobalConfig.services.nightLightTemperature", "testTemperature")
        (root / "NightLightPreview.qml").write_text(service)
        shutil.copyfile(SOURCE / "HyprsunsetVersion.js", root / "HyprsunsetVersion.js")
        (bin_dir / "hyprsunset").write_text(
            '#!/bin/sh\nif [ "$1" = "--version" ]; then echo "hyprsunset v0.4.0"; exit 0; fi\nexit 1\n'
        )
        (bin_dir / "hyprctl").write_text("""#!/usr/bin/env python3
import os
from pathlib import Path
import sys
import time

root = Path(os.environ["MOCK_NIGHTLIGHT_DIR"])
args = sys.argv[1:]
with (root / "calls").open("a") as output:
    output.write(" ".join(args) + "\\n")
if args == ["hyprsunset", "identity", "get"]:
    path = root / "queries"
    count = int(path.read_text() if path.exists() else "0") + 1
    path.write_text(str(count))
    if os.environ["MOCK_NIGHTLIGHT_CASE"] == "disconnect" and count > 1:
        sys.exit(1)
    if os.environ["MOCK_NIGHTLIGHT_CASE"] == "invalid" and count > 1:
        print("unknown command")
    else:
        print("false" if (root / "state").read_text() == "on" else "true")
elif args[:2] == ["hyprsunset", "temperature"]:
    if os.environ["MOCK_NIGHTLIGHT_CASE"] in ("race", "rapid", "enable-change"):
        time.sleep(0.35)
    (root / "state").write_text("on")
elif args == ["hyprsunset", "identity"]:
    (root / "state").write_text("off")
else:
    sys.exit(1)
""")
        for cmd in bin_dir.iterdir():
            cmd.chmod(0o755)
        (root / "shell.qml").write_text(f"""import QtQuick
import Quickshell

ShellRoot {{
    NightLightPreview {{ id: night }}

    Timer {{
        running: true
        interval: 350
        onTriggered: {{
            if (["disconnect", "invalid"].includes("{case}"))
                night.refresh();
            else if ("{case}" === "rapid")
                night.testTemperature = 5100;
            else
                night.testTemperature = 5200;
        }}
    }}
    Timer {{
        running: ["race", "enable-change"].includes("{case}")
        interval: "{case}" === "enable-change" ? 230 : 540
        onTriggered: night.toggle()
    }}
    Timer {{
        running: "{case}" === "rapid"
        interval: 535
        onTriggered: night.testTemperature = 5200
    }}
    Timer {{
        running: true
        interval: 1450
        onTriggered: {{
            console.log("VERIFY_RESULT:" + JSON.stringify({{
                active: night.active, pending: night.pending, available: night.available
            }}));
            Qt.quit();
        }}
    }}
}}
""")
        env = dict(os.environ)
        env.update({
            "PATH": str(bin_dir) + os.pathsep + env.get("PATH", ""),
            "QT_QPA_PLATFORM": "offscreen",
            "MOCK_NIGHTLIGHT_DIR": str(root),
            "MOCK_NIGHTLIGHT_CASE": case,
        })
        qs = shutil.which("quickshell") or shutil.which("qs")
        if qs is None:
            raise RuntimeError("Quickshell is required for the runtime test")
        run = subprocess.run(
            [qs, "--path", str(root / "shell.qml"), "--no-color"],
            env=env, text=True, capture_output=True, timeout=12,
        )
        match = re.search(r"VERIFY_RESULT:(\{[^\n]+\})", run.stdout + run.stderr)
        if not match or run.returncode != 0:
            raise AssertionError(f"{case}: no successful result\n{run.stdout}\n{run.stderr}")
        result = json.loads(match.group(1))
        calls = (root / "calls").read_text().splitlines()
        assert result["available"] and not result["pending"], (case, result, calls)
        if case == "temperature":
            assert result["active"] and (root / "state").read_text() == "on", (result, calls)
            assert calls.count("hyprsunset temperature 5200") == 1, calls
        elif case in ("disconnect", "invalid"):
            assert not result["active"], (result, calls)
            assert calls.count("hyprsunset identity get") >= 2, calls
        elif case in ("rapid", "enable-change"):
            assert result["active"] and (root / "state").read_text() == "on", (result, calls)
            assert calls.count("hyprsunset temperature 5200") == 1, calls
            if case == "rapid":
                assert calls.index("hyprsunset temperature 5100") < calls.index("hyprsunset temperature 5200"), calls
            else:
                assert "hyprsunset temperature 4500" in calls, calls
        elif case == "race":
            assert not result["active"] and (root / "state").read_text() == "off", (result, calls)
            assert "hyprsunset temperature 5200" in calls, calls
            assert calls.index("hyprsunset temperature 5200") < calls.index("hyprsunset identity"), calls
        print(f"{case}: PASS ({len(calls)} mocked IPC commands)")


if __name__ == "__main__":
    for scenario in ("temperature", "disconnect", "invalid", "race", "rapid", "enable-change"):
        run_case(scenario)
