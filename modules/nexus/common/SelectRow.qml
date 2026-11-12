import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.hallownest
import qs.services
import qs.modules.nexus.common

ConnectedRect {
    id: root

    property alias label: label.text
    property string subtext
    property list<MenuItem> menuItems
    property MenuItem active
    property string fallbackText
    // Kept for the callers; HkSelect has no icons and places its popup itself
    property string fallbackIcon
    property bool menuOnTop

    signal selected(item: MenuItem)

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins * 2

    RowLayout {
        id: rowLayout

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: label

                Layout.fillWidth: true
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.subtext
                text: root.subtext
                color: Hallownest.subtext
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        HkSelect {
            options: root.menuItems
            currentIndex: root.menuItems.indexOf(root.active)
            placeholder: root.fallbackText
            onActivated: index => root.selected(root.menuItems[index])
        }
    }
}
