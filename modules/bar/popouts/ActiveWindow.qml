import qs.components
import qs.services
import qs.utils
import qs.config
import Quickshell.Widgets
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Item wrapper

    implicitWidth: child.implicitWidth
    implicitHeight: child.implicitHeight

    Column {
        id: child

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        RowLayout {
            id: detailsRow

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.normal

            IconImage {
                id: icon

                Layout.alignment: Qt.AlignVCenter
                implicitSize: details.implicitHeight
                source: Icons.getAppIcon(niri.focusedWindow?.appId, "desktop_windows")
            }

            ColumnLayout {
                id: details

                spacing: 0
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: niri.focusedWindow?.title ?? qsTr("Application")
                    font.pointSize: Appearance.font.size.normal
                    elide: Text.ElideRight
                    Layout.preferredWidth: 200
                }

                StyledText {
                    Layout.fillWidth: true
                    text: niri.focusedWindow?.appId ?? ""
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }
            }

            Item {
                implicitWidth: expandIcon.implicitHeight + Appearance.padding.small * 2
                implicitHeight: expandIcon.implicitHeight + Appearance.padding.small * 2

                Layout.alignment: Qt.AlignVCenter

                StateLayer {
                    radius: Appearance.rounding.normal

                    function onClicked(): void {
                        root.wrapper.detach("winfo");
                    }
                }

                MaterialIcon {
                    id: expandIcon

                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: font.pointSize * 0.05

                    text: "chevron_right"

                    font.pointSize: Appearance.font.size.large
                }
            }
        }

        ScreencopyView {
            id: preview
            live: true

            captureSource: {
                console.log("Hello")
                wayland: Wayland
                return wayland.getClientByPid(niri.focusedWindow.pid)
            }

            constraintSize.width: Config.bar.sizes.windowPreviewSize
            constraintSize.height: Config.bar.sizes.windowPreviewSize
        }
    }
}
