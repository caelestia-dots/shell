import qs.components
import qs.services
import qs.config
import Caelestia
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var list
    readonly property string query: encodeURIComponent(list.search.text.slice(`${Config.launcher.actionPrefix}gpt `.length))

    function onClicked(): void {
        Quickshell.execDetached(["fish", "-C",`xdg-open 'https://chatgpt.com/?q=${query}'`]);
        root.list.visibilities.launcher = false;
    }

    implicitHeight: Config.launcher.sizes.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    // Keys.onReturnPressed: onClicked()

    StateLayer {
        radius: Appearance.rounding.normal

        function onClicked(): void {
            root.onClicked();
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Appearance.padding.larger

        spacing: Appearance.spacing.normal

        MaterialIcon {
            text: "smart_toy"
            font.pointSize: Appearance.font.size.extraLarge
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            text: query.length > 0
                ? qsTr("Ask ChatGPT: ") + decodeURIComponent(query)
                : qsTr("Type a message for ChatGPT")
            color: query.length > 0
                ? Colours.palette.m3onSurface
                : Colours.palette.m3onSurfaceVariant
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }
}

