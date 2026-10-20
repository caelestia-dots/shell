#!/usr/bin/env python3
"""Check immediate acceptance during a real AppList transition; fake opener only."""
import importlib.util
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('existing_tests', HERE / 'run_tests.py')
tests = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tests)
run_original = tests.run


def run(config, env, body, label, work, expected_urls=None):
    content = (tests.REPO / 'modules/launcher/Content.qml').read_text()
    handler = content.split('        onAccepted: {\n', 1)[1].split('\n        Keys.onUpPressed:', 1)[0].rsplit('        }', 1)[0]
    # Keep the original real-AppList regression and run Content's handler verbatim.
    body = '''
    property var screenState: host.session
    property var list: ({currentList: host.entry, showWallpapers: false})
    property string text: host.input.text
    function accept(): void {
''' + handler + '\n    }\n' + body
    needle = '            root.done();\n'
    assert body.count(needle) == 1
    body = body.replace(needle, '''
            // The displayed web result is still present during the fade-out.
            host.input.text = "firefox";
            check(host.entry.currentItem?.modelData?.url === "https://www.reddit.com/search/?q=final", "selected web row remains during fade-out");
            accept();
            check(host.session.launcher, "immediate Enter defers while old web row is displayed");
            check(Apps.launched === "", "stale row never reaches Apps.launch");
            scenarios.start();
''')
    body += SCENARIOS
    # Make both fade phases observable without changing the product sources.
    tokens = work / 'imports/Caelestia/Config/Tokens.qml'
    tokens.write_text(tokens.read_text().replace('small: 10', 'small: 30'))
    services = config / 'modules/launcher/services'
    # Both harness and real AppList observe the same application service double.
    (services / 'Apps.qml').write_text('''pragma Singleton
import QtQuick
import "../../../stubs" as Stubs
QtObject {
    function search(text: string): var { return Stubs.Apps.search(text); }
    function launch(entry: var): void { Stubs.Apps.launch(entry); }
}
''')
    for name in ['Actions', 'Schemes', 'M3Variants']:
        path = services / (name + '.qml')
        source = path.read_text()
        source = source.replace('{name: "command"}', '{name: "command", onClicked: list => { Apps.launch({id: text}); list.screenState.launcher = false; }}')
        source = source.replace('{name: text}', '{name: text, onClicked: list => { Apps.launch({id: text}); list.screenState.launcher = false; }}')
        path.write_text(source)
    # CalcItem is a visual double; only its dispatch is observed, no clipboard.
    calc = config / 'modules/launcher/items/CalcItem.qml'
    calc.write_text(calc.read_text().replace('import QtQuick', 'import QtQuick\nimport qs.modules.launcher.services').replace('    objectName:', '''    function onClicked(): void { Apps.launch({id: list.search.text}); list.screenState.launcher = false; }
    objectName:'''))
    try:
        return run_original(config, env, body, label, work, EXPECTED_URLS)
    finally:
        urls = [json.loads(line) for line in (work / 'urls').read_text().splitlines()] if (work / 'urls').exists() else []
        (tests.OUT / 'transition-review-urls.json').write_text(json.dumps(urls, indent=2) + '\n')
        print('CAPTURED_REVIEW_URLS', json.dumps(urls))


EXPECTED_URLS = [
    'https://www.reddit.com/search/?q=new',
    'https://www.google.com/search?q=new',
    'https://www.google.com/search?q=unmatched%20new',
    'https://www.youtube.com/results?search_query=new',
    'https://www.reddit.com/search/?q=interrupted',
]

SCENARIOS = r'''
    QtObject { id: nativeEntry; property string name: "native app entry" }
    property int scenario: 0
    property int phase: 0
    property bool dispatched: false
    property var routes: [
        ["reddit old", "firefox", "firefox"],
        ["firefox", "reddit new", ""],
        ["reddit old", "google new", ""],
        ["unmatched old", "unmatched new", ""],
        ["google old", "youtube new", ""],
        [">old", ">new", ">new"],
        ["reddit old", ">new", ">new"],
        [">old", "firefox", "firefox"],
        [">calc 1+1", ">calc 2+2", ">calc 2+2"],
        ["reddit old", ">calc 2+2", ">calc 2+2"],
        [">scheme old", ">scheme new", ">scheme new"],
        [">variant old", ">variant new", ">variant new"],
        [">scheme old", ">variant new", ">variant new"],
        ["firefox", "@c Network", "settings"],
        ["firefox", "firefox", "firefox", "roundtrip"],
        ["google old", "reddit interrupted", ""]
    ]
    Timer {
        id: scenarios
        interval: 100
        repeat: true
        onTriggered: {
            if (root.scenario === root.routes.length) {
                stop();
                // Selection changes must not activate the row from the prior index.
                Apps.matches = {firefox: [{id: "first"}, {id: "second"}]};
                host.session.launcher = true;
                host.input.text = "firefox";
                selectionCheck.start();
                return;
            }
            const [oldQuery, query, expectedApp] = root.routes[root.scenario];
            if (root.phase === 0) {
                host.session.launcher = true;
                host.input.text = oldQuery;
                root.phase++;
            } else if (root.phase === 1) {
                check(host.entry.displayText === oldQuery, "source query settled " + oldQuery);
                Apps.launched = "";
                host.input.text = query;
                if (query === "reddit interrupted") {
                    host.input.text = "firefox";
                    host.input.text = ">calc 3+3";
                    host.input.text = query;
                }
                if (root.routes[root.scenario][3] === "roundtrip") {
                    host.input.text = "google abandoned";
                    host.input.text = query;
                    check(host.entry.displayText === query, "interrupted roundtrip retains matching text");
                    check(host.entry.selectedItem() === null, "matching text cannot bypass a running transition");
                }
                const selected = host.entry.selectedItem();
                check(!selected || selected.modelData === host.entry.model.values[host.entry.currentIndex], "immediate selection belongs to current model " + query);
                accept();
                root.dispatched = !host.session.launcher;
                check(Apps.launched === "" || Apps.launched === expectedApp, "immediate dispatch never activates old query " + query);
                if (host.entry.displayText !== query)
                    check(host.session.launcher, "old display cannot dispatch " + query);
                sampleFade.start();
                root.phase++;
            } else {
                check(host.entry.displayText === query, "destination query settled " + query);
                check(host.entry.selectedItem() === host.entry.currentItem, "settled selection accepted " + query);
                if (!root.dispatched)
                    accept();
                check(!host.session.launcher, "current query dispatches after settling " + query);
                check(Apps.launched === expectedApp, "correct dispatch target " + query);
                root.scenario++;
                root.phase = 0;
            }
        }
    }
    Timer {
        id: sampleFade
        interval: 10
        onTriggered: {
            if (host.entry.displayText !== host.input.text) {
                check(host.entry.selectedItem() === null, "fade-out selection rejected");
                accept();
                check(host.session.launcher, "fade-out Enter remains deferred");
            }
            fadeIn.start();
        }
    }
    Timer {
        id: fadeIn
        interval: 30
        onTriggered: {
            // Cross-state queries have swapped their model but are still fading in.
            const [oldQuery, query] = root.routes[root.scenario];
            if (host.entry.stateForText(oldQuery) !== host.entry.stateForText(query)) {
                check(host.entry.displayText === query, "fade-in uses new model");
                check(host.entry.selectedItem() === null, "fade-in selection deferred");
                accept();
                check(host.session.launcher, "fade-in Enter remains deferred");
            }
        }
    }
    Timer {
        id: selectionCheck
        interval: 100
        onTriggered: {
            check(host.entry.currentIndex === 0, "multiple results start at first row");
            // Simulate the ListView's model/delegate update gap deterministically.
            const item = host.entry.currentItem;
            const currentData = item.modelData;
            item.modelData = {id: "stale"};
            Apps.launched = "";
            check(host.entry.selectedItem() === null, "delegate must belong to current model");
            accept();
            check(Apps.launched === "", "stale delegate never dispatches");
            check(host.session.launcher, "stale delegate leaves launcher open");
            item.modelData = currentData;
            check(host.entry.selectedItem() === item, "current delegate can dispatch again");
            host.entry.currentIndex = 1;
            const selected = host.entry.selectedItem();
            check(!selected || selected.modelData.id === "second", "immediate selection change is safe");
            selectedRow.start();
        }
    }
    Timer {
        id: selectedRow
        interval: 100
        onTriggered: {
            check(host.entry.selectedItem()?.modelData.id === "second", "keyboard selection preserved");
            host.session.launcher = true;
            accept();
            check(Apps.launched === "second", "Enter launches selected app, not first result");
            check(!host.session.launcher, "selected app closes launcher");
            // Real applications/actions are QObjects, whereas web rows are JS objects.
            Apps.matches = {firefox: [nativeEntry]};
            host.session.launcher = true;
            objectSelection.start();
        }
    }
    Timer {
        id: objectSelection
        interval: 100
        onTriggered: {
            check(host.entry.currentIndex === 0, "QObject model change resets selection");
            check(host.entry.currentItem?.modelData === nativeEntry, "QObject modelData identity preserved");
            check(host.entry.selectedItem() === host.entry.currentItem, "QObject selection is accepted");
            finish.start();
        }
    }
    Timer { id: finish; interval: 200; onTriggered: root.done(); }
'''


tests.run = run
try:
    result = tests.test_component()
except AssertionError:
    (tests.OUT / 'transition-review.log').write_bytes((tests.OUT / 'component.log').read_bytes())
    print((tests.OUT / 'transition-review.log').read_text())
    raise SystemExit(1)
(tests.OUT / 'transition-results.json').write_text(json.dumps(result, indent=2) + '\n')
