pragma ComponentBehavior: Bound

import ".."
import "../../components"
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

CollapsibleSection {
    id: root

    required property var rootPane

    title: qsTr("Fonts")
    showBackground: true

    CollapsibleSection {
        id: materialFontSection
        title: qsTr("Material font family")
        expanded: true
        showBackground: true
        nested: true

        Loader {
            id: materialFontLoader
            Layout.fillWidth: true
            Layout.preferredHeight: item ? Math.min(item.contentHeight, 300) : 0
            asynchronous: true
            active: materialFontSection.expanded

            sourceComponent: StyledListView {
                id: materialFontList
                property alias contentHeight: materialFontList.contentHeight

                clip: true
                spacing: Appearance.spacing.small / 2
                model: Qt.fontFamilies()

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: materialFontList
                }

                delegate: StyledRect {
                    required property string modelData
                    required property int index

                    width: ListView.view.width

                    readonly property bool isCurrent: modelData === rootPane.fontFamilyMaterial
                    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, isCurrent ? Colours.tPalette.m3surfaceContainer.a : 0)
                    radius: Appearance.rounding.normal
                    border.width: isCurrent ? 1 : 0
                    border.color: Colours.palette.m3primary

                    StateLayer {
                        function onClicked(): void {
                            rootPane.fontFamilyMaterial = modelData;
                            rootPane.saveConfig();
                        }
                    }

                    RowLayout {
                        id: fontFamilyMaterialRow

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.normal

                        spacing: Appearance.spacing.normal

                        StyledText {
                            text: modelData
                            font.pointSize: Appearance.font.size.normal
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Loader {
                            active: isCurrent
                            asynchronous: true

                            sourceComponent: MaterialIcon {
                                text: "check"
                                color: Colours.palette.m3onSurfaceVariant
                                font.pointSize: Appearance.font.size.large
                            }
                        }
                    }

                    implicitHeight: fontFamilyMaterialRow.implicitHeight + Appearance.padding.normal * 2
                }
            }
        }
    }

    CollapsibleSection {
        id: monoFontSection
        title: qsTr("Monospace font family")
        expanded: false
        showBackground: true
        nested: true

        Loader {
            Layout.fillWidth: true
            Layout.preferredHeight: item ? Math.min(item.contentHeight, 300) : 0
            asynchronous: true
            active: monoFontSection.expanded

            sourceComponent: StyledListView {
                id: monoFontList
                property alias contentHeight: monoFontList.contentHeight

                clip: true
                spacing: Appearance.spacing.small / 2
                model: Qt.fontFamilies()

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: monoFontList
                }

                delegate: StyledRect {
                    required property string modelData
                    required property int index

                    width: ListView.view.width

                    readonly property bool isCurrent: modelData === rootPane.fontFamilyMono
                    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, isCurrent ? Colours.tPalette.m3surfaceContainer.a : 0)
                    radius: Appearance.rounding.normal
                    border.width: isCurrent ? 1 : 0
                    border.color: Colours.palette.m3primary

                    StateLayer {
                        function onClicked(): void {
                            rootPane.fontFamilyMono = modelData;
                            rootPane.saveConfig();
                        }
                    }

                    RowLayout {
                        id: fontFamilyMonoRow

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.normal

                        spacing: Appearance.spacing.normal

                        StyledText {
                            text: modelData
                            font.pointSize: Appearance.font.size.normal
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Loader {
                            active: isCurrent
                            asynchronous: true

                            sourceComponent: MaterialIcon {
                                text: "check"
                                color: Colours.palette.m3onSurfaceVariant
                                font.pointSize: Appearance.font.size.large
                            }
                        }
                    }

                    implicitHeight: fontFamilyMonoRow.implicitHeight + Appearance.padding.normal * 2
                }
            }
        }
    }

    CollapsibleSection {
        id: sansFontSection
        title: qsTr("Sans-serif font family")
        expanded: false
        showBackground: true
        nested: true

        Loader {
            Layout.fillWidth: true
            Layout.preferredHeight: item ? Math.min(item.contentHeight, 300) : 0
            asynchronous: true
            active: sansFontSection.expanded

            sourceComponent: StyledListView {
                id: sansFontList
                property alias contentHeight: sansFontList.contentHeight

                clip: true
                spacing: Appearance.spacing.small / 2
                model: Qt.fontFamilies()

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: sansFontList
                }

                delegate: StyledRect {
                    required property string modelData
                    required property int index

                    width: ListView.view.width

                    readonly property bool isCurrent: modelData === rootPane.fontFamilySans
                    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, isCurrent ? Colours.tPalette.m3surfaceContainer.a : 0)
                    radius: Appearance.rounding.normal
                    border.width: isCurrent ? 1 : 0
                    border.color: Colours.palette.m3primary

                    StateLayer {
                        function onClicked(): void {
                            rootPane.fontFamilySans = modelData;
                            rootPane.saveConfig();
                        }
                    }

                    RowLayout {
                        id: fontFamilySansRow

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.normal

                        spacing: Appearance.spacing.normal

                        StyledText {
                            text: modelData
                            font.pointSize: Appearance.font.size.normal
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Loader {
                            active: isCurrent
                            asynchronous: true

                            sourceComponent: MaterialIcon {
                                text: "check"
                                color: Colours.palette.m3onSurfaceVariant
                                font.pointSize: Appearance.font.size.large
                            }
                        }
                    }

                    implicitHeight: fontFamilySansRow.implicitHeight + Appearance.padding.normal * 2
                }
            }
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true
            
            label: qsTr("Font size scale")
            value: rootPane.fontSizeScale
            from: 0.7
            to: 1.5
            decimals: 2
            suffix: "×"
            validator: DoubleValidator { bottom: 0.7; top: 1.5 }
            
            onValueModified: (newValue) => {
                rootPane.fontSizeScale = newValue;
                rootPane.saveConfig();
            }
        }
    }
}

