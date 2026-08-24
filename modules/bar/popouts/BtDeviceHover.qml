pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils

StyledRect {
    id: root

    required property PopoutState popouts

    readonly property var connectedDevices: (Bluetooth.devices.values ?? []).filter( // qmllint disable unresolved-type
        d => d.state !== BluetoothDeviceState.Disconnected) // qmllint disable unresolved-type

    width: 340
    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer
    clip: true
    implicitHeight: devicesColumn.implicitHeight + Tokens.padding.large * 2

    ColumnLayout {
        id: devicesColumn

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Tokens.padding.large
        }
        spacing: Tokens.spacing.medium

        Repeater {
            model: ScriptModel {
                values: root.connectedDevices
            }

            // ── Per-device section ──────────────────────────────────────────────
            delegate: ColumnLayout {
                id: deviceSection

                required property BluetoothDevice modelData // qmllint disable unresolved-type

                readonly property string address: deviceSection.modelData?.address ?? ""
                readonly property var bbmData: BbmService.available
                    ? BbmService.dataFor(deviceSection.address)
                    : null

                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                // divider between devices
                Rectangle {
                    visible: deviceSection.index > 0
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.12)
                }

                // ── Device name ───────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    BbmIcon {
                        readonly property string url_: BbmService.deviceIconUrl(deviceSection.address, deviceSection.modelData?.icon ?? "")
                        url: url_
                        visible: url_.length > 0
                        size: 16
                        colour: Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: deviceSection.modelData?.name ?? ""
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }
                }

                // ── Battery circles ───────────────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    visible: GlobalConfig.services?.bluetoothHoverShowBatteries ?? true
                    implicitHeight: batteryRow.implicitHeight

                    Row {
                        id: batteryRow

                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Tokens.spacing.medium

                        Repeater {
                            model: ScriptModel {
                                values: deviceSection.bbmData
                                    ? BbmService.batteriesFor(deviceSection.bbmData)
                                    : deviceSection.modelData?.batteryAvailable === true
                                        ? [{icon: "", level: Math.round((deviceSection.modelData?.battery ?? 0) * 100), charging: false}]
                                        : []
                            }

                            ColumnLayout {
                                id: circleDel

                                required property var modelData

                                spacing: Tokens.spacing.extraSmall

                                Item {
                                    implicitWidth: 56
                                    implicitHeight: 56

                                    CircularProgress {
                                        anchors.fill: parent
                                        value: circleDel.modelData.level / 100
                                        strokeWidth: 4
                                        fgColour: circleDel.modelData.charging
                                            ? Colours.palette.m3tertiary
                                            : BbmService.batteryColorForLevel(circleDel.modelData.level)
                                        bgColour: Qt.alpha(Colours.palette.m3onSurface, 0.12)
                                    }

                                    BbmIcon {
                                        anchors.centerIn: parent
                                        url: BbmService.batteryIconUrl(circleDel.modelData.icon)
                                        visible: url.length > 0
                                        size: 22
                                        colour: circleDel.modelData.charging
                                            ? Colours.palette.m3tertiary
                                            : BbmService.batteryColorForLevel(circleDel.modelData.level)
                                    }

                                    MaterialIcon {
                                        visible: (circleDel.modelData.icon ?? "").length === 0
                                        anchors.centerIn: parent
                                        text: Icons.getDeviceIcon(deviceSection.address, deviceSection.modelData?.icon ?? "")
                                        color: BbmService.batteryColorForLevel(circleDel.modelData.level)
                                    }

                                    MaterialIcon {
                                        visible: circleDel.modelData.charging
                                        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                                        text: "bolt"
                                        color: Colours.palette.m3tertiary
                                        fontStyle: Tokens.font.icon.small
                                    }
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: `${circleDel.modelData.level}%`
                                    color: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.body.small
                                }
                            }
                        }
                    }
                }

                // ── Divider before controls ───────────────────────────────────
                Rectangle {
                    readonly property bool hasBatteries: (GlobalConfig.services?.bluetoothHoverShowBatteries ?? true)
                        && (deviceSection.bbmData !== null || deviceSection.modelData?.batteryAvailable === true)
                    readonly property bool hasControls: (GlobalConfig.services?.bluetoothHoverShowControls ?? true)
                        && deviceSection.bbmData !== null
                        && ((deviceSection.bbmData?.Toggle1Visible ?? false) || (deviceSection.bbmData?.Toggle2Visible ?? false))
                    visible: hasBatteries && hasControls
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.10)
                }

                // ── Toggle rows (Noise Control etc.) ──────────────────────────
                Repeater {
                    model: (GlobalConfig.services?.bluetoothHoverShowControls ?? true)
                        ? BbmService.togglesFor(deviceSection.bbmData)
                        : []

                    delegate: ColumnLayout {
                        id: toggleGroup

                        required property var modelData

                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            visible: toggleGroup.modelData.title.length > 0
                            text: toggleGroup.modelData.title
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall

                            Repeater {
                                model: toggleGroup.modelData.buttons.map((name, i) => ({
                                    name,
                                    icon: (toggleGroup.modelData.buttonIcons ?? [])[i] ?? "",
                                    active: toggleGroup.modelData.state === (i + 1),
                                    widgetId: toggleGroup.modelData.widgetId,
                                    index: i,
                                    addr: deviceSection.address,
                                }))

                                delegate: StyledRect {
                                    id: pill

                                    required property var modelData

                                    readonly property string iconUrl: BbmService.toggleIconUrl(pill.modelData.icon ?? "")

                                    Layout.fillWidth: true
                                    implicitHeight: pillIcon.size + Tokens.padding.small * 2
                                    radius: Tokens.rounding.medium
                                    color: pill.modelData.active
                                        ? Colours.palette.m3primary
                                        : Qt.alpha(Colours.palette.m3onSurface, 0.08)

                                    Behavior on color {
                                        Anim { type: Anim.DefaultEffects }
                                    }

                                    StateLayer {
                                        radius: parent.radius
                                        color: pill.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                                        onClicked: BbmService.sendUIAction(pill.modelData.addr, pill.modelData.widgetId, pill.modelData.index + 1)
                                    }

                                    BbmIcon {
                                        id: pillIcon
                                        anchors.centerIn: parent
                                        url: pill.iconUrl
                                        visible: url.length > 0
                                        size: 18
                                        colour: pill.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                                    }

                                    StyledText {
                                        anchors.centerIn: parent
                                        visible: pill.iconUrl.length === 0
                                        text: pill.modelData.name
                                        color: pill.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                                        font: Tokens.font.body.small
                                    }
                                }
                            }
                        }
                    }
                }

                // ── NC intensity level sub-row ─────────────────────────────────
                Item {
                    id: ancLevelContainer

                    readonly property bool showing: (GlobalConfig.services?.bluetoothHoverShowControls ?? true)
                        && (deviceSection.bbmData?.OptionsBoxVisible ?? 0) === 1
                        && (deviceSection.bbmData?.AncLevelButtons ?? []).length > 0

                    Layout.fillWidth: true
                    implicitHeight: showing ? ancLevelLayout.implicitHeight : 0
                    clip: true

                    Behavior on implicitHeight {
                        Anim {}
                    }

                    ColumnLayout {
                        id: ancLevelLayout

                        width: parent.width
                        spacing: Tokens.spacing.extraSmall
                        opacity: ancLevelContainer.showing ? 1 : 0
                        scale: ancLevelContainer.showing ? 1 : 0.92
                        transformOrigin: Item.Top

                        Behavior on opacity {
                            Anim { type: Anim.StandardSmall }
                        }

                        Behavior on scale {
                            Anim { type: Anim.StandardSmall }
                        }

                        StyledText {
                            visible: (deviceSection.bbmData?.AncLevelTitle ?? "").length > 0
                            text: deviceSection.bbmData?.AncLevelTitle ?? ""
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall

                            Repeater {
                                model: (deviceSection.bbmData?.AncLevelButtons ?? []).map((name, i) => ({
                                    name,
                                    active: (deviceSection.bbmData?.AncLevelState ?? 0) === (i + 1),
                                    index: i,
                                    addr: deviceSection.address,
                                }))

                                delegate: StyledRect {
                                    id: levelPill

                                    required property var modelData

                                    Layout.fillWidth: true
                                    implicitHeight: levelLabel.implicitHeight + Tokens.padding.small * 2
                                    radius: Tokens.rounding.medium
                                    color: levelPill.modelData.active
                                        ? Colours.palette.m3secondary
                                        : Qt.alpha(Colours.palette.m3onSurface, 0.08)

                                    Behavior on color {
                                        Anim { type: Anim.DefaultEffects }
                                    }

                                    StateLayer {
                                        radius: parent.radius
                                        color: levelPill.modelData.active ? Colours.palette.m3onSecondary : Colours.palette.m3onSurface
                                        onClicked: BbmService.sendUIAction(levelPill.modelData.addr, BbmService.WIDGET_ANC_LEVEL, levelPill.modelData.index + 1)
                                    }

                                    StyledText {
                                        id: levelLabel
                                        anchors.centerIn: parent
                                        text: levelPill.modelData.name
                                        color: levelPill.modelData.active ? Colours.palette.m3onSecondary : Colours.palette.m3onSurface
                                        font: Tokens.font.body.small
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}
