import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var list
    readonly property string math: list.search.text.slice(`${GlobalConfig.launcher.actionPrefix}calc `.length)

    function onClicked(): void {
        Quickshell.execDetached(["wl-copy", Qalculator.rawResult]);
        root.list.visibilities.launcher = false;
    }

    onMathChanged: {
        if (math.length > 0)
            Qalculator.evalAsync(math);
    }

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.normal
        onClicked: root.onClicked()
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.larger

        spacing: Tokens.spacing.normal

        MaterialIcon {
            text: "function"
            font.pointSize: Tokens.font.size.extraLarge
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            id: result

            color: {
                if (text.includes("error: ") || text.includes("warning: "))
                    return Colours.palette.m3error;
                if (!root.math)
                    return Colours.palette.m3onSurfaceVariant;
                return Colours.palette.m3onSurface;
            }

            text: root.math.length > 0 ? (Qalculator.result || qsTr("Calculating...")) : qsTr("Type an expression to calculate")
            elide: Text.ElideLeft

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        StyledRect {
            color: Colours.palette.m3tertiary
            radius: Tokens.rounding.normal
            clip: true

            implicitWidth: (stateLayer.containsMouse ? label.implicitWidth + label.anchors.rightMargin : 0) + icon.implicitWidth + Tokens.padding.normal * 2
            implicitHeight: Math.max(label.implicitHeight, icon.implicitHeight) + Tokens.padding.small * 2

            Layout.alignment: Qt.AlignVCenter

            StateLayer {
                id: stateLayer

                onClicked: {
                    Quickshell.execDetached(["app2unit", "--", ...Config.general.apps.terminal, "fish", "-C", `exec qalc -i '${root.math}'`]);
                    root.list.visibilities.launcher = false;
                }

                color: Colours.palette.m3onTertiary
            }

            StyledText {
                id: label

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: icon.left
                anchors.rightMargin: Tokens.spacing.small

                text: qsTr("Open in calculator")
                color: Colours.palette.m3onTertiary
                font.pointSize: Tokens.font.size.normal

                opacity: stateLayer.containsMouse ? 1 : 0

                Behavior on opacity {
                    Anim {}
                }
            }

            MaterialIcon {
                id: icon

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Tokens.padding.normal

                text: "open_in_new"
                color: Colours.palette.m3onTertiary
                font.pointSize: Tokens.font.size.large
            }

            Behavior on implicitWidth {
                Anim {
                    type: Anim.Emphasized
                }
            }
        }
    }
}
