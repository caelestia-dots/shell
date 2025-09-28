pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import Caelestia
import Caelestia.Models
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var props
    required property var visibilities
    required property string title
    required property string path
    required property var nameFilters
    required property string firstIcon
    required property var firstApp
    required property string textPrefix
    required property string expandedProp

    spacing: 0

    WrapperMouseArea {
        Layout.fillWidth: true

        cursorShape: Qt.PointingHandCursor
        onClicked: root.props[root.expandedProp] = !root.props[root.expandedProp]

        RowLayout {
            spacing: Appearance.spacing.smaller

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                text: "list"
                font.pointSize: Appearance.font.size.large
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                text: qsTr(root.title)
                font.pointSize: Appearance.font.size.normal
            }

            IconButton {
                icon: root.props[root.expandedProp] ? "unfold_less" : "unfold_more"
                type: IconButton.Text
                label.animate: true
                onClicked: root.props[root.expandedProp] = !root.props[root.expandedProp]
            }
        }
    }

    StyledListView {
        id: list

        model: FileSystemModel {
            path: root.path
            nameFilters: root.nameFilters
            sortReverse: true
        }

        Layout.fillWidth: true
        Layout.rightMargin: -Appearance.spacing.small
        implicitHeight: (Appearance.font.size.larger + Appearance.padding.small) * (root.props[root.expandedProp] ? 10 : 3)
        clip: true

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: list
        }

        delegate: RowLayout {
            id: item

            required property FileSystemEntry modelData
            property string baseName

            anchors.left: list.contentItem.left
            anchors.right: list.contentItem.right
            anchors.rightMargin: Appearance.spacing.small
            spacing: Appearance.spacing.small / 2

            Component.onCompleted: baseName = modelData.baseName

            StyledText {
                Layout.fillWidth: true
                Layout.rightMargin: Appearance.spacing.small / 2
                text: {
                    const time = item.baseName;
                    const matches = time.match(new RegExp(`^${root.textPrefix}_(\\d{4})(\\d{2})(\\d{2})_(\\d{2})-(\\d{2})-(\\d{2})`));
                    if (!matches)
                        return time;
                    const date = new Date(...matches.slice(1));
                    return qsTr(`${root.textPrefix} at %1`).arg(Qt.formatDateTime(date, Qt.locale()));
                }
                color: Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
            }

            IconButton {
                icon: root.firstIcon
                type: IconButton.Text
                onClicked: {
                    root.visibilities.utilities = false;
                    root.visibilities.sidebar = false;
                    Quickshell.execDetached(["app2unit", "--", ...root.firstApp, item.modelData.path]);
                }
            }

            IconButton {
                icon: "folder"
                type: IconButton.Text
                onClicked: {
                    root.visibilities.utilities = false;
                    root.visibilities.sidebar = false;
                    Quickshell.execDetached(["app2unit", "--", ...Config.general.apps.explorer, item.modelData.path]);
                }
            }

            IconButton {
                icon: "delete_forever"
                type: IconButton.Text
                label.color: Colours.palette.m3error
                stateLayer.color: Colours.palette.m3error
                enabled: true
                onClicked: root.props[root.textPrefix.toLowerCase() + "ConfirmDelete"] = item.modelData.path
            }
        }

        add: Transition {
            Anim {
                property: "opacity"
                from: 0
                to: 1
            }
            Anim {
                property: "scale"
                from: 0.5
                to: 1
            }
        }

        remove: Transition {
            Anim {
                property: "opacity"
                to: 0
            }
            Anim {
                property: "scale"
                to: 0.5
            }
        }

        displaced: Transition {
            Anim {
                properties: "opacity,scale"
                to: 1
            }
            Anim {
                property: "y"
            }
        }

        Loader {
            anchors.centerIn: parent

            opacity: list.count === 0 ? 1 : 0
            active: opacity > 0
            asynchronous: true

            sourceComponent: list.implicitHeight > 150 ? expandedPlaceholder : collapsedPlaceholder

            Component {
                id: expandedPlaceholder

                ColumnLayout {
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.textPrefix === "Screenshot" ? "image" : "videocam"
                        font.pointSize: Appearance.font.size.larger * 2
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("No %1 found").arg(root.title.toLowerCase())
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.normal
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Take a %1 to see it here").arg(root.title.toLowerCase().slice(0, -1))
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.small
                    }
                }
            }

            Component {
                id: collapsedPlaceholder

                RowLayout {
                    spacing: Appearance.spacing.smaller

                    MaterialIcon {
                        text: root.textPrefix === "Screenshot" ? "image" : "videocam"
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        text: qsTr("No %1").arg(root.title.toLowerCase())
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.small
                        elide: Text.ElideRight
                    }
                }
            }

            Behavior on opacity {
                Anim {}
            }
        }

        Behavior on implicitHeight {
            Anim {
                duration: 80
                easing.bezierCurve: [0, 0, 1, 1]  // Linear easing for speed
            }
        }
    }
}