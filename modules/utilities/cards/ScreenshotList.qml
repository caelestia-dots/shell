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

    spacing: 0

    WrapperMouseArea {
        Layout.fillWidth: true

        cursorShape: Qt.PointingHandCursor
        onClicked: root.props.screenshotListExpanded = !root.props.screenshotListExpanded

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
                text: qsTr("Screenshots")
                font.pointSize: Appearance.font.size.normal
            }

            IconButton {
                icon: root.props.screenshotListExpanded ? "unfold_less" : "unfold_more"
                type: IconButton.Text
                label.animate: true
                onClicked: root.props.screenshotListExpanded = !root.props.screenshotListExpanded
            }
        }
    }

    StyledListView {
        id: list

        model: FileSystemModel {
            path: Paths.shotsdir
            nameFilters: ["screenshot_*.png"]
            sortReverse: true
        }

        Layout.fillWidth: true
        Layout.rightMargin: -Appearance.spacing.small
        implicitHeight: (Appearance.font.size.larger + Appearance.padding.small) * (root.props.screenshotListExpanded ? 10 : 3)
        clip: true

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: list
        }

        delegate: RowLayout {
            id: screenshot

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
                    const time = screenshot.baseName;
                    const matches = time.match(/^screenshot_(\d{4})(\d{2})(\d{2})_(\d{2})-(\d{2})-(\d{2})/);
                    if (!matches)
                        return time;
                    const date = new Date(...matches.slice(1));
                    return qsTr("Screenshot at %1").arg(Qt.formatDateTime(date, Qt.locale()));
                }
                color: Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
            }

            IconButton {
                icon: "photo_library"
                type: IconButton.Text
                onClicked: {
                    root.visibilities.utilities = false;
                    root.visibilities.sidebar = false;
                    Quickshell.execDetached(["app2unit", "--", ...Config.general.apps.image, screenshot.modelData.path]);
                }
            }

            IconButton {
                icon: "folder"
                type: IconButton.Text
                onClicked: {
                    root.visibilities.utilities = false;
                    root.visibilities.sidebar = false;
                    Quickshell.execDetached(["app2unit", "--", ...Config.general.apps.explorer, screenshot.modelData.path]);
                }
            }

            IconButton {
                icon: "delete_forever"
                type: IconButton.Text
                label.color: Colours.palette.m3error
                stateLayer.color: Colours.palette.m3error
                onClicked: root.props.screenshotConfirmDelete = screenshot.modelData.path
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

            sourceComponent: ColumnLayout {
                spacing: Appearance.spacing.small

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "scan_delete"
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.extraLarge

                    opacity: root.props.screenshotListExpanded ? 1 : 0
                    scale: root.props.screenshotListExpanded ? 1 : 0
                    Layout.preferredHeight: root.props.screenshotListExpanded ? implicitHeight : 0

                    Behavior on opacity {
                        Anim {}
                    }

                    Behavior on scale {
                        Anim {}
                    }

                    Behavior on Layout.preferredHeight {
                        Anim {}
                    }
                }

                RowLayout {
                    spacing: Appearance.spacing.smaller

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "scan_delete"
                        color: Colours.palette.m3outline

                        opacity: !root.props.screenshotListExpanded ? 1 : 0
                        scale: !root.props.screenshotListExpanded ? 1 : 0
                        Layout.preferredWidth: !root.props.screenshotListExpanded ? implicitWidth : 0

                        Behavior on opacity {
                            Anim {}
                        }

                        Behavior on scale {
                            Anim {}
                        }

                        Behavior on Layout.preferredWidth {
                            Anim {}
                        }
                    }

                    StyledText {
                        text: qsTr("No screenshots found")
                        color: Colours.palette.m3outline
                    }
                }
            }

            Behavior on opacity { Anim {} }
        }

        Behavior on implicitHeight {
            Anim {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }
    }
}
