pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.hallownest
import qs.services
import qs.modules.launcher.items
import qs.modules.launcher.services

StyledListView {
    id: root

    required property SearchBar search
    required property ScreenState screenState

    property string displayText

    readonly property string requestedState: stateForText(search.text)
    readonly property string displayState: stateForText(displayText)
    readonly property string calcExpression: calcExpressionForText(displayText)
    readonly property string webQuery: webQueryForText(displayText)
    readonly property string translateQuery: displayText.startsWith(`${GlobalConfig.launcher.actionPrefix}tr `) ? displayText.slice(GlobalConfig.launcher.actionPrefix.length + 3) : ""
    readonly property string fileQuery: displayState === "files" ? displayText.slice(1) : ""

    function syncDisplayText(): void {
        if (screenState.launcher && requestedState === displayState)
            displayText = search.text;
    }

    // Plain text counts as a calculation when it starts with "=" or looks like maths
    function isMath(text: string): bool {
        const t = text.trim();
        if (t.startsWith("="))
            return true;
        return /[\d)π]\s*[+\-*\/^×÷]\s*[\d(.√π]/.test(t) // 2+3, (1+2)*3
            || /^-?[\d.,]+\s*[^\s\d]*\s+(to|in)\s+[^\s\d]+$/i.test(t) // 10 km to mi
            || /^[\d.,]+\s*%\s+of\s+[\d.,]+$/i.test(t) // 15% of 200
            || /^[\d.,]+\s*!$/.test(t) // 5!
            || /^√\s*[\d(]/.test(t) // √2
            || /^[a-z]+\(.*\d/i.test(t); // sqrt(16)
    }

    function calcExpressionForText(text: string): string {
        const prefix = `${GlobalConfig.launcher.actionPrefix}calc `;
        if (text.startsWith(prefix))
            return text.slice(prefix.length);
        if (text.startsWith(GlobalConfig.launcher.actionPrefix) || !isMath(text))
            return "";
        const t = text.trim();
        return t.startsWith("=") ? t.slice(1).trim() : t;
    }

    function webQueryForText(text: string): string {
        const prefix = `${GlobalConfig.launcher.actionPrefix}web `;
        return text.startsWith(prefix) ? text.slice(prefix.length) : text;
    }

    function stateForText(text: string): string {
        const prefix = GlobalConfig.launcher.actionPrefix;
        if (text.startsWith(prefix)) {
            for (const action of ["calc", "web", "tr"])
                if (text.startsWith(`${prefix}${action} `))
                    return action;
            if (text.startsWith(`${prefix}theme `))
                return "scheme";
            if (text.startsWith(`${prefix}color `))
                return "flavour";

            return "actions";
        }

        if (text.startsWith("/"))
            return "files";
        if (WebSearch.siteSearch(text))
            return "web";
        if (isMath(text))
            return "calc";
        // Fall back to a web search when nothing matches
        if (text.trim() && !text.startsWith(GlobalConfig.launcher.specialPrefix) && Apps.search(text).length === 0)
            return "web";
        return "apps";
    }

    function resultsForText(text: string): var {
        switch (stateForText(text)) {
        case "actions":
            return Actions.query(text);
        case "calc":
        case "web":
        case "tr":
            return [0];
        case "scheme":
            return Schemes.query(text);
        case "flavour":
            return Flavours.query(text);
        case "files":
            return FileSearch.results;
        default:
            return Apps.search(text);
        }
    }

    model: ScriptModel {
        values: root.resultsForText(root.displayText)
        onValuesChanged: root.currentIndex = 0
    }

    spacing: Tokens.spacing.small
    orientation: Qt.Vertical
    implicitHeight: (Tokens.sizes.launcher.itemHeight + spacing) * Math.min(Config.launcher.maxShown, count) - spacing

    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: ListView.ApplyRange

    highlightFollowsCurrentItem: false
    highlight: HkSelection {
        radius: Tokens.rounding.large

        y: root.currentItem?.y ?? 0
        implicitWidth: root.width
        implicitHeight: root.currentItem?.implicitHeight ?? 0

        Behavior on y {
            Anim {}
        }
    }

    state: screenState.launcher ? requestedState : displayState

    onStateChanged: {
        if (state === "web")
            WebSearch.reload();
    }

    onFileQueryChanged: FileSearch.search(fileQuery)
    Component.onCompleted: displayText = search.text

    states: [
        State {
            name: "apps"

            PropertyChanges {
                root.delegate: appItem
            }
        },
        State {
            name: "actions"

            PropertyChanges {
                root.delegate: actionItem
            }
        },
        State {
            name: "calc"

            PropertyChanges {
                root.delegate: calcItem
            }
        },
        State {
            name: "tr"

            PropertyChanges {
                root.delegate: translateItem
            }
        },
        State {
            name: "web"

            PropertyChanges {
                root.delegate: webItem
            }
        },
        State {
            name: "files"

            PropertyChanges {
                root.delegate: fileItem
            }
        },
        State {
            name: "scheme"

            PropertyChanges {
                root.delegate: schemeItem
            }
        },
        State {
            name: "flavour"

            PropertyChanges {
                root.delegate: schemeItem
            }
        }
    ]

    transitions: Transition {
        SequentialAnimation {
            ParallelAnimation {
                Anim {
                    target: root
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardAccel
                }
                Anim {
                    target: root
                    property: "scale"
                    from: 1
                    to: 0.9
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardAccel
                }
            }
            PropertyAction {
                target: root
                property: "delegate"
                value: null
            }
            ScriptAction {
                script: root.displayText = root.search.text
            }
            PropertyAction {
                target: root
                property: "delegate"
            }
            ParallelAnimation {
                Anim {
                    target: root
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardDecel
                }
                Anim {
                    target: root
                    property: "scale"
                    from: 0.9
                    to: 1
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardDecel
                }
            }
            PropertyAction {
                targets: [root.add, root.remove]
                property: "enabled"
                value: true
            }
        }
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    add: Transition {
        enabled: !root.state

        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            from: 0
            to: 1
        }
    }

    remove: Transition {
        enabled: !root.state

        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            from: 1
            to: 0
        }
    }

    move: Transition {
        Anim {
            property: "y"
        }
        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            to: 1
        }
    }

    addDisplaced: Transition {
        Anim {
            property: "y"
            type: Anim.StandardSmall
        }
        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            to: 1
        }
    }

    displaced: Transition {
        Anim {
            property: "y"
        }
        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            to: 1
        }
    }

    Component {
        id: appItem

        AppItem {
            screenState: root.screenState
        }
    }

    Component {
        id: actionItem

        ActionItem {
            list: root
        }
    }

    Component {
        id: calcItem

        CalcItem {
            list: root
        }
    }

    Component {
        id: translateItem

        TranslateItem {
            list: root
        }
    }

    Component {
        id: webItem

        WebItem {
            list: root
        }
    }

    Component {
        id: fileItem

        FileItem {
            list: root
        }
    }

    Component {
        id: schemeItem

        SchemeItem {
            list: root
        }
    }

    Connections {
        function onTextChanged() {
            root.syncDisplayText();
        }

        target: root.search
    }

    Connections {
        function onLauncherChanged() {
            root.syncDisplayText();
        }

        target: root.screenState
    }
}
