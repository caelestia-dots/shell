pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    property var schemeList: []
    property string draftColour: Colours.sourceColour
    readonly property bool validColour: /^#?(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/.test(draftColour.trim())
    readonly property color selectedColour: validColour ? (draftColour.startsWith("#") ? draftColour : `#${draftColour}`) : Colours.palette.m3primary

    property real hue: 0
    property real saturation: 1
    property real lightness: 0.5

    function applyColour(): void {
        if (!root.validColour)
            return;
        Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "--colour", root.draftColour.trim()]);
    }

    function resetColour(): void {
        Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "--auto-colour"]);
    }

    function colourHex(colour: color): string {
        const channel = value => Math.round(value * 255).toString(16).padStart(2, "0");
        return `${channel(colour.r)}${channel(colour.g)}${channel(colour.b)}`;
    }

    function syncPickerFromDraft(): void {
        const colour = root.selectedColour;
        root.hue = colour.hslHue >= 0 ? colour.hslHue : 0;
        root.saturation = colour.hslSaturation;
        root.lightness = colour.hslLightness;
    }

    function updatePicker(x: real, y: real): void {
        root.saturation = Math.max(0, Math.min(1, x / saturationPicker.width));
        root.lightness = Math.max(0, Math.min(1, 1 - y / saturationPicker.height));
        root.draftColour = root.colourHex(Qt.hsla(root.hue, root.saturation, root.lightness, 1));
    }

    function updateHue(x: real): void {
        root.hue = Math.max(0, Math.min(1, x / huePicker.width));
        root.draftColour = root.colourHex(Qt.hsla(root.hue, root.saturation, root.lightness, 1));
    }

    title: Tr.tr("Colours")
    isSubPage: true

    onDraftColourChanged: root.syncPickerFromDraft()
    Component.onCompleted: getSchemes.running = true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        Connections {
            function onSourceColourChanged(): void {
                root.draftColour = Colours.sourceColour;
            }

            target: Colours
        }

        Process {
            id: getSchemes

            command: ["caelestia", "scheme", "list"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const data = JSON.parse(text);
                    const flat = [];
                    for (const name in data) {
                        for (const flavour in data[name]) {
                            flat.push({
                                name,
                                flavour,
                                colours: data[name][flavour]
                            });
                        }
                    }
                    flat.sort((a, b) => {
                        const aKey = `${a.name}${a.flavour}`;
                        const bKey = `${b.name}${b.flavour}`;
                        return aKey < bKey ? -1 : aKey > bKey ? 1 : 0;
                    });
                    root.schemeList = flat;
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: Tr.tr("Choose the accent colour used to generate the whole Caelestia palette.")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "wallpaper"
                text: Tr.tr("Follow wallpaper")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                onClicked: Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-n", "dynamic"])
            }

            IconTextButton {
                icon: "shuffle"
                text: Tr.tr("Random")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                onClicked: Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-r"])
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: Tr.tr("Custom accent")
            color: Colours.palette.m3onSurface
            font: Tokens.font.title.small
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 64
            color: root.selectedColour
            radius: Tokens.rounding.extraLarge

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.large
                anchors.rightMargin: Tokens.padding.large
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "palette"
                    color: Colours.on(root.selectedColour)
                    fontStyle: Tokens.font.icon.large
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: root.validColour ? Tr.tr("Selected colour") : Tr.tr("Wallpaper colour")
                        color: Colours.on(root.selectedColour)
                        font: Tokens.font.title.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: `#${root.colourHex(root.selectedColour).toUpperCase()}`
                        color: Qt.alpha(Colours.on(root.selectedColour), 0.78)
                        font: Tokens.font.label.small
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: Tr.tr("Saturation and lightness")
            color: Colours.palette.m3onSurface
            font: Tokens.font.title.small
        }

        Item {
            id: saturationPicker

            Layout.fillWidth: true
            implicitHeight: Math.min(260, Math.max(190, width * 0.58))
            clip: true

            Rectangle {
                anchors.fill: parent
                color: Qt.hsla(root.hue, 1, 0.5, 1)

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal

                        GradientStop {
                            position: 0
                            color: "#ffffffff"
                        }
                        GradientStop {
                            position: 1
                            color: "#00ffffff"
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Vertical

                        GradientStop {
                            position: 0
                            color: "#00ffffff"
                        }
                        GradientStop {
                            position: 1
                            color: "#ff000000"
                        }
                    }
                }
            }

            Rectangle {
                x: root.saturation * (parent.width - width)
                y: (1 - root.lightness) * (parent.height - height)
                width: 22
                height: 22
                radius: 11
                color: "transparent"
                border.color: "#ffffffff"
                border.width: 3

                Rectangle {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    radius: 6
                    color: root.selectedColour
                    border.color: "#66000000"
                    border.width: 1
                }
            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true
                onPressed: event => root.updatePicker(event.x, event.y)
                onPositionChanged: event => {
                    if (pressed)
                        root.updatePicker(event.x, event.y);
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: Tr.tr("Hue")
            color: Colours.palette.m3onSurface
            font: Tokens.font.title.small
        }

        Item {
            id: huePicker

            Layout.fillWidth: true
            implicitHeight: 28

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal

                    GradientStop {
                        position: 0.00
                        color: "#ffff0000"
                    }
                    GradientStop {
                        position: 0.17
                        color: "#ffffff00"
                    }
                    GradientStop {
                        position: 0.33
                        color: "#ff00ff00"
                    }
                    GradientStop {
                        position: 0.50
                        color: "#ff00ffff"
                    }
                    GradientStop {
                        position: 0.67
                        color: "#ff0000ff"
                    }
                    GradientStop {
                        position: 0.83
                        color: "#ffff00ff"
                    }
                    GradientStop {
                        position: 1.00
                        color: "#ffff0000"
                    }
                }
            }

            Rectangle {
                x: root.hue * (parent.width - width)
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                radius: 15
                color: "transparent"
                border.color: "#ffffffff"
                border.width: 3

                Rectangle {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    radius: 9
                    color: Qt.hsla(root.hue, 1, 0.5, 1)
                    border.color: "#66000000"
                    border.width: 1
                }
            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true
                onPressed: event => root.updateHue(event.x)
                onPositionChanged: event => {
                    if (pressed)
                        root.updateHue(event.x);
                }
            }
        }

        StyledTextField {
            id: colourField

            Layout.fillWidth: true
            text: root.draftColour
            placeholderText: Tr.tr("HEX colour, e.g. #9bd0cc")
            supportingText: root.validColour ? Tr.tr("Current source: %1").arg(root.draftColour || Tr.tr("automatic")) : ""
            errorText: Tr.tr("Use a 3 or 6 digit hexadecimal colour")
            isError: text.length > 0 && !valid
            validate: /^#?(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/
            leadingIcon: "format_color_fill"
            onTextEdited: root.draftColour = text
            onAccepted: root.applyColour()
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "check"
                text: Tr.tr("Apply")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Filled
                disabled: !root.validColour
                onClicked: root.applyColour()
            }

            IconTextButton {
                icon: "auto_awesome"
                text: Tr.tr("Automatic")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                onClicked: root.resetColour()
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: Colours.sourceColour ? Tr.tr("Manual colour active") : Colours.scheme === "dynamic" ? Tr.tr("Automatic colour from wallpaper active") : Tr.tr("Preset palette selected")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            text: Tr.tr("Palettes")
            font: Tokens.font.title.small
        }

        GridLayout {
            Layout.fillWidth: true
            visible: root.schemeList.length > 0
            columns: Config.nexus.wallpapersPerRow
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.large

            Repeater {
                model: root.schemeList

                SchemeCard {
                    required property var modelData

                    name: modelData.name
                    flavour: modelData.flavour
                    colours: modelData.colours
                    current: modelData.name === Colours.scheme && modelData.flavour === Colours.flavour && !Colours.sourceColour

                    onClicked: Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-n", modelData.name, "-f", modelData.flavour])
                }
            }
        }
    }
}
