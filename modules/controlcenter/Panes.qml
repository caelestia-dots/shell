pragma ComponentBehavior: Bound

import "bluetooth"
import "network"
import "audio"
import "appearance"
import "taskbar"
import "launcher"
import qs.components
import qs.services
import qs.config
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

ClippingRectangle {
    id: root

    required property Session session

    color: "transparent"
    clip: true

    ColumnLayout {
        id: layout

        spacing: 0
        y: -root.session.activeIndex * root.height
        clip: true

        Pane {
            index: 0
            sourceComponent: NetworkingPane {
                session: root.session
            }
        }

        Pane {
            index: 1
            sourceComponent: BtPane {
                session: root.session
            }
        }

        Pane {
            index: 2
            sourceComponent: AudioPane {
                session: root.session
            }
        }

        Pane {
            index: 3
            sourceComponent: AppearancePane {
                session: root.session
            }
        }

        Pane {
            index: 4
            sourceComponent: TaskbarPane {
                session: root.session
            }
        }

        Pane {
            index: 5
            sourceComponent: LauncherPane {
                session: root.session
            }
        }

        Behavior on y {
            Anim {}
        }
    }

    component Pane: Item {
        id: pane

        required property int index
        property alias sourceComponent: loader.sourceComponent

        implicitWidth: root.width
        implicitHeight: root.height

        Loader {
            id: loader

            anchors.fill: parent
            clip: false
            asynchronous: true
            active: {
                // Keep loaders active for current and adjacent panels
                // This prevents content from disappearing during panel transitions
                const diff = Math.abs(root.session.activeIndex - pane.index);
                return diff <= 1;
            }
        }
    }
}
