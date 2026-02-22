import qs.components
import qs.config
import qs.services
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: item
    property string text: ""
    property string icon: ""
    property bool bold: false
    property bool hasSubMenu: false
    property int submenuIndex: -1
    property bool isSubmenuItem: false
    property bool isSeparator: false
    property bool preventSubmenuClose: false
    signal triggered
    signal hovered

    Layout.fillWidth: true
    Layout.minimumWidth: isSeparator ? 0 : (itemRow.implicitWidth + Appearance.padding.small * 2)
    implicitHeight: isSeparator ? 1 : (32 + Appearance.padding.small * 2)
    radius: isSeparator ? 0 : Appearance.rounding.small
    color: "transparent"

    Timer {
        id: openTimer
        interval: 250
        onTriggered: if (item.hasSubMenu && mouse.containsMouse) {
            activeSubmenuIndex = item.submenuIndex;
            Qt.callLater(() => {
                submenuProgress = 1;
            });
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: !item.isSeparator
        hoverEnabled: !item.isSeparator
        cursorShape: item.hasSubMenu ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: if (!item.hasSubMenu)
            item.triggered()
        onEntered: {
            item.color = Qt.alpha(Colours.palette.m3primary, 0.15);
            item.hovered();
            if (item.hasSubMenu) {
                hoveredSubmenuIndex = item.submenuIndex;
                submenuItemY = item.y + item.height / 2;
                submenuCloseTimer.stop();
                openTimer.restart();
            } else if (item.isSubmenuItem) {
                submenuCloseTimer.stop();
            } else {
                hoveredSubmenuIndex = -1;
                if (activeSubmenuIndex >= 0) {
                    submenuCloseTimer.restart();
                }
            }
        }
        onExited: {
            openTimer.stop();
            item.color = "transparent";
            if (activeSubmenuIndex >= 0 && !item.preventSubmenuClose) {
                hoveredSubmenuIndex = -1;
                submenuCloseTimer.restart();
            }
        }
        onPressed: if (!item.hasSubMenu)
            item.color = Qt.alpha(Colours.palette.m3primary, 0.2)
        onReleased: if (!item.hasSubMenu)
            item.color = containsMouse ? Qt.alpha(Colours.palette.m3primary, 0.15) : "transparent"
    }

    RowLayout {
        id: itemRow
        anchors.fill: parent
        anchors.margins: Appearance.padding.small
        spacing: Appearance.spacing.normal
        visible: !item.isSeparator

        MaterialIcon {
            text: item.icon
            visible: text.length > 0
            color: Colours.palette.m3onSurface
            font.pointSize: Appearance.font.size.normal
        }
        StyledText {
            text: item.text
            color: Colours.palette.m3onSurface
            font.pointSize: Appearance.font.size.normal
            font.weight: item.bold ? Font.DemiBold : Font.Normal
        }
        Item {
            Layout.fillWidth: true
        }
        MaterialIcon {
            text: "chevron_right"
            visible: item.hasSubMenu
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.normal
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width - Appearance.padding.small * 2
        height: 1
        color: Colours.palette.m3outlineVariant
        visible: item.isSeparator
    }
}
