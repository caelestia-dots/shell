pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.containers
import qs.config
import qs.services

StyledRect {
    id: root

    required property var sections
    required property string activeSection

    signal sectionChanged(string sectionId)

    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
    radius: Appearance.rounding.normal

    implicitWidth: 200

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.padding.normal
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StyledRect {
                id: activeIndicator

                property Item activeTab: {
                    for (let i = 0; i < tabsRepeater.count; i++) {
                        const tab = tabsRepeater.itemAt(i);
                        if (tab && tab.isActive) {
                            return tab;
                        }
                    }
                    return null;
                }

                visible: activeTab !== null
                color: Colours.palette.m3primary
                radius: Appearance.rounding.small

                x: activeTab ? activeTab.x : 0
                y: activeTab ? activeTab.y : 0
                width: activeTab ? activeTab.width : 0
                height: activeTab ? activeTab.height : 0

                Behavior on y {
                    Anim {
                        duration: Appearance.anim.durations.normal
                        easing.bezierCurve: Appearance.anim.curves.emphasized
                    }
                }

                Behavior on height {
                    Anim {
                        duration: Appearance.anim.durations.normal
                        easing.bezierCurve: Appearance.anim.curves.emphasized
                    }
                }
            }

            Column {
                id: tabsColumn
                width: parent.width
                spacing: Appearance.spacing.small

                Repeater {
                    id: tabsRepeater
                    model: root.sections

                    delegate: Item {
                        required property var modelData
                        required property int index

                        property bool isActive: root.activeSection === modelData.id

                        width: tabsColumn.width
                        implicitHeight: tabContent.height + Appearance.padding.small * 2

                        StateLayer {
                            anchors.fill: parent
                            radius: Appearance.rounding.small
                            function onClicked(): void {
                                root.sectionChanged(modelData.id);
                            }
                        }

                        RowLayout {
                            id: tabContent
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: Appearance.padding.normal
                            anchors.rightMargin: Appearance.padding.normal
                            spacing: Appearance.spacing.small

                            MaterialIcon {
                                text: modelData.icon
                                font.pointSize: Appearance.font.size.normal
                                color: parent.parent.isActive ? Colours.palette.m3surface : Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.name
                                font.pointSize: Appearance.font.size.normal
                                color: parent.parent.isActive ? Colours.palette.m3surface : Colours.palette.m3onSurfaceVariant
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
