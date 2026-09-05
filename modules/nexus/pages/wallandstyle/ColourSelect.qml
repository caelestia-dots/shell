pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    property var schemeList: []

    title: qsTr("Colours")
    isSubPage: true

    Component.onCompleted: getSchemes.running = true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        // Non-visual helper -- PageBase (unlike a plain Item/Layout)
        // overrides its default property to a QQuickItem-only list, so this
        // can't live directly under the PageBase root. ColumnLayout doesn't
        // have that restriction. Kept self-contained here (rather than
        // reusing modules/launcher/services/Schemes.qml, which fetches the
        // same list) since that singleton is coupled to the launcher's
        // Searcher/search-bar machinery, which doesn't apply on a Nexus
        // page -- the current-scheme highlight below instead just binds
        // live to Colours.scheme/flavour, which is already reactive
        // (Colours.qml watches scheme.json directly), so no separate
        // "get current" process or manual bookkeeping is needed here.
        Process {
            id: getSchemes

            command: ["caelestia", "scheme", "list"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const data = JSON.parse(text);
                    const flat = [];
                    for (const name in data)
                        for (const flavour in data[name])
                            flat.push({
                                name,
                                flavour,
                                colours: data[name][flavour]
                            });
                    flat.sort((a, b) => (a.name + a.flavour).localeCompare(b.name + b.flavour));
                    root.schemeList = flat;
                }
            }
        }

        ButtonRow {
            Layout.bottomMargin: Tokens.spacing.medium
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "wallpaper"
                text: qsTr("Follow wallpaper")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                onClicked: Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-n", "dynamic"])
            }

            IconTextButton {
                icon: "shuffle"
                text: qsTr("Random")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                type: IconTextButton.Tonal
                onClicked: Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-r"])
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.large
            text: qsTr("Palettes")
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
                    current: modelData.name === Colours.scheme && modelData.flavour === Colours.flavour

                    onClicked: Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-n", modelData.name, "-f", modelData.flavour])
                }
            }
        }
    }
}
