pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.effects
import qs.components.containers
import qs.config
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Component leftContent
    required property Component rightDetailsComponent
    required property Component rightSettingsComponent
    
    property var activeItem: null
    property var paneIdGenerator: function(item) { return item ? String(item) : ""; }
    
    property Component overlayComponent: null

    SplitPaneLayout {
        id: splitLayout

        anchors.fill: parent

        leftContent: root.leftContent

        rightContent: Component {
        Item {
            id: rightPaneItem
            
            property var pane: root.activeItem
            property string paneId: root.paneIdGenerator(pane)
            property Component targetComponent: root.rightSettingsComponent
            property Component nextComponent: root.rightSettingsComponent

            function getComponentForPane() {
                return pane ? root.rightDetailsComponent : root.rightSettingsComponent;
            }

            Component.onCompleted: {
                targetComponent = getComponentForPane();
                nextComponent = targetComponent;
            }

            Loader {
                id: rightLoader

                anchors.fill: parent

                opacity: 1
                scale: 1
                transformOrigin: Item.Center

                clip: false
                asynchronous: true
                sourceComponent: rightPaneItem.targetComponent
            }

            Behavior on paneId {
                PaneTransition {
                    target: rightLoader
                    propertyActions: [
                        PropertyAction {
                            target: rightPaneItem
                            property: "targetComponent"
                            value: rightPaneItem.nextComponent
                        }
                    ]
                }
            }

            onPaneChanged: {
                nextComponent = getComponentForPane();
                paneId = root.paneIdGenerator(pane);
            }
        }
        }
    }

    Loader {
        id: overlayLoader
        
        anchors.fill: parent
        z: 1000
        sourceComponent: root.overlayComponent
        active: root.overlayComponent !== null
    }
}

