import qs.components
import qs.services
import qs.config
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    property bool pinned: Config.options?.dock.pinnedOnStartup ?? false
    
    readonly property int padding: Appearance.padding.normal
    readonly property int rounding: Appearance.rounding.large
    
    implicitWidth: dockRow.implicitWidth + padding * 2
    implicitHeight: (Config.options?.dock.height ?? 60) + padding * 2
    
    RowLayout {
        id: dockRow
        anchors.centerIn: parent
        spacing: Appearance.spacing.normal
        
        Rectangle { // Pin button
            Layout.fillHeight: true
            width: 35
            color: root.pinned ? Colours.palette.m3primary : "transparent"
            radius: Appearance.rounding.normal
            border.width: 1
            border.color: Colours.palette.m3outline
            
            MouseArea {
                anchors.fill: parent
                onClicked: root.pinned = !root.pinned
            }
            
            MaterialIcon {
                anchors.centerIn: parent
                text: "keep"
                color: root.pinned ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            }
        }
        
        Rectangle { // Separator
            Layout.fillHeight: true
            width: 1
            color: Colours.palette.m3outlineVariant
        }
        
        DockApps { 
            id: dockApps
        }
        
        Rectangle { // Separator  
            Layout.fillHeight: true
            width: 1
            color: Colours.palette.m3outlineVariant
        }
        
        Rectangle { // Apps button
            Layout.fillHeight: true
            width: 35
            color: "transparent"
            radius: Appearance.rounding.normal
            border.width: 1
            border.color: Colours.palette.m3outline
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    // TODO: Add proper GlobalStates reference
                    console.log("Apps button clicked")
                }
            }
            
            MaterialIcon {
                anchors.centerIn: parent
                text: "apps"
                color: Colours.palette.m3onSurface
            }
        }
    }
}