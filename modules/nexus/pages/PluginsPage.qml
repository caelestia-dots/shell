pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Components
import Caelestia.Config
import Caelestia.Plugins
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property var allPlugins: Plugins.plugins // qmllint disable unresolved-type
    readonly property var enabledList: Plugins.loadedPlugins // qmllint disable unresolved-type

    // function openPlugin(plugin: PluginManifest): void {
    //     nState.selectedPlugin = plugin;
    //     nState.openSubPage(1);
    // }

    title: qsTr("Plugins")
    maxWidth: Tokens.sizes.nexus.maxContentWidth * 2
    horizontalPadding: Tokens.padding.extraLarge

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // // Empty state
        // StyledText {
        //     Layout.topMargin: Tokens.spacing.large
        //     Layout.alignment: Qt.AlignHCenter
        //     visible: root.allPlugins.length === 0
        //     text: qsTr("No plugins found in %1").arg("~/.config/caelestia/plugins")
        //     color: Colours.palette.m3outline
        //     font: Tokens.font.body.medium
        // }

        // Installed
        SectionHeader {
            first: true
            text: qsTr("Installed plugins")
            color: Colours.palette.m3onSurface
            font: Tokens.font.title.medium
        }

        PluginGrid {
            plugins: Array.from({
                length: 4
            }, () => ({
                        name: "Example plugin",
                        author: "sora",
                        description: "An example of a plugin. Some long text to test wrapping, blah blah blah. :adodead:",
                        tags: ["example", "tag", "something"],
                        installed: true
                    }))
        }

        // Store
        SectionHeader {
            text: qsTr("Browse plugins")
            color: Colours.palette.m3onSurface
            font: Tokens.font.title.medium
        }

        PluginGrid {
            plugins: Array.from({
                length: 30
            }, () => ({
                        name: "Example plugin",
                        author: "sora",
                        description: "An example of a plugin. Some long text to test wrapping, blah blah blah. :adodead:",
                        tags: ["example", "tag", "something"]
                    }))
        }

        // Repeater {
        //     model: root.enabledList

        //     NavRow {
        //         required property PluginManifest modelData
        //         required property int index

        //         first: index === 0
        //         last: index === root.enabledList.length - 1
        //         icon: modelData.icon || "extension"
        //         label: modelData.name
        //         status: qsTr("%1 · v%2").arg(modelData.author).arg(modelData.version)
        //         onClicked: root.openPlugin(modelData)
        //     }
        // }

        // // Available
        // SectionHeader {
        //     visible: root.availableList.length
        //     text: qsTr("Available")
        // }

        // Repeater {
        //     model: root.availableList

        //     NavRow {
        //         required property PluginManifest modelData
        //         required property int index

        //         first: index === 0
        //         last: index === root.availableList.length - 1
        //         icon: "extension_off"
        //         label: modelData.name
        //         status: qsTr("%1 · v%2").arg(modelData.author).arg(modelData.version)
        //         onClicked: root.openPlugin(modelData)
        //     }
        // }

        // // Issues
        // SectionHeader {
        //     visible: root.issueList.length
        //     text: qsTr("Issues")
        // }

        // Repeater {
        //     model: root.issueList

        //     InfoRow {
        //         required property PluginManifest modelData
        //         required property int index

        //         first: index === 0
        //         last: index === root.issueList.length - 1
        //         icon: "error"
        //         iconColour: Colours.palette.m3error
        //         label: modelData.name || modelData.dir
        //         subtext: modelData.error
        //     }
        // }
    }

    component PluginGrid: LazyGridView {
        id: grid

        property alias plugins: model.values

        Layout.fillWidth: true
        implicitHeight: animatedContentHeight

        cellWidth: 300 // Minimum cell width, elements stretch to fill complete view width
        rowSpacing: Tokens.spacing.large
        columnSpacing: Tokens.spacing.large
        estimatedRowHeight: 426 // Height per plugin card with default tokens and 2 line description, at nexus initial size

        asynchronous: true
        cacheBuffer: 400
        readyDelay: 1

        // Expressive default spatial spring params
        stiffness: 380
        damping: 0.8

        enterDuration: Tokens.anim.durations.expressiveDefaultEffects
        removeDuration: Tokens.anim.durations.expressiveDefaultEffects
        easing: Tokens.anim.expressiveDefaultEffects

        useCustomViewport: true
        viewport: {
            tWatcher.transform; // mapToItem is not reactive so use this to trigger updates
            return Qt.rect(0, root.flickable.contentY - mapToItem(root.flickable.contentItem, 0, 0).y, width, root.flickable.height);
        }

        model: ScriptModel {
            id: model
        }

        delegate: PluginCard {}

        // Frame animation to trigger move/resize springs
        FrameAnimation {
            running: grid.animating
            onTriggered: grid.step(frameTime)
        }

        TransformWatcher {
            id: tWatcher

            a: root.flickable.contentItem
            b: grid
        }
    }

    component PluginCard: StyledRect {
        id: plugin

        required property int index
        required property var modelData

        // TODO: it won't have the installed property, it would be more like checking instanceof PluginManifest vs another type
        readonly property bool isInstalled: modelData.installed ?? false

        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.extraLarge

        implicitHeight: heroWrapper.implicitHeight + detailLayout.implicitHeight + detailLayout.anchors.topMargin + detailLayout.anchors.margins

        StyledClippingRect {
            id: heroWrapper

            anchors.left: parent.left
            anchors.right: parent.right
            implicitHeight: width * 9 / 16

            color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
            radius: Tokens.rounding.extraLarge

            MaterialIcon {
                anchors.centerIn: parent
                text: "image"
                color: Colours.palette.m3outline
                fontStyle: Tokens.font.icon.extraLarge
            }

            // TODO: image
        }

        ColumnLayout {
            id: detailLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: heroWrapper.bottom
            anchors.bottom: parent.bottom
            anchors.margins: Tokens.padding.large
            anchors.topMargin: Tokens.spacing.medium

            spacing: Tokens.spacing.extraSmall

            StyledText {
                Layout.fillWidth: true
                text: plugin.modelData.name
                font: Tokens.font.title.builders.medium.width(110).build()
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            StyledText {
                Layout.topMargin: -parent.spacing / 2
                Layout.fillWidth: true
                text: qsTr("By %1").arg(plugin.modelData.author)
                color: Colours.palette.m3outline
                font: Tokens.font.body.small
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            StyledText {
                Layout.topMargin: Tokens.spacing.extraSmall
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: plugin.modelData.description.repeat(Math.round(Math.random()) + 1)
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            Flow {
                Layout.topMargin: Tokens.spacing.small
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                Repeater {
                    model: plugin.modelData.tags

                    StyledRect {
                        required property string modelData

                        color: Colours.palette.m3tertiaryContainer
                        radius: Tokens.rounding.full

                        implicitWidth: tagText.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: tagText.implicitHeight + Tokens.padding.extraSmall * 2

                        StyledText {
                            id: tagText

                            anchors.centerIn: parent
                            text: parent.modelData
                            color: Colours.palette.m3onTertiaryContainer
                            font: Tokens.font.label.small
                        }
                    }
                }
            }

            Loader {
                Layout.topMargin: Tokens.spacing.medium
                Layout.fillWidth: true

                active: !plugin.isInstalled
                visible: active

                sourceComponent: ButtonRow {
                    spacing: Tokens.spacing.extraSmall

                    TextButton {
                        isRound: true
                        shapeMorph: true
                        fillWidth: true
                        text: qsTr("Install")
                        font: Tokens.font.body.builders.small.width(110).build()
                    }

                    IconButton {
                        isRound: true
                        shapeMorph: true
                        icon: "home"
                        type: IconButton.Tonal
                        implicitWidth: implicitHeight + Tokens.padding.small * 2
                    }
                }
            }
        }
    }
}
