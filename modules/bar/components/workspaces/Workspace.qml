import qs.components
import qs.services
import qs.utils
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

StyledClippingRect {
    id: bgRoot
    required property int wsId
    required property int wsActiveWindowId
    required property bool wsIsFocused
    required property bool wsIsUrgent
    required property bool wsIsActive
    required property string wsName

    implicitWidth: Config.bar.sizes.innerWidth - 5
    implicitHeight: root.height
    radius: Appearance.rounding.full
    color: wsIsActive ? Colours.layer(Colours.palette.m3surfaceContainerHigh, 2): "transparent"

    Layout.alignment: Qt.AlignHCenter

    ColumnLayout {
        id: root
        anchors.centerIn: parent


        readonly property bool isWorkspace: true // Flag for finding workspace children
        // Unanimated prop for others to use as reference
        // readonly property int size: implicitHeight + (hasWindows ? Appearance.padding.small : 0)
        // Layout.preferredHeight: size

        spacing: 0

        StyledText {
            id: indicator

            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.preferredHeight: Config.bar.sizes.innerWidth - Appearance.padding.small * 2

            animate: true
            text: {
                // if the workspace is empty, its active window id = 0
                if (wsName !== "") {
                    return wsName
                } else if (wsActiveWindowId > 0) {
                    return Config.bar.workspaces.activeLabel
                } else {
                    return Config.bar.workspaces.label
                }
            }
            color: {
                if (wsIsUrgent) {
                    return Colours.palette.m3error
                } else if (wsIsFocused) {
                    return Colours.palette.m3onSurface
                } else {
                    return Colours.layer(Colours.palette.m3outlineVariant, 2)
                }
            }
            verticalAlignment: Qt.AlignVCenter
        }

        Loader {
            id: windows

            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            Layout.topMargin: -Config.bar.sizes.innerWidth / 10

            visible: bgRoot.wsIsActive
            active: bgRoot.wsIsActive
            asynchronous: true

            sourceComponent: Column {
                spacing: 0

                add: Transition {
                    Anim {
                        properties: "scale"
                        from: 0
                        to: 1
                        easing.bezierCurve: Appearance.anim.curves.standardDecel
                    }
                }

                move: Transition {
                    Anim {
                        properties: "scale"
                        to: 1
                        easing.bezierCurve: Appearance.anim.curves.standardDecel
                    }
                    Anim {
                        properties: "x,y"
                    }
                }

                Repeater {
                    model: niri.windows

                    RowLayout {
                        id: window
                        required property int id
                        required property int workspaceId
                        required property string iconPath
                        required property string appId
                        required property bool isFocused

                        property int size: 18

                        visible: workspaceId === bgRoot.wsId

                        MaterialIcon {
                            text: Icons.getAppCategoryIcon(appId, "terminal")
                            color: isFocused ? Colours.palette.m3primary : Colours.palette.m3onSurface
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    console.log("Trying to focus" + window.id)
                                    niri.focusWindow(window.id)
                                }
                            }
                        }
                    }
                }
            }
        }

        Behavior on Layout.preferredHeight {
            Anim {}
        }
    }
}
