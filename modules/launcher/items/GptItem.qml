import qs.components
import qs.services
import qs.config
import Caelestia
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    focus: true // ensure this item listens to keys globally if needed

    required property var list
    readonly property string query: encodeURIComponent(
        list.search.text.slice(`${Config.launcher.actionPrefix}gpt `.length)
    )

    function onClicked(): void {
        if (query.length === 0)
            return;

        Quickshell.execDetached([
            "fish", "-C",
            `xdg-open 'https://chatgpt.com/?q=${query}'`
        ])
        root.list.visibilities.launcher = false;
    }

    implicitHeight: Config.launcher.sizes.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    // ✅ Pressing Enter on the item itself
    Keys.onReturnPressed: root.onClicked()
    Keys.onEnterPressed: root.onClicked()

    // ✅ Pressing Enter inside the search bar triggers this too
    Component.onCompleted: {
        if (list && list.search) {
            list.search.Keys.onReturnPressed.connect(root.onClicked)
            list.search.Keys.onEnterPressed.connect(root.onClicked)
        }
    }

    StateLayer {
        radius: Appearance.rounding.normal
        function onClicked(): void {
            root.onClicked()
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

