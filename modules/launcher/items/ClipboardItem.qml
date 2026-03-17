import "../services"
import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var modelData
    required property var list

    implicitHeight: Config.launcher.sizes.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    property string imagePath: ""

    function _loadImage(): void {
        imagePath = ""
        if (modelData?.isImage)
            decodeImage.running = true
    }

    Component.onCompleted: _loadImage()
    onModelDataChanged: _loadImage()

    Process {
        id: decodeImage

        command: ["sh", "-c",
            "cliphist decode " + (root.modelData?.id ?? "0")
            + " > /tmp/qs-clipboard-" + (root.modelData?.id ?? "0") + ".png"]

        onRunningChanged: {
            if (!running && root.modelData?.isImage)
                root.imagePath = "/tmp/qs-clipboard-" + root.modelData.id + ".png"
        }
    }

    StateLayer {
        radius: Appearance.rounding.normal

        function onClicked(): void {
            const id = root.modelData?.id ?? ""
            const isImage = root.modelData?.isImage ?? false
            const typeArg = isImage ? " | wl-copy --type image/png" : " | wl-copy"
            Quickshell.execDetached(["sh", "-c", "cliphist decode " + id + typeArg])
            root.list.visibilities.launcher = false
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Appearance.padding.larger
        anchors.rightMargin: Appearance.padding.larger

        spacing: Appearance.spacing.normal

        Item {
            readonly property int sz: Config.launcher.sizes.itemHeight - Appearance.padding.normal * 2

            Layout.preferredWidth: sz
            Layout.preferredHeight: sz
            Layout.alignment: Qt.AlignVCenter

            MaterialIcon {
                anchors.centerIn: parent
                visible: !root.modelData?.isImage
                text: "content_paste"
                font.pointSize: Appearance.font.size.extraLarge
            }

            StyledRect {
                anchors.fill: parent
                visible: root.modelData?.isImage ?? false
                radius: Appearance.rounding.small
                color: Colours.palette.m3surfaceVariant

                Image {
                    anchors.fill: parent
                    source: root.imagePath ? ("file://" + root.imagePath) : ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    visible: !!root.imagePath
                }
            }
        }

        StyledText {
            text: root.modelData?.isImage
                ? qsTr("Image")
                : (root.modelData?.preview ?? "")
            font.pointSize: Appearance.font.size.normal
            elide: Text.ElideRight
            color: root.modelData?.isImage
                ? Colours.palette.m3onSurfaceVariant
                : Colours.palette.m3onSurface
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
