import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

// The dock content without the window wrapper
Item {
    id: root
    property bool pinned: Config.options?.dock.pinnedOnStartup ?? false
    
    implicitWidth: dockBackground.implicitWidth
    implicitHeight: (Config.options?.dock.height ?? 70)

    Item { // Wrapper for the dock background
        id: dockBackground
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }

        implicitWidth: dockRow.implicitWidth + 5 * 2
        height: parent.height

        StyledRectangularShadow {
            target: dockVisualBackground
        }
        Rectangle { // The real rectangle that is visible
            id: dockVisualBackground
            anchors.fill: parent
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            radius: Appearance.rounding.large
        }

        RowLayout {
            id: dockRow
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 3
            property real padding: 5

            VerticalButtonGroup {
                Layout.topMargin: 5
                GroupButton { // Pin button
                    baseWidth: 35
                    baseHeight: 35
                    clickedWidth: baseWidth
                    clickedHeight: baseHeight + 20
                    buttonRadius: Appearance.rounding.normal
                    toggled: root.pinned
                    onClicked: root.pinned = !root.pinned
                    contentItem: MaterialSymbol {
                        text: "keep"
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: Appearance.font.pixelSize.larger
                        color: root.pinned ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0
                    }
                }
            }
            DockSeperator {}
            DockApps { id: dockApps; }
            DockSeperator {}
            DockButton {
                Layout.fillHeight: true
                onClicked: GlobalStates.overviewOpen = !GlobalStates.overviewOpen
                contentItem: MaterialSymbol {
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: parent.width / 2
                    text: "apps"
                    color: Appearance.colors.colOnLayer0
                }
            }
        }
    }
}