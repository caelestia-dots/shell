#!/usr/bin/env python3
"""Run the real launcher components in an isolated, offscreen Quickshell.

Usage: python -B tests/launcher/run_tests.py [candidate]
Requires qs, Qt Quick and Python 3. No browser or desktop service is started.
WEBSEARCH_TEST_OUTPUT selects the log directory (temporary by default).
WEBSEARCH_LEGACY_REPO optionally enables parity against the legacy Git ref.
Use --negative-control with a vulnerable source snapshot to check the witness.
The .qml.in fixture is copied unchanged; its imports resolve against test doubles,
so it must not be discovered as a production QML component by build tooling.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

HERE = Path(__file__).resolve().parent
LEGACY_REF = 'origin/fix/caelestia-2.5-safe-sync:modules/launcher/services/WebSearch.qml'
STALE_URL = 'https://www.reddit.com/search/?q=final'


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def singletons(path, modules):
    write(path / 'qmldir', '\n'.join(
        f'singleton {name} 1.0 {name}.qml' for name in modules) + '\n')
    for name, body in modules.items():
        write(path / (name + '.qml'), 'pragma Singleton\nimport QtQuick\nQtObject {\n' + body + '\n}\n')


def setup(work, repo, legacy, negative, duration):
    config = work / 'config'
    for name in ['AppList.qml', 'Content.qml', 'services/WebSearch.qml']:
        target = config / 'modules/launcher' / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(repo / 'modules/launcher' / name, target)
    shutil.copyfile(HERE / 'LauncherTest.qml.in', config / 'shell.qml')
    singletons(work / 'imports/Caelestia', {
        'CUtils': 'function clamp(value: real, low: real, high: real): real { return Math.max(low, Math.min(value, high)); }'})
    singletons(work / 'imports/Caelestia/I18n', {
        'Tr': 'function tr(text: string): string { return text; }'})
    singletons(work / 'imports/Caelestia/Config', {
        'GlobalConfig': 'property var launcher: ({actionPrefix: ">", specialPrefix: "@", vimKeybinds: false})',
        'Config': 'property var launcher: ({maxShown: 7}); property var border: ({thickness: 1})',
        'Tokens': '''property var spacing: ({small: 4})
            property var sizes: ({launcher: {itemHeight: 30}})
            property var rounding: ({large: 8, extraLarge: 12})
            property var padding: ({large: 12, medium: 8})
            property var anim: ({durations: {small: ''' + str(duration) + '''}, standardAccel: Easing.Linear, standardDecel: Easing.Linear})'''})
    services = config / 'modules/launcher/services'
    singletons(services, {
        'Apps': '''property var matches: ({firefox: [{id: "firefox"}], "@c Network": [{id: "settings"}]})
            property string launched: ""
            property int launches: 0
            property string lastQuery: ""
            function search(text: string): var { lastQuery = text; return matches[text] ?? []; }
            function launch(entry: var): void { launched = entry.id ?? "INVALID"; launches++; }''',
        'Actions': '''property string lastQuery: ""
            function query(text: string): var {
                lastQuery = text;
                return [{name: "command", onClicked: list => { Apps.launch({id: text}); list.screenState.launcher = false; }}];
            }''',
        'Schemes': '''property int reloads: 0
            function query(text: string): var { return [{name: text, onClicked: list => { Apps.launch({id: text}); list.screenState.launcher = false; }}]; }
            function reload(): void { reloads++; }''',
        'M3Variants': '''function query(text: string): var { return [{name: text, onClicked: list => { Apps.launch({id: text}); list.screenState.launcher = false; }}]; }''',
    })
    # WebSearch is copied byte-for-byte and uses its real execDetached callback.
    with (services / 'qmldir').open('a') as stream:
        stream.write('singleton WebSearch 1.0 WebSearch.qml\n')
    if legacy is not None:
        write(services / 'LegacyWebSearch.qml', legacy)
        with (services / 'qmldir').open('a') as stream:
            stream.write('singleton LegacyWebSearch 1.0 LegacyWebSearch.qml\n')
    singletons(config / 'services', {
        'Colours': 'property string scheme: "static"; property var palette: ({m3onSurface: "white"})',
        'Wallpapers': 'property bool previewColourLock: false; property string actualCurrent: ""; property string selected: ""; function setWallpaper(path: string): void { selected = path; }',
    })
    write(config / 'services/ScreenState.qml', 'import QtQuick\nQtObject { property bool launcher: true; property bool session: false }\n')
    with (config / 'services/qmldir').open('a') as stream:
        stream.write('ScreenState 1.0 ScreenState.qml\n')
    write(config / 'components/controls/SearchBar.qml', 'import QtQuick.Controls\nTextField {}\n')
    write(config / 'components/StyledRect.qml', 'import QtQuick\nRectangle {}\n')
    write(config / 'components/Anim.qml', '''import QtQuick
NumberAnimation {
    enum Kind { DefaultEffects, StandardSmall }
    property int type: 0
    duration: 10
}
''')
    write(config / 'components/containers/StyledListView.qml', 'import QtQuick\nListView {}\n')
    write(config / 'components/controls/StyledScrollBar.qml', 'import QtQuick.Controls\nScrollBar { property var flickable }\n')
    for name, fields in [('AppItem', 'required property var screenState'),
                         ('ActionItem', 'required property var list'),
                         ('CalcItem', '''required property var list
    function onClicked(): void { Apps.launch({id: list.search.text}); list.screenState.launcher = false; }'''),
                         ('SchemeItem', 'required property var list'),
                         ('VariantItem', 'required property var list')]:
        write(config / 'modules/launcher/items' / (name + '.qml'), '''import QtQuick
import qs.modules.launcher.services
Item {
    required property var modelData
    ''' + fields + '''
    objectName: "''' + name + '''"
    width: 280
    height: 30
    implicitHeight: 30
}
''')
    # Layout/picker doubles expose the real AppList to the real Content handler.
    write(config / 'modules/launcher/ContentList.qml', '''import QtQuick
import Caelestia.Config
import qs.components.controls
import qs.services
Item {
    required property var content
    required property ScreenState screenState
    required property var panels
    required property real maxHeight
    required property SearchBar search
    required property int padding
    required property int rounding
    readonly property bool showWallpapers: search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}wallpaper `)
    readonly property var currentList: showWallpapers ? wallpaperList : app
    objectName: "testContentList"
    width: 280
    height: 200
    AppList { id: app; objectName: "testAppList"; width: 280; height: 200; search: parent.search; screenState: parent.screenState }
    QtObject { id: wallpaperList; property var currentItem: ({modelData: {path: "/fixture/wallpaper.png"}}) }
}
''')
    binary = work / 'bin'
    write(binary / 'xdg-open', '''#!/usr/bin/env python3
import json
import os
import sys
with open(os.environ['WEBSEARCH_URL_LOG'], 'a') as stream:
    stream.write(json.dumps(sys.argv[1:]) + '\\n')
''')
    (binary / 'xdg-open').chmod(0o755)
    (work / 'runtime').mkdir(mode=0o700)
    env = {k: v for k, v in os.environ.items() if k not in (
        'DISPLAY', 'WAYLAND_DISPLAY', 'HYPRLAND_INSTANCE_SIGNATURE', 'DBUS_SESSION_BUS_ADDRESS',
        'QML_IMPORT_PATH', 'QML2_IMPORT_PATH', 'QT_PLUGIN_PATH', 'QS_CONFIG_PATH')}
    env.update({
        'HOME': str(work / 'home'), 'XDG_CONFIG_HOME': str(work / 'xdg'),
        'XDG_CONFIG_DIRS': str(work / 'xdg-dirs'), 'XDG_STATE_HOME': str(work / 'state'),
        'XDG_DATA_HOME': str(work / 'data'), 'XDG_DATA_DIRS': str(work / 'data-dirs'),
        'XDG_CACHE_HOME': str(work / 'cache'), 'XDG_RUNTIME_DIR': str(work / 'runtime'),
        'QT_QPA_PLATFORM': 'offscreen', 'QT_QUICK_BACKEND': 'software',
        'QSG_RHI_BACKEND': 'software', 'QML_IMPORT_PATH': str(work / 'imports'),
        'PATH': str(binary) + ':' + os.environ['PATH'], 'WEBSEARCH_URL_LOG': str(work / 'urls'),
        'DBUS_SESSION_BUS_ADDRESS': 'unix:path=' + str(work / 'no-session-bus'),
        'WEBSEARCH_PARITY': '1' if legacy is not None else '',
        'WEBSEARCH_NEGATIVE_CONTROL': '1' if negative else '',
    })
    return config, env


def read_urls(work):
    path = work / 'urls'
    return [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('repo', nargs='?', type=Path, default=HERE.parents[1])
    parser.add_argument('--negative-control', action='store_true')
    parser.add_argument('--transition-duration', type=int, default=30, choices=range(1, 501), metavar='1..500')
    args = parser.parse_args()
    legacy_repo = os.environ.get('WEBSEARCH_LEGACY_REPO')
    legacy = subprocess.run(['git', '-C', legacy_repo, 'show', LEGACY_REF],
                            text=True, capture_output=True, check=True).stdout if legacy_repo else None
    out = Path(os.environ.get('WEBSEARCH_TEST_OUTPUT') or tempfile.mkdtemp(prefix='websearch-results-'))
    out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='websearch-launcher-') as temp:
        work = Path(temp)
        config, env = setup(work, args.repo.resolve(), legacy, args.negative_control, args.transition_duration)
        proc = subprocess.run(['qs', '--path', str(config), '--no-color'], env=env,
                              text=True, capture_output=True, timeout=60)
        log = proc.stdout + proc.stderr
        (out / 'launcher.log').write_text(log)
        line = next((line.split('TEST_RESULT ', 1)[1] for line in log.splitlines() if 'TEST_RESULT ' in line), None)
        if proc.returncode or line is None or any(word in log for word in ['TypeError:', 'ReferenceError:', 'WARN', 'Built against Qt']):
            raise AssertionError(log)
        result = json.loads(line)
        negative = args.negative_control and result['failure'] == 'stale Reddit result activated for firefox'
        unexpected_errors = [line for line in log.splitlines() if 'ERROR' in line
                             and not (negative and 'TEST_FAIL stale Reddit result activated for firefox' in line)]
        if (result['failures'] and not negative) or (args.negative_control and not negative) or unexpected_errors:
            raise AssertionError(log)
        expected = [[url] for url in result.pop('expectedUrls')]
        if negative:
            expected = [[STALE_URL]]
        # Detached openers complete asynchronously; observe their output, never sleep a guessed duration.
        deadline = time.monotonic() + 5
        while sorted(read_urls(work)) != sorted(expected) and time.monotonic() < deadline:
            time.sleep(0.01)
        urls = read_urls(work)
        if sorted(urls) != sorted(expected):
            raise AssertionError((expected, urls, log))
        result.update(opener_calls=len(urls), negative_control=negative, legacy_parity=legacy is not None)
        (out / 'results.json').write_text(json.dumps(result, indent=2) + '\n')
        (out / 'urls.json').write_text(json.dumps(urls, indent=2) + '\n')
        print(json.dumps(result))
        print('Logs:', out)


if __name__ == '__main__':
    main()
