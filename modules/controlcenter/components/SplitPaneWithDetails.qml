pragma ComponentBehavior: Bound

import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.components.containers
import qs.components.effects
import qs.config

Item {
    id: root

    required property Component leftContent
    required property Component rightDetailsComponent
    required property Component rightSettingsComponent

    property var activeItem: null
    property var paneIdGenerator: function (item) {
        return item ? String(item) : "";
    }

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

                onPaneChanged: {
                    nextComponent = getComponentForPane();
                    paneId = root.paneIdGenerator(pane);
                }

                Loader {
                    id: rightLoader

                    anchors.fill: parent

                    asynchronous: true
                    opacity: 1
                    scale: 1
                    transformOrigin: Item.Center

                    clip: false
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
            }
        }
    }

    Loader {
        id: overlayLoader

        anchors.fill: parent
        asynchronous: true
        z: 1000
        sourceComponent: root.overlayComponent
        active: root.overlayComponent !== null
    }
}
