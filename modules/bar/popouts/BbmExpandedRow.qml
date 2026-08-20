pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

StyledRect {
    id: root

    required property var bbmData
    required property string address

    Layout.fillWidth: true
    Layout.topMargin: Tokens.spacing.extraSmall

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer
    clip: true
    implicitHeight: content.implicitHeight + Tokens.padding.large * 2

    Behavior on implicitHeight {
        Anim {}
    }

    ColumnLayout {
        id: content

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Tokens.padding.large
        }
        spacing: Tokens.spacing.small

        // ── Per-bud battery row ───────────────────────────────────────────────

        RowLayout {
            visible: (root.bbmData?.Battery1Level ?? 0) > 0
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            Repeater {
                model: root.bbmData ? [
                    {icon: root.bbmData.Battery1Icon ?? "", level: root.bbmData.Battery1Level ?? 0, charging: (root.bbmData.Battery1Status ?? "") === "charging"},
                    {icon: root.bbmData.Battery2Icon ?? "", level: root.bbmData.Battery2Level ?? 0, charging: (root.bbmData.Battery2Status ?? "") === "charging"},
                    {icon: root.bbmData.Battery3Icon ?? "", level: root.bbmData.Battery3Level ?? 0, charging: (root.bbmData.Battery3Status ?? "") === "charging"},
                ].filter(b => b.level > 0) : []

                delegate: RowLayout {
                    required property var modelData

                    spacing: Tokens.spacing.extraSmall

                    BbmIcon {
                        url: BbmService.batteryIconUrl(modelData.icon)
                        visible: url.length > 0
                        size: 16
                        colour: Colours.palette.m3onSurface
                    }

                    StyledProgressBar {
                        implicitWidth: 32
                        implicitHeight: 4
                        value: modelData.level / 100
                        fgColour: modelData.level < 20 ? Colours.palette.m3error : Colours.palette.m3primary
                    }

                    StyledText {
                        text: `${modelData.level}%`
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                    }

                    MaterialIcon {
                        visible: modelData.charging
                        text: "bolt"
                        font.pixelSize: 12
                        color: Colours.palette.m3primary
                    }
                }
            }
        }

        // ── ANC / mode toggle (icon-only segmented control) ───────────────────

        Repeater {
            model: [
                {title: root.bbmData?.Toggle1Title ?? "", buttons: root.bbmData?.Toggle1Buttons ?? [], buttonIcons: root.bbmData?.Toggle1ButtonIcons ?? [], state: root.bbmData?.Toggle1State ?? 0, visible: root.bbmData?.Toggle1Visible ?? false, widgetId: "toggle1State"},
                {title: root.bbmData?.Toggle2Title ?? "", buttons: root.bbmData?.Toggle2Buttons ?? [], buttonIcons: root.bbmData?.Toggle2ButtonIcons ?? [], state: root.bbmData?.Toggle2State ?? 0, visible: root.bbmData?.Toggle2Visible ?? false, widgetId: "toggle2State"},
            ].filter(t => t.visible && t.buttons.length > 0)

            delegate: ColumnLayout {
                id: toggleRow

                required property var modelData

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    visible: toggleRow.modelData.title.length > 0
                    text: toggleRow.modelData.title
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }

                // Segmented row — icon-only pills with medium rounding
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    Repeater {
                        model: toggleRow.modelData.buttons.map((name, i) => ({
                            name,
                            icon: (toggleRow.modelData.buttonIcons ?? [])[i] ?? "",
                            active: toggleRow.modelData.state === (i + 1),
                            widgetId: toggleRow.modelData.widgetId,
                            index: i,
                        }))

                        delegate: StyledRect {
                            id: pill

                            required property var modelData

                            // Square-ish pill: equal height/width padding so icon is centred
                            implicitHeight: 18 + Tokens.padding.small * 2
                            implicitWidth: 18 + Tokens.padding.medium * 2

                            radius: Tokens.rounding.medium
                            color: pill.modelData.active
                                ? Colours.palette.m3primary
                                : Qt.alpha(Colours.palette.m3onSurface, 0.08)

                            Behavior on color {
                                Anim { type: Anim.DefaultEffects }
                            }

                            StateLayer {
                                radius: Tokens.rounding.medium
                                color: pill.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                                onClicked: BbmService.sendUIAction(root.address, pill.modelData.widgetId, pill.modelData.index + 1)
                            }

                            BbmIcon {
                                anchors.centerIn: parent
                                url: BbmService.toggleIconUrl(pill.modelData.icon)
                                visible: url.length > 0
                                size: 18
                                colour: pill.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                            }
                        }
                    }
                }
            }
        }

        // ── NC intensity levels — pops in only when NC mode is active ─────────

        Item {
            id: ancLevelContainer

            readonly property bool showing: (root.bbmData?.OptionsBoxVisible ?? 0) === 1
                && (root.bbmData?.AncLevelButtons ?? []).length > 0

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
                    visible: (root.bbmData?.AncLevelTitle ?? "").length > 0
                    text: root.bbmData?.AncLevelTitle ?? ""
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    Repeater {
                        model: (root.bbmData?.AncLevelButtons ?? []).map((name, i) => ({
                            name,
                            active: (root.bbmData?.AncLevelState ?? 0) === (i + 1),
                            index: i,
                        }))

                        delegate: StyledRect {
                            id: levelPill

                            required property var modelData

                            implicitHeight: levelLabel.implicitHeight + Tokens.padding.small * 2
                            implicitWidth: levelLabel.implicitWidth + Tokens.padding.medium * 2

                            radius: Tokens.rounding.medium
                            color: levelPill.modelData.active
                                ? Colours.palette.m3secondary
                                : Qt.alpha(Colours.palette.m3onSurface, 0.08)

                            Behavior on color {
                                Anim { type: Anim.DefaultEffects }
                            }

                            StateLayer {
                                radius: Tokens.rounding.medium
                                color: levelPill.modelData.active ? Colours.palette.m3onSecondary : Colours.palette.m3onSurface
                                onClicked: BbmService.sendUIAction(root.address, "box1RadioButtonState", levelPill.modelData.index + 1)
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

    // ── Theme-aware SVG icon ──────────────────────────────────────────────────
    // BBM SVGs have fill="#2e3436" (dark). Colouriser brightens by
    // (1 - sourceColor.hslLightness) so the dark pixels normalise to near-white
    // before colorizationColor is applied — the icon then takes on the exact
    // theme token colour regardless of light/dark mode.

    component BbmIcon: Item {
        id: iconItem

        required property string url
        required property color colour
        property int size: 18

        implicitWidth: size
        implicitHeight: size

        Image {
            id: img
            anchors.fill: parent
            source: iconItem.url
            sourceSize: Qt.size(iconItem.size, iconItem.size)
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: status !== Image.Error
            layer.enabled: true
            layer.effect: Colouriser {
                sourceColor: "#2e3436"
                colorizationColor: iconItem.colour
            }
        }
    }
}
