pragma ComponentBehavior: Bound

import "root:/services"
import "root:/config"
import "root:/utils"
import Quickshell
import QtQuick
import QtQuick.Dialogs

Item {
    id: root

    required property PersistentProperties visibilities
    readonly property PersistentProperties state: PersistentProperties {
        property int currentTab

        readonly property FileDialog facePicker: FileDialog {
            title: qsTr("Select a profile picture")
            acceptLabel: qsTr("Select")
            nameFilters: [`Image files (${Wallpapers.extensions.map(e => `*.${e}`).join(" ")})`]
            onAccepted: {
                Paths.copy(selectedFile, `${Paths.home}/.face`);
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "-h", `STRING:image-path:${Paths.strip(selectedFile)}`, "Profile picture changed", `Profile picture changed to ${Paths.shortenHome(Paths.strip(selectedFile))}`]);
            }
        }
    }

    visible: height > 0
    implicitHeight: 0
    implicitWidth: content.implicitWidth

    states: State {
        name: "visible"
        when: root.visibilities.dashboard

        PropertyChanges {
            root.implicitHeight: content.implicitHeight
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            NumberAnimation {
                target: root
                property: "implicitHeight"
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            NumberAnimation {
                target: root
                property: "implicitHeight"
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
    ]

    Loader {
        id: content

        Component.onCompleted: active = Qt.binding(() => root.visibilities.dashboard || root.visible)

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        sourceComponent: Content {
            visibilities: root.visibilities
            state: root.state
        }
    }
}
