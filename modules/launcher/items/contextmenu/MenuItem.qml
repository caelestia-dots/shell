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
    signal triggered
    signal hovered

    Layout.fillWidth: true
    Layout.minimumWidth: itemRow.implicitWidth + Appearance.padding.small * 2
    implicitHeight: 32 + Appearance.padding.small * 2
    radius: Appearance.rounding.small
    color: "transparent"

    Timer {
        id: openTimer
        interval: 250
        onTriggered: if (hasSubMenu && mouse.containsMouse) {
            activeSubmenuIndex = submenuIndex;
            Qt.callLater(() => {
                submenuProgress = 1;
            });
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: hasSubMenu ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: if (!hasSubMenu)
            item.triggered()
        onEntered: {
            item.color = Qt.alpha(Colours.palette.m3onSurface, 0.08);
            item.hovered();
            if (hasSubMenu) {
                hoveredSubmenuIndex = submenuIndex;
                submenuItemY = item.y + item.height / 2;
                submenuCloseTimer.stop();
                openTimer.restart();
            } else if (isSubmenuItem) {
                // Hovering submenu item - keep submenu open
                submenuCloseTimer.stop();
            } else {
                // Hovering regular menu item - close submenu
                hoveredSubmenuIndex = -1;
                if (activeSubmenuIndex >= 0) {
                    submenuCloseTimer.restart();
                }
            }
        }
        onExited: {
            openTimer.stop();
            item.color = "transparent";
            if (!isSubmenuItem && activeSubmenuIndex >= 0) {
                hoveredSubmenuIndex = -1;
                submenuCloseTimer.restart();
            }
        }
        onPressed: if (!hasSubMenu)
            item.color = Qt.alpha(Colours.palette.m3onSurface, 0.12)
        onReleased: if (!hasSubMenu)
            item.color = containsMouse ? Qt.alpha(Colours.palette.m3onSurface, 0.08) : "transparent"
    }

    RowLayout {
        id: itemRow
        anchors.fill: parent
        anchors.margins: Appearance.padding.small
        spacing: Appearance.spacing.normal
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
}
