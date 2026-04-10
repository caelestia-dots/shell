import "items"
import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick

Item {
    id: root

    readonly property int itemWidth: 100
    readonly property int visibleItems: Math.min(7, Math.max(1, Wallpapers.folders.length))

    implicitWidth: visibleItems * itemWidth
    implicitHeight: 36

    // Extract valid folders to ensure consistent indices
    readonly property var folders: Wallpapers.folders
    readonly property int currentIndex: Wallpapers.currentFolderIndex

    Component {
        id: delegateComponent
        
        Item {
            id: delegateRoot
            
            required property int index
            required property string modelData
            
            width: root.itemWidth
            height: root.height
            
            readonly property bool isCurrent: index === root.currentIndex
            
            // PathView specific properties
            readonly property bool onPath: PathView.onPath ?? true
            readonly property bool isPathCurrent: PathView.isCurrentItem ?? isCurrent
            
            scale: isPathCurrent ? 1.0 : 0.85
            opacity: onPath ? (isPathCurrent ? 1.0 : 0.6) : 0

            StyledRect {
                anchors.fill: parent
                anchors.margins: 4

                color: delegateRoot.isPathCurrent 
                    ? Colours.palette.m3primaryContainer 
                    : Colours.palette.m3surfaceContainerHigh
                radius: Appearance.rounding.full

                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.anim.durations.normal
                    }
                }
            }

            StyledText {
                anchors.centerIn: parent

                text: delegateRoot.modelData
                color: delegateRoot.isPathCurrent 
                    ? Colours.palette.m3onPrimaryContainer 
                    : Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
                font.weight: delegateRoot.isPathCurrent ? 600 : 400
            }

            Behavior on scale {
                Anim {
                    duration: Appearance.anim.durations.normal
                }
            }

            Behavior on opacity {
                Anim {
                    duration: Appearance.anim.durations.normal
                }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: Wallpapers.currentFolderIndex = index
            }
        }
    }

    Loader {
        anchors.fill: parent
        sourceComponent: Config.launcher.folderWrapAround ? pathViewComp : listViewComp
    }

    Component {
        id: listViewComp

        ListView {
            model: root.folders
            currentIndex: root.currentIndex
            
            orientation: ListView.Horizontal
            
            highlightMoveDuration: Appearance.anim.durations.normal
            highlightMoveVelocity: -1
            
            preferredHighlightBegin: (width - itemWidth) / 2
            preferredHighlightEnd: (width + itemWidth) / 2
            highlightRangeMode: ListView.StrictlyEnforceRange

            delegate: delegateComponent
        }
    }

    Component {
        id: pathViewComp
        
        PathView {
            model: root.folders
            currentIndex: root.currentIndex
            
            pathItemCount: root.visibleItems + 2 // Extra items for smooth entry/exit
            
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange
            snapMode: PathView.SnapToItem
            
            delegate: delegateComponent
            
            path: Path {
                startX: -root.itemWidth / 2
                startY: root.height / 2
                
                PathLine {
                    x: root.width + root.itemWidth / 2
                    y: root.height / 2
                }
            }
        }
    }
}
