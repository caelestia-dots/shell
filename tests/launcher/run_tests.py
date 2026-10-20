#!/usr/bin/env python3
"""Isolated tests adapted from WebSearch's safe-sync launcher harness.

Run: python -B run_tests.py /path/to/candidate
Requires qs/Qt Quick. Provider parity reads the legacy service from
WEBSEARCH_LEGACY_REPO (default: candidate's sibling 'websearch') at
origin/fix/caelestia-2.5-safe-sync. WEBSEARCH_TEST_OUTPUT selects the log folder.
No real desktop services, browser, session bus or full shell is started.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

REPO = Path(sys.argv[1]).resolve()
OUT = Path(os.environ.get('WEBSEARCH_TEST_OUTPUT') or tempfile.mkdtemp(prefix='websearch-test-results-'))
OUT.mkdir(parents=True, exist_ok=True)


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def singleton_module(path, uri, modules):
    write(path / 'qmldir', 'module ' + uri + '\n' + '\n'.join(
        f'singleton {name} 1.0 {name}.qml' for name in modules) + '\n')
    for name, body in modules.items():
        write(path / (name + '.qml'), 'pragma Singleton\nimport QtQuick\nQtObject {\n' + body + '\n}\n')


def setup(work):
    config = work / 'config'
    services = config / 'modules/launcher/services'
    write(services / 'WebSearch.qml', (REPO / 'modules/launcher/services/WebSearch.qml').read_text())
    singleton_module(work / 'imports/Caelestia/I18n', 'Caelestia.I18n', {
        'Tr': 'function tr(text: string): string { return text; }'})
    singleton_module(work / 'imports/Caelestia/Config', 'Caelestia.Config', {
        'GlobalConfig': 'property var launcher: ({actionPrefix: ">", specialPrefix: "@"})',
        'Config': 'property var launcher: ({maxShown: 7})',
        'Tokens': '''property var spacing: ({small: 4})
            property var sizes: ({launcher: {itemHeight: 30}})
            property var rounding: ({large: 8})
            property var anim: ({durations: {small: 10}, standardAccel: Easing.Linear, standardDecel: Easing.Linear})'''})
    singleton_module(config / 'stubs', 'TestStubs', {
        'Apps': '''property var matches: ({firefox: [{id: "firefox"}], "@c Network": [{id: "settings"}]})
            property string launched: ""
            property string lastQuery: ""
            function search(text: string): var { lastQuery = text; return matches[text] ?? []; }
            function launch(entry: var): void { launched = entry.id ?? "INVALID"; }''',
        'Actions': '''property string lastQuery: ""
            function query(text: string): var { lastQuery = text; return [{name: "command"}]; }''',
        'Schemes': '''property int reloads: 0
            function query(text: string): var { return [{name: text}]; }
            function reload(): void { reloads++; }''',
        'M3Variants': 'function query(text: string): var { return [{name: text}]; }',
        'Colours': 'property string scheme: "static"; property bool previewColourLock: false; property var palette: ({m3onSurface: "white"})',
        'Wallpapers': 'property bool previewColourLock: false; property string actualCurrent: ""; property string selected: ""; function setWallpaper(path: string): void { selected = path; }',
    })
    binary = work / 'bin'
    write(binary / 'xdg-open', '#!/usr/bin/env python3\nimport os,json\nwith open(os.environ["WEBSEARCH_URL_LOG"],"a") as f: f.write(json.dumps(__import__("sys").argv[1:])+"\\n")\n')
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
    })
    return config, env


FUNCTION_TEST = r'''
    property var screenState: ({launcher: true})
    property var list: ({currentList: {currentItem: null, screenState: screenState, selectedItem() { return this.currentItem; }}, showWallpapers: false})
    property string text: ""
    property int commands: 0
    property int calculations: 0
    Component.onCompleted: {
        const cases = [
            ["google théorie de la relativité", "Google", "https://www.google.com/search?q=th%C3%A9orie%20de%20la%20relativit%C3%A9"],
            ["  YouTube   lofi\t hip hop  ", "YouTube", "https://www.youtube.com/results?search_query=lofi%20hip%20hop"],
            ["wiki Alan Turing", "Wikipedia", "https://fr.wikipedia.org/wiki/Special:Search?search=Alan%20Turing"],
            ["gh caelestia", "GitHub", "https://github.com/search?q=caelestia"],
            ["github C++ \"hello world\"", "GitHub", "https://github.com/search?q=C%2B%2B%20%22hello%20world%22"],
            ["reddit linux gaming", "Reddit", "https://www.reddit.com/search/?q=linux%20gaming"],
            ["maps café / 🐧", "Google Maps", "https://www.google.com/maps/search/caf%C3%A9%20%2F%20%F0%9F%90%A7"],
            ["google a&b=#?%/", "Google", "https://www.google.com/search?q=a%26b%3D%23%3F%25%2F"],
            ["google $(touch SHOULD_NOT_EXIST); `id`", "Google", "https://www.google.com/search?q=%24(touch%20SHOULD_NOT_EXIST)%3B%20%60id%60"],
            ["GOOGLE å\n日", "Google", "https://www.google.com/search?q=%C3%A5%20%E6%97%A5"],
        ];
        for (const [query, provider, url] of cases) {
            const result = WebSearch.parse(query);
            check(result?.desc === provider, "provider " + query);
            check(result?.url === url, "encoded URL " + query);
            check(result?.name.startsWith('Search for "'), "English translatable label");
            check(stateForText(query) === "web", "explicit provider state");
            screenState.launcher = true;
            text = query;
            list.currentList.currentItem = {modelData: resultsForText(query)[0]};
            accept();
            check(!screenState.launcher, "Enter closes web launcher");
            check(Apps.launched === "", "web never calls Apps.launch");
        }
        for (const query of ["", "   ", "google", "google  ", "yt lofi", "__proto__ test", "constructor test"])
            check(WebSearch.parse(query) === null, "no explicit provider " + query);
        check(WebSearch.fallback(" \n ") === null, "no blank fallback");
        check(WebSearch.fallback("  a   b ").url === "https://www.google.com/search?q=a%20b", "fallback normalization");
        check(WebSearch.parse("google café%20").url.endsWith("caf%C3%A9%2520"), "literal percent encoded once");
        check(stateForText("firefox") === "apps", "app before fallback");
        check(stateForText("@c Network") === "apps", "special app query");
        check(Apps.lastQuery === "@c Network", "app query passed untouched");
        check(stateForText("   ") === "apps", "blank app list");
        check(stateForText("no match") === "web", "Google fallback");
        Apps.matches = {"firefox": [{id: "firefox"}], "google overlap": [{id: "overlap"}]};
        check(stateForText("google overlap") === "web", "explicit provider before matching app");
        for (const query of [">google test", ">unknown", ">wallpaper test"])
            check(stateForText(query) === "actions", "command priority " + query);
        check(stateForText(">calc 1+1") === "calc", "calculator priority");
        check(stateForText(">scheme dark") === "scheme", "scheme priority");
        check(stateForText(">variant tonal") === "variant", "variant priority");
        check(resultsForText(">calc 1+1")[0] === 0, "calculator result unchanged");
        check(resultsForText(">scheme dark")[0].name === ">scheme dark", "scheme query untouched");
        check(resultsForText(">variant tonal")[0].name === ">variant tonal", "variant query untouched");
        check(resultsForText(">google test")[0].name === "command", "native actions result");
        check(Actions.lastQuery === ">google test", "actions query untouched");
        GlobalConfig.launcher = {actionPrefix: ":", specialPrefix: "@"};
        check(stateForText(":google test") === "actions", "custom action prefix");
        check(stateForText(":calc 1+1") === "calc", "custom calculator prefix");
        GlobalConfig.launcher = {actionPrefix: ">", specialPrefix: "@"};
        text = ">custom hello world";
        list.currentList.currentItem = {modelData: {onClicked: () => { commands++; }}};
        accept();
        check(commands === 1, "native action Enter once");
        text = ">calc 1+1";
        list.currentList.currentItem = {onClicked: () => { calculations++; }};
        accept();
        check(calculations === 1, "calculator Enter once");
        text = "firefox";
        screenState.launcher = true;
        list.currentList.currentItem = {modelData: resultsForText(text)[0]};
        accept();
        check(Apps.launched === "firefox", "app Enter dispatch unchanged");
        check(!screenState.launcher, "app Enter closes launcher");
        text = "fallback test";
        screenState.launcher = true;
        list.currentList.currentItem = {modelData: resultsForText(text)[0]};
        accept();
        check(!screenState.launcher, "fallback Enter closes launcher");
        screenState.launcher = true;
        WebSearch.parse("youtube mouse").onClicked(list.currentList);
        check(!screenState.launcher, "mouse callback closes launcher");
        list.showWallpapers = true;
        list.currentList.currentItem = {modelData: {path: "/fixture/wallpaper.png"}};
        Colours.scheme = "dynamic";
        accept();
        check(Wallpapers.selected === "/fixture/wallpaper.png", "wallpaper dispatch preserved");
        check(Wallpapers.previewColourLock, "wallpaper preview lock preserved");
        list.currentList.currentItem = null;
        accept();
        check(Apps.launched === "firefox", "empty selection does not launch");
        finish.start();
    }
    Timer { id: finish; interval: 300; onTriggered: root.done(); }
'''


def run(config, env, body, label, work, expected_urls=None):
    header = '''import Quickshell
import QtQuick
import Caelestia.Config
import qs.modules.launcher.services
import "stubs"
ShellRoot {
    id: root
    property int assertions: 0
    property int failures: 0
    function check(ok: bool, why: string): void {
        assertions++;
        if (!ok) { failures++; console.error("TEST_FAIL " + why); }
    }
    function done(): void {
        console.log("TEST_RESULT " + JSON.stringify({assertions, failures}));
        Qt.quit();
    }
'''
    if label == 'component':
        header = header.replace('ShellRoot {', 'import QtQuick.Window\nimport qs.components\nimport qs.services\nimport qs.modules.launcher\nShellRoot {')
    write(config / 'shell.qml', header + body + '\n}\n')
    proc = subprocess.run(['qs', '--path', str(config), '--no-color'], env=env,
                          text=True, capture_output=True, timeout=15)
    log = proc.stdout + proc.stderr
    (OUT / (label + '.log')).write_text(log)
    line = next((x.split('TEST_RESULT ', 1)[1] for x in log.splitlines() if 'TEST_RESULT ' in x), None)
    if proc.returncode or line is None or 'TEST_FAIL' in log or any(
            text in log for text in ['TypeError:', 'ReferenceError:', 'ERROR', 'WARN', 'Built against Qt']):
        raise AssertionError(label + '\n' + log)
    result = json.loads(line)
    assert not result['failures'], result
    urls = [json.loads(line) for line in (work / 'urls').read_text().splitlines()] if (work / 'urls').exists() else []
    if expected_urls is not None:
        assert sorted(urls) == sorted([[url] for url in expected_urls]), urls
    result.update(label=label, opener_calls=len(urls), exit_code=proc.returncode)
    print(json.dumps(result))
    return result


def test_functions():
    app = (REPO / 'modules/launcher/AppList.qml').read_text()
    content = (REPO / 'modules/launcher/Content.qml').read_text()
    functions = app[app.index('    function stateForText('):app.index('    model: ScriptModel {')]
    handler = content.split('        onAccepted: {\n', 1)[1].split('\n        Keys.onUpPressed:', 1)[0].rsplit('        }', 1)[0]
    urls = [
        'https://www.google.com/search?q=th%C3%A9orie%20de%20la%20relativit%C3%A9',
        'https://www.youtube.com/results?search_query=lofi%20hip%20hop',
        'https://fr.wikipedia.org/wiki/Special:Search?search=Alan%20Turing',
        'https://github.com/search?q=caelestia',
        'https://github.com/search?q=C%2B%2B%20%22hello%20world%22',
        'https://www.reddit.com/search/?q=linux%20gaming',
        'https://www.google.com/maps/search/caf%C3%A9%20%2F%20%F0%9F%90%A7',
        'https://www.google.com/search?q=a%26b%3D%23%3F%25%2F',
        'https://www.google.com/search?q=%24(touch%20SHOULD_NOT_EXIST)%3B%20%60id%60',
        'https://www.google.com/search?q=%C3%A5%20%E6%97%A5',
        'https://www.google.com/search?q=fallback%20test',
        'https://www.youtube.com/results?search_query=mouse',
    ]
    with tempfile.TemporaryDirectory(prefix='caelestia-websearch-functions-') as temp:
        work = Path(temp)
        config, env = setup(work)
        return run(config, env, functions + '\n    function accept(): void {\n' + handler + '\n}\n' + FUNCTION_TEST,
                   'functions', work, urls)


def test_component():
    with tempfile.TemporaryDirectory(prefix='caelestia-websearch-listview-') as temp:
        work = Path(temp)
        config, env = setup(work)
        write(config / 'modules/launcher/AppList.qml', (REPO / 'modules/launcher/AppList.qml').read_text())
        for name in ['Apps', 'Actions', 'Schemes', 'M3Variants']:
            write(config / 'modules/launcher/services' / (name + '.qml'), (config / 'stubs' / (name + '.qml')).read_text())
        for name in ['Colours', 'Wallpapers']:
            write(config / 'services' / (name + '.qml'), (config / 'stubs' / (name + '.qml')).read_text())
        write(config / 'services/ScreenState.qml', 'import QtQuick\nQtObject { property bool launcher: true }\n')
        write(config / 'components/SearchBar.qml', 'import QtQuick\nTextInput {}\n')
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
                             ('CalcItem', 'required property var list'),
                             ('SchemeItem', 'required property var list'),
                             ('VariantItem', 'required property var list')]:
            write(config / 'modules/launcher/items' / (name + '.qml'), '''import QtQuick
Item {
    required property var modelData
    ''' + fields + '''
    objectName: "''' + name + '''"
    width: 280
    height: 30
    implicitHeight: 30
}
''')
        body = '''
    property int step: 0
    property var cases: [
        ["", "apps", "", 0],
        ["firefox", "apps", "AppItem", 1],
        ["google linux", "web", "ActionItem", 1],
        ["youtube cats", "web", "ActionItem", 1],
        [">calc 1+1", "calc", "CalcItem", 1],
        [">scheme dark", "scheme", "SchemeItem", 1],
        [">variant tonal", "variant", "VariantItem", 1],
        [">google linux", "actions", "ActionItem", 1],
        ["no app matches", "web", "ActionItem", 1],
        ["@c Network", "apps", "AppItem", 1],
        ["firefox", "apps", "AppItem", 1]
    ]
    property bool verifying: false
    QtObject { id: control }
    component Host: Window {
        visible: true
        width: 300
        height: 250
        SearchBar { id: search; objectName: "search" }
        ScreenState { id: session }
        AppList { id: app; width: 280; height: 200; search: search; screenState: session }
        property alias entry: app
        property alias input: search
        property alias session: session
    }
    Host { id: host }
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (root.step >= root.cases.length) {
                check(host.entry.currentItem.modelData.id === "firefox", "final app modelData intact");
                host.session.launcher = false;
                host.input.text = "google hidden";
                check(host.entry.displayText === "firefox", "closed list retains displayed app");
                check(host.entry.state === "apps", "closed state preserved");
                host.session.launcher = true;
                stop();
                hiddenCheck.start();
                return;
            }
            const [query, expected, itemType, count] = root.cases[root.step];
            if (!root.verifying) {
                host.input.text = query;
                root.verifying = true;
                return;
            }
            check(host.entry.requestedState === expected, "requested state " + query);
            check(host.entry.displayState === expected, "display state after transition " + query);
            check(host.entry.displayText === query, "display text " + query);
            check(host.entry.count === count, "ScriptModel count " + query);
            if (itemType) {
                check(host.entry.currentItem?.objectName === itemType, "delegate after transition " + query);
                check(host.entry.currentIndex === 0, "selection resets after model change");
            }
            root.verifying = false;
            root.step++;
        }
    }
    Timer {
        id: hiddenCheck
        interval: 100
        onTriggered: {
            check(host.entry.displayState === "web", "reopened state transitions to web");
            check(host.entry.currentItem?.objectName === "ActionItem", "reopened web delegate");
            check(host.entry.currentItem?.modelData?.url === "https://www.google.com/search?q=hidden", "reopened current model URL");
            host.input.text = "firefox";
            host.input.text = "youtube first";
            host.input.text = ">calc 2+2";
            host.input.text = ">scheme light";
            host.input.text = "reddit final";
            rapidCheck.start();
        }
    }
    Timer {
        id: rapidCheck
        interval: 100
        onTriggered: {
            check(host.entry.displayText === "reddit final", "rapid state changes retain final text");
            check(host.entry.currentItem?.objectName === "ActionItem", "rapid state changes retain correct delegate");
            check(host.entry.currentItem?.modelData?.url === "https://www.reddit.com/search/?q=final", "rapid state changes retain final URL");
            root.done();
        }
    }
'''
        # Add imports only to the isolated harness; the actual AppList stays byte-identical.
        body = body.replace('    QtObject { id: control }\n', '')
        result = run(config, env, body, 'component', work, [])
        return result


def test_parity():
    # Compare the actual legacy service, not a rewritten implementation of its parser.
    source = subprocess.run([
        'git', '-C', os.environ.get('WEBSEARCH_LEGACY_REPO', str(REPO.parent / 'websearch')), 'show',
        'origin/fix/caelestia-2.5-safe-sync:modules/launcher/services/WebSearch.qml'
    ], text=True, capture_output=True, check=True).stdout
    body = '''
    Component.onCompleted: {
        const keys = ["google", "youtube", "wiki", "gh", "github", "reddit", "maps"];
        check(Object.keys(WebSearch.providers).join(",") === keys.join(","), "provider order preserved");
        check(JSON.stringify(WebSearch.providers) === JSON.stringify(LegacyWebSearch.providers), "provider definitions unchanged");
        for (const key of keys) {
            for (const input of ["linux", " café 🐧 ", "C++ & 100%", "a\\tb\\nc", "'quoted' /?=#"]) {
                const query = key + " " + input;
                check(WebSearch.parse(query).url === LegacyWebSearch.parse(query).url, "legacy explicit URL parity");
                check(WebSearch.fallback(query).url === LegacyWebSearch.fallback(query).url, "legacy fallback URL parity");
            }
            check(WebSearch.parse(key) === LegacyWebSearch.parse(key), "legacy empty query parity");
        }
        finish.start();
    }
    Timer { id: finish; interval: 1; onTriggered: root.done(); }
'''
    with tempfile.TemporaryDirectory(prefix='caelestia-websearch-parity-') as temp:
        work = Path(temp)
        config, env = setup(work)
        write(config / 'modules/launcher/services/LegacyWebSearch.qml', source)
        return run(config, env, body, 'parity', work, [])


if __name__ == '__main__':
    result = [test_functions(), test_component(), test_parity()]
    (OUT / 'results.json').write_text(json.dumps(result, indent=2) + '\n')
