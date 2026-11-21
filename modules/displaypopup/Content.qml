pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property LazyLoader loader
    required property ShellScreen screen

    property bool closing: false
    property string pendingMode: Hypr.projectionMode
    property real pendingScale: Hypr.externalScale

    readonly property list<real> scaleSteps: [1, 1.25, 1.5, 1.75, 2]
    readonly property list<string> scaleLabels: ["100%", "125%", "150%", "175%", "200%"]
    readonly property int scaleIndex: {
        const idx = scaleSteps.findIndex(s => Math.abs(s - pendingScale) < 0.01);
        return idx >= 0 ? idx : 0;
    }

    readonly property list<var> modeOptions: [
        {
            id: "extend",
            icon: "vital_signs",
            title: Tr.tr("Extend right"),
            desc: Tr.tr("Place external display to the right")
        },
        {
            id: "extend-up",
            icon: "keyboard_double_arrow_up",
            title: Tr.tr("Extend above"),
            desc: Tr.tr("Place external display above")
        },
        {
            id: "extend-left",
            icon: "keyboard_double_arrow_left",
            title: Tr.tr("Extend left"),
            desc: Tr.tr("Place external display to the left")
        },
        {
            id: "mirror",
            icon: "cast",
            title: Tr.tr("Mirror / Duplicate"),
            desc: Tr.tr("Mirror primary display onto external display")
        },
        {
            id: "external",
            icon: "desktop_windows",
            title: Tr.tr("External only"),
            desc: Tr.tr("Disable built-in display")
        },
        {
            id: "internal",
            icon: "laptop_chromebook",
            title: Tr.tr("Built-in only"),
            desc: Tr.tr("Disable external display")
        }
    ]

    readonly property string externalMonitorInfo: {
        const allMons = Hypr.monitors.values;
        const internal = allMons.find(m => m.name.startsWith("eDP") || m.name.startsWith("LVDS")) ?? allMons[0];
        const ext = allMons.find(m => m !== internal);
        if (!ext)
            return Tr.tr("No external display connected");
        const ipc = ext.lastIpcObject;
        if (ipc && ipc.description)
            return `${ext.name} • ${ipc.description} (${ipc.width}x${ipc.height}@${Math.round(ipc.refreshRate)}Hz)`;
        return ext.name;
    }

    readonly property bool hasChanges: pendingMode !== Hypr.projectionMode || Math.abs(pendingScale - Hypr.externalScale) > 0.01

    function commitAndClose(): void {
        if (closing)
            return;
        closing = true;
        if (hasChanges)
            Hypr.applyMonitorLayout(pendingMode, pendingScale);
        closeTimer.start();
    }

    function cancelAndClose(): void {
        if (closing)
            return;
        closing = true;
        closeTimer.start();
    }

    anchors.fill: parent
    focus: true

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.cancelAndClose();
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.commitAndClose();
            event.accepted = true;
        }
    }

    Timer {
        id: closeTimer

        interval: 180
        onTriggered: root.loader.activeAsync = false
    }

    StyledRect {
        anchors.fill: parent
        color: Colours.palette.m3scrim
        opacity: root.closing ? 0 : 0.45

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.commitAndClose()
        }
    }

    StyledRect {
        id: card

        anchors.centerIn: parent
        width: 560
        implicitHeight: mainCol.implicitHeight + Tokens.padding.extraLarge * 2
        radius: Tokens.rounding.extraLarge
        color: Colours.tPalette.m3surfaceContainerHigh
        border.width: 1
        border.color: Colours.palette.m3outlineVariant
        scale: root.closing ? 0.92 : 1
        opacity: root.closing ? 0 : 1

        Behavior on scale {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: mainCol

            anchors.fill: parent
            anchors.margins: Tokens.padding.extraLarge
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                StyledRect {
                    implicitWidth: 44
                    implicitHeight: 44
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3secondaryContainer

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "monitor"
                        color: Colours.palette.m3onSecondaryContainer
                        fontStyle: Tokens.font.icon.medium
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Display & Projection")
                        font: Tokens.font.title.medium
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.externalMonitorInfo
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                IconButton {
                    icon: "close"
                    type: IconButton.Tonal
                    isRound: true
                    onClicked: root.cancelAndClose()
                }
            }

            StyledText {
                text: Tr.tr("Projection mode")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: Tokens.spacing.small
                columnSpacing: Tokens.spacing.small

                Repeater {
                    model: root.modeOptions

                    StyledRect {
                        id: modeCard

                        required property var modelData

                        readonly property bool isSelected: root.pendingMode === modelData.id

                        Layout.fillWidth: true
                        implicitHeight: 68
                        radius: isSelected ? Tokens.rounding.large : Tokens.rounding.medium
                        color: isSelected ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
                        border.width: isSelected ? 2 : 0
                        border.color: isSelected ? Colours.palette.m3primary : "transparent"

                        Behavior on color {
                            CAnim {}
                        }

                        Behavior on radius {
                            Anim {}
                        }

                        StateLayer {
                            radius: parent.radius
                            onClicked: root.pendingMode = modeCard.modelData.id
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            spacing: Tokens.spacing.medium

                            StyledRect {
                                implicitWidth: 36
                                implicitHeight: 36
                                radius: Tokens.rounding.full
                                color: modeCard.isSelected ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainerHigh

                                Behavior on color {
                                    CAnim {}
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: modeCard.modelData.icon
                                    color: modeCard.isSelected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                                    fontStyle: Tokens.font.icon.small
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    Layout.fillWidth: true
                                    text: modeCard.modelData.title
                                    color: modeCard.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                    font: Tokens.font.body.small
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: modeCard.modelData.desc
                                    color: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.label.small
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small
                opacity: (root.pendingMode === "mirror" || root.pendingMode === "internal") ? 0.45 : 1

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("External display scale")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.medium
                    }

                    StyledRect {
                        implicitWidth: scaleBadgeText.implicitWidth + Tokens.padding.small * 2
                        implicitHeight: scaleBadgeText.implicitHeight + 4
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primary

                        StyledText {
                            id: scaleBadgeText

                            anchors.centerIn: parent
                            text: root.pendingMode === "mirror" ? "1:1" : `${root.scaleLabels[root.scaleIndex]} (${root.pendingScale}x)`
                            color: Colours.palette.m3onPrimary
                            font: Tokens.font.label.small
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 58
                    radius: Tokens.rounding.large
                    color: Colours.tPalette.m3surfaceContainer

                    Item {
                        id: sliderTrack

                        readonly property real usableWidth: Math.max(1, width - thumb.width)
                        readonly property real stepRatio: root.scaleIndex / Math.max(1, root.scaleSteps.length - 1)

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: Tokens.padding.large
                        anchors.rightMargin: Tokens.padding.large
                        anchors.topMargin: Tokens.padding.small
                        height: 24

                        StyledRect {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: thumb.width / 2
                            anchors.rightMargin: thumb.width / 2
                            height: 6
                            radius: Tokens.rounding.full
                            color: Colours.palette.m3surfaceContainerHighest
                        }

                        StyledRect {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: thumb.width / 2
                            width: sliderTrack.usableWidth * sliderTrack.stepRatio
                            height: 6
                            radius: Tokens.rounding.full
                            color: Colours.palette.m3primary

                            Behavior on width {
                                Anim {}
                            }
                        }

                        Repeater {
                            model: root.scaleSteps

                            StyledRect {
                                required property int index
                                required property real modelData

                                readonly property bool passed: index <= root.scaleIndex

                                x: (thumb.width / 2) + (index / Math.max(1, root.scaleSteps.length - 1)) * sliderTrack.usableWidth - width / 2
                                anchors.verticalCenter: parent.verticalCenter
                                width: 10
                                height: 10
                                radius: Tokens.rounding.full
                                color: passed ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                                Behavior on color {
                                    CAnim {}
                                }
                            }
                        }

                        StyledRect {
                            id: thumb

                            x: sliderTrack.stepRatio * sliderTrack.usableWidth
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            height: 20
                            radius: Tokens.rounding.full
                            color: Colours.palette.m3primary
                            border.width: 3
                            border.color: Colours.tPalette.m3surfaceContainer

                            Behavior on x {
                                Anim {}
                            }
                        }

                        MouseArea {
                            function selectAt(mouseX: real): void {
                                const rel = Math.max(0, Math.min(1, (mouseX - thumb.width / 2) / sliderTrack.usableWidth));
                                const idx = Math.round(rel * (root.scaleSteps.length - 1));
                                const chosen = root.scaleSteps[idx];
                                if (chosen !== undefined)
                                    root.pendingScale = chosen;
                            }

                            anchors.fill: parent
                            enabled: root.pendingMode !== "mirror" && root.pendingMode !== "internal"
                            cursorShape: Qt.PointingHandCursor
                            onPressed: mouse => selectAt(mouse.x)
                            onPositionChanged: mouse => {
                                if (pressed)
                                    selectAt(mouse.x);
                            }
                        }
                    }

                    Item {
                        anchors.left: sliderTrack.left
                        anchors.right: sliderTrack.right
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        height: 16

                        Repeater {
                            model: root.scaleLabels

                            StyledText {
                                required property int index
                                required property string modelData

                                readonly property bool isCurrent: index === root.scaleIndex

                                x: (thumb.width / 2) + (index / Math.max(1, root.scaleLabels.length - 1)) * sliderTrack.usableWidth - width / 2
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData
                                font: Tokens.font.label.small
                                color: isCurrent ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("Click outside or press Apply to confirm.")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                    wrapMode: Text.WordWrap
                }

                TextButton {
                    text: root.hasChanges ? Tr.tr("Apply") : Tr.tr("Done")
                    inactiveColour: Colours.palette.m3primary
                    inactiveOnColour: Colours.palette.m3onPrimary
                    onClicked: root.commitAndClose()
                }
            }
        }
    }
}
