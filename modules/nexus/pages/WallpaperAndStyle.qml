pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.images
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    property string currentCursorTheme: ""
    property int currentCursorSize: 24
    property bool cursorLoaded: false
    property var themeNames: []

    readonly property var cursorSizes: [16, 20, 24, 28, 32, 40, 48, 64, 96, 128]

    function sanitizeCursor(name) {
        return name.replace(/[^a-zA-Z0-9_-]/g, "");
    }

    function applyVisual(theme, size) {
        visualProc.pendingTheme = theme;
        visualProc.pendingSize = size;
        if (!visualProc.running)
            visualProc.running = true;
        else
            visualProc.pendingRun = true;

        persistProc.themeName = theme;
        persistProc.size = size;
        if (!persistProc.running)
            persistProc.running = true;
        else
            persistProc.pendingRun = true;
    }

    function applyCursor(name, size) {
        const safe = sanitizeCursor(name);
        if (safe.length === 0)
            return;

        root.currentCursorTheme = safe;
        root.currentCursorSize = size;
        applyVisual(safe, size);
    }

    title: qsTr("Wallpaper & style")

    Component.onCompleted: cursorListProc.running = true

    data: [
        Process {
            id: cursorListProc

            running: false
            command: ["bash", "-c", "for d in /usr/share/icons \"$HOME/.local/share/icons\" \"$HOME/.icons\"; do " + "[ -d \"$d\" ] && for t in \"$d\"/*/; do " + "[ -d \"${t}cursors\" ] && basename \"$t\"; done; done | sort -u"]

            stdout: SplitParser {
                onRead: data => {
                    const t = data.trim();
                    if (t.length > 0 && !root.themeNames.includes(t))
                        root.themeNames = root.themeNames.concat(t);
                }
            }

            onRunningChanged: {
                if (!running)
                    cursorCurrentProc.running = true;
            }
        },
        Process {
            id: cursorCurrentProc

            running: false
            command: ["bash", "-c", "grep '^\\$cursorTheme' \"$HOME/.config/hypr/variables.conf\" 2>/dev/null | sed 's/.*= *//'; " + "grep '^\\$cursorSize' \"$HOME/.config/hypr/variables.conf\" 2>/dev/null | sed 's/.*= *//'"]

            stdout: SplitParser {
                id: cursorCurrentParser

                property int lineIndex: 0

                onRead: data => {
                    const t = data.trim();
                    if (t.length === 0)
                        return;
                    if (lineIndex === 0)
                        root.currentCursorTheme = t;
                    else {
                        const n = parseInt(t);
                        if (!isNaN(n))
                            root.currentCursorSize = n;
                    }
                    lineIndex++;
                }
            }

            onRunningChanged: {
                if (running)
                    cursorCurrentParser.lineIndex = 0;
                if (!running)
                    root.cursorLoaded = true;
            }
        },
        Process {
            id: visualProc

            property string pendingTheme: ""
            property int pendingSize: 24
            property bool pendingRun: false

            running: false
            command: ["hyprctl", "setcursor", visualProc.pendingTheme, String(visualProc.pendingSize)]

            onRunningChanged: {
                if (!running && pendingRun) {
                    pendingRun = false;
                    running = true;
                }
            }
        },
        Process {
            id: persistProc

            property string themeName: ""
            property int size: 24
            property bool pendingRun: false

            running: false
            command: ["bash", "-c", 'THEME="$1"; SIZE="$2"; ' + 'gsettings set org.gnome.desktop.interface cursor-theme "$THEME"; ' + 'gsettings set org.gnome.desktop.interface cursor-size "$SIZE"; ' + 'CONF="$HOME/.config/hypr/variables.conf"; ' + 'grep -q "^\\$cursorTheme" "$CONF" 2>/dev/null && ' + '  sed -i "s|^\\$cursorTheme = .*|\\$cursorTheme = $THEME|" "$CONF" || ' + '  echo "\\$cursorTheme = $THEME" >> "$CONF"; ' + 'grep -q "^\\$cursorSize" "$CONF" 2>/dev/null && ' + '  sed -i "s|^\\$cursorSize = .*|\\$cursorSize = $SIZE|" "$CONF" || ' + '  echo "\\$cursorSize = $SIZE" >> "$CONF"', "_", persistProc.themeName, String(persistProc.size)]

            stdout: SplitParser {
                onRead: data => console.log("[cursor] persistProc stdout:", data)
            }

            stderr: SplitParser {
                onRead: data => console.log("[cursor] persistProc stderr:", data)
            }

            onRunningChanged: {
                if (!running && pendingRun) {
                    pendingRun = false;
                    running = true;
                }
            }
        }
    ]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        StyledClippingRect {
            id: wallWrapper

            implicitWidth: {
                const screen = root.nState.screen;
                return implicitHeight / screen.height * screen.width;
            }
            implicitHeight: {
                const screen = root.nState.screen;
                const cWidth = root.cappedWidth;
                return Math.min(Math.round(cWidth * 0.4), cWidth / screen.width * screen.height);
            }

            Layout.alignment: Qt.AlignHCenter
            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.large

            Loader {
                anchors.centerIn: parent
                opacity: Config.background.wallpaperEnabled ? 0 : 1
                active: opacity > 0

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hide_image"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Wallpaper disabled")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.large
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }

            Item {
                anchors.fill: parent
                opacity: Config.background.wallpaperEnabled ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }

                Loader {
                    id: wallIndicatorLoader

                    anchors.centerIn: parent
                    opacity: 0
                    active: opacity > 0

                    sourceComponent: StyledRect {
                        implicitWidth: wallLoadingIndicator.implicitSize + Tokens.padding.largeIncreased * 2
                        implicitHeight: wallLoadingIndicator.implicitSize + Tokens.padding.largeIncreased * 2
                        color: Colours.palette.m3primaryContainer
                        radius: Tokens.rounding.full

                        LoadingIndicator {
                            id: wallLoadingIndicator

                            anchors.centerIn: parent
                            containsIcon: true
                            implicitSize: Math.min(wallWrapper.implicitWidth, wallWrapper.implicitHeight) * 0.4
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                Timer {
                    id: wallLoadDebounceTimer

                    interval: 100

                    onTriggered: {
                        if (wallImg.status !== Image.Ready)
                            wallIndicatorLoader.opacity = 1;
                    }
                }

                FadeImage {
                    id: wallImg

                    anchors.fill: parent
                    source: Wallpapers.current
                    preventInit: wallIndicatorLoader.opacity > 0
                    fadeOutAnim: Anim.DefaultEffects
                    fadeInAnim: Anim.SlowEffects

                    onSourceChanged: wallLoadDebounceTimer.restart()

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            wallLoadDebounceTimer.stop();
                            wallIndicatorLoader.opacity = 0;
                        }
                    }
                }
            }
        }

        ButtonRow {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "wallpaper"
                text: qsTr("Wallpapers")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                disabled: !Config.background.wallpaperEnabled
                onClicked: root.nState.openSubPage(1)
            }

            IconTextButton {
                icon: "palette"
                text: qsTr("Colours")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                onClicked: root.nState.openSubPage(3)
            }
        }

        ToggleRow {
            first: true
            text: qsTr("Display wallpaper")
            checked: Config.background.wallpaperEnabled
            onToggled: GlobalConfig.background.wallpaperEnabled = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            text: qsTr("Transparency")
            subtext: qsTr("Base %1, layers %2").arg(Colours.transparency.base).arg(Colours.transparency.layers)
            checked: Colours.transparency.enabled
            onToggled: GlobalConfig.appearance.transparency.enabled = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            last: true
            text: qsTr("Dark theme")
            checked: !Colours.light
            onToggled: Colours.setMode(checked ? "dark" : "light")
        }

        CursorThemeRow {
            first: true
            icon: "mouse"
            popupIcon: "palette"
            label: qsTr("Cursor theme")
            status: root.cursorLoaded ? root.currentCursorTheme : qsTr("Loading…")
        }

        CursorSizeRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            last: true
            icon: "mouse"
            popupIcon: "straighten"
            label: qsTr("Cursor size")
            status: root.cursorLoaded ? root.currentCursorSize + " px" : qsTr("Loading…")
        }
    }

    component CursorThemeRow: PopupRow {
        id: cursorRow

        readonly property int popupHeight: root.flickable.height - y + root.flickable.contentY - Tokens.padding.large - Tokens.padding.extraExtraLarge

        keepPopupAsChild: {
            if (root.nState.animatingContainer || root.opacity < 1)
                return true;

            let p = root.parent;
            while (p && p.objectName !== "PageContainer")
                p = p.parent;
            return p?.opacity < 1;
        }
        popup.topMovement: Math.max(Tokens.sizes.nexus.minPopupHeight - popupHeight, Tokens.padding.large)

        content: Loader {
            id: themeLoader

            active: cursorRow.popup.animDriver > 0

            onLoaded: {
                Qt.callLater(() => {
                    const view = item as VerticalFadeListView;
                    if (view)
                        view.positionViewAtIndex(root.themeNames.indexOf(root.currentCursorTheme), ListView.Center);
                });
            }

            sourceComponent: VerticalFadeListView {
                implicitWidth: Tokens.sizes.nexus.popupWidth
                implicitHeight: CUtils.clamp(cursorRow.popupHeight, Tokens.sizes.nexus.minPopupHeight, Tokens.sizes.nexus.maxPopupHeight)

                model: root.themeNames

                delegate: StateLayer {
                    id: themeItem

                    required property string modelData
                    required property int index

                    anchors.fill: undefined
                    anchors.left: parent?.left
                    anchors.right: parent?.right
                    implicitHeight: itemLayout.implicitHeight + itemLayout.anchors.margins * 2
                    radius: Tokens.rounding.small

                    onClicked: {
                        cursorRow.popup.open = false;
                        root.applyCursor(modelData, root.currentCursorSize);
                    }

                    RowLayout {
                        id: itemLayout

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        StyledText {
                            Layout.fillWidth: true
                            text: themeItem.modelData
                            font: Tokens.font.body.small
                            color: themeItem.modelData === root.currentCursorTheme ? Colours.palette.m3primary : Colours.palette.m3onSurface
                            elide: Text.ElideRight
                        }

                        MaterialIcon {
                            visible: themeItem.modelData === root.currentCursorTheme
                            text: "check"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.small
                        }
                    }
                }
            }
        }

        data: [
            Connections {
                function onOpenChanged() {
                    if (cursorRow.popup.open)
                        Qt.callLater(() => {
                            const view = themeLoader.item as VerticalFadeListView;
                            if (view)
                                view.positionViewAtIndex(root.themeNames.indexOf(root.currentCursorTheme), ListView.Center);
                        });
                }

                target: cursorRow.popup
            }
        ]
    }

    component CursorSizeRow: PopupRow {
        id: cursorSizeRow

        readonly property int popupHeight: root.flickable.height - y + root.flickable.contentY - Tokens.padding.large - Tokens.padding.extraExtraLarge

        keepPopupAsChild: {
            if (root.nState.animatingContainer || root.opacity < 1)
                return true;

            let p = root.parent;
            while (p && p.objectName !== "PageContainer")
                p = p.parent;
            return p?.opacity < 1;
        }
        popup.topMovement: Math.max(Tokens.sizes.nexus.minPopupHeight - popupHeight, Tokens.padding.large)

        content: Loader {
            id: sizeLoader

            active: cursorSizeRow.popup.animDriver > 0

            onLoaded: {
                Qt.callLater(() => {
                    const view = item as VerticalFadeListView;
                    if (view)
                        view.positionViewAtIndex(root.cursorSizes.indexOf(root.currentCursorSize), ListView.Center);
                });
            }

            sourceComponent: VerticalFadeListView {
                implicitWidth: Tokens.sizes.nexus.popupWidth
                implicitHeight: CUtils.clamp(cursorSizeRow.popupHeight, Tokens.sizes.nexus.minPopupHeight, Tokens.sizes.nexus.maxPopupHeight)

                model: root.cursorSizes

                delegate: StateLayer {
                    id: sizeItem

                    required property int modelData
                    required property int index

                    anchors.fill: undefined
                    anchors.left: parent?.left
                    anchors.right: parent?.right
                    implicitHeight: sizeLayout.implicitHeight + sizeLayout.anchors.margins * 2
                    radius: Tokens.rounding.small

                    onClicked: {
                        cursorSizeRow.popup.open = false;
                        root.applyCursor(root.currentCursorTheme, modelData);
                    }

                    RowLayout {
                        id: sizeLayout

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        StyledText {
                            Layout.fillWidth: true
                            text: sizeItem.modelData + " px"
                            font: Tokens.font.body.small
                            color: sizeItem.modelData === root.currentCursorSize ? Colours.palette.m3primary : Colours.palette.m3onSurface
                            elide: Text.ElideRight
                        }

                        MaterialIcon {
                            visible: sizeItem.modelData === root.currentCursorSize
                            text: "check"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.small
                        }
                    }
                }
            }
        }

        data: [
            Connections {
                function onOpenChanged() {
                    if (cursorSizeRow.popup.open)
                        Qt.callLater(() => {
                            const view = sizeLoader.item as VerticalFadeListView;
                            if (view)
                                view.positionViewAtIndex(root.cursorSizes.indexOf(root.currentCursorSize), ListView.Center);
                        });
                }

                target: cursorSizeRow.popup
            }
        ]
    }
}
