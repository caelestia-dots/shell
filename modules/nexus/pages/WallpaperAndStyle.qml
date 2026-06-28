pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.images
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

    function applyCursor(name, size, isScroll = false) {
        const safe = sanitizeCursor(name);
        if (safe.length === 0)
            return;

        root.currentCursorTheme = safe;
        root.currentCursorSize = size;

        if (isScroll) {
            applyDebounceTimer.themeName = safe;
            applyDebounceTimer.size = size;
            applyDebounceTimer.restart();
        } else {
            applyVisual(safe, size);
        }
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
        Timer {
            id: applyDebounceTimer

            property string themeName: ""
            property int size: 24

            interval: 300
            onTriggered: {
                root.applyVisual(themeName, size);
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
        },
        Variants {
            id: themeVariants

            model: root.themeNames
            delegate: MenuItem {
                required property string modelData

                text: modelData
                icon: modelData === root.currentCursorTheme ? "check" : ""
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

        SelectRow {
            id: cursorThemeSelect

            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            first: true
            label: qsTr("Cursor theme")
            menuItems: themeVariants.instances
            active: menuItems.find(i => i.text === root.currentCursorTheme) ?? null
            onSelected: item => root.applyCursor(item.text, root.currentCursorSize, false)
        }

        Item {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            implicitHeight: sliderRowComponent.implicitHeight

            SliderRow {
                id: sliderRowComponent

                anchors.fill: parent
                last: true
                icon: "mouse"
                label: qsTr("Size")
                value: {
                    if (!root.cursorLoaded)
                        return 0;
                    var idx = root.cursorSizes.indexOf(root.currentCursorSize);
                    if (idx < 0)
                        return 0;
                    return idx / (root.cursorSizes.length - 1);
                }
                valueLabel: {
                    if (!root.cursorLoaded)
                        return qsTr("Loading…");
                    var idx = Math.round(value * (root.cursorSizes.length - 1));
                    if (idx >= 0 && idx < root.cursorSizes.length)
                        return String(root.cursorSizes[idx]) + " px";
                    return String(root.currentCursorSize) + " px";
                }
                onMoved: v => {
                    var idx = Math.round(v * (root.cursorSizes.length - 1));
                    if (idx >= 0 && idx < root.cursorSizes.length) {
                        var newSize = root.cursorSizes[idx];
                        root.applyCursor(root.currentCursorTheme, newSize, true);
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: true

                onPressed: mouse => {
                    mouse.accepted = false;
                }
                onPositionChanged: mouse => {
                    mouse.accepted = false;
                }
                onReleased: mouse => {
                    mouse.accepted = false;
                }

                onWheel: wheel => {
                    wheel.accepted = true;

                    if (!root.cursorLoaded)
                        return;

                    let step = wheel.angleDelta.y > 0 ? 1 : -1;
                    let currentIndex = root.cursorSizes.indexOf(root.currentCursorSize);

                    if (currentIndex < 0)
                        currentIndex = 2;

                    let newIndex = Math.max(0, Math.min(root.cursorSizes.length - 1, currentIndex + step));

                    if (newIndex !== currentIndex) {
                        root.applyCursor(root.currentCursorTheme, root.cursorSizes[newIndex], true);
                    }
                }
            }
        }
    }
}