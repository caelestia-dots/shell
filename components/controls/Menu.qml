pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.modules.drawers

MouseArea {
    id: root

    enum Side {
        Top,
        Bottom,
        Left,
        Right
    }

    required property Item attachTo
    property int attachSideX: Menu.Right
    property int attachSideY: Menu.Bottom
    property int thisSideX: Menu.Right
    property int thisSideY: Menu.Top
    property real marginX
    property real marginY

    property list<MenuItem> items
    property MenuItem active: items[0] ?? null
    property bool expanded

    signal itemSelected(item: MenuItem)

    parent: {
        const win = QsWindow.window;
        const contentWin = win as ContentWindow; // If inside the drawer content window, put it inside the interaction wrapper so hover works
        return contentWin ? contentWin.interactionWrapper : (win as QsWindow).contentItem;
    }
    anchors.fill: parent

    enabled: expanded
    onClicked: expanded = false

    opacity: expanded ? 1 : 0
    layer.enabled: opacity < 1

    Behavior on opacity {
        Anim {
            duration: Tokens.anim.durations.small
        }
    }

    TransformWatcher {
        id: watcher

        a: root.parent
        b: root.attachTo
    }

    Elevation {
        id: menu

        x: {
            watcher.transform; // mapToItem is not reactive so this forces updates
            const item = root.attachTo;
            let off = root.attachSideX === Menu.Left ? 0 : item.width;
            if (root.thisSideX === Menu.Right)
                off -= width;
            return item.mapToItem(root.parent, off, 0).x + root.marginX;
        }
        y: {
            watcher.transform; // mapToItem is not reactive so this forces updates
            const item = root.attachTo;
            let off = root.attachSideY === Menu.Top ? 0 : item.height;
            if (root.thisSideY === Menu.Bottom)
                off -= height;
            return item.mapToItem(root.parent, 0, off).y + root.marginY;
        }

        radius: Tokens.rounding.normal
        level: 2

        implicitWidth: Math.max(200, column.implicitWidth + column.anchors.margins * 2)
        implicitHeight: column.implicitHeight + column.anchors.margins * 2

        transform: Scale {
            yScale: root.expanded ? 1 : 0.1
            origin.y: root.thisSideY === Menu.Bottom ? menu.height : 0

            Behavior on yScale {
                Anim {
                    type: Anim.DefaultSpatial
                }
            }
        }

        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: Colours.palette.m3surfaceContainerLow

            ColumnLayout {
                id: column

                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                spacing: 0

                Repeater {
                    id: repeater

                    model: root.items

                    StyledRect {
                        id: item

                        required property int index
                        required property MenuItem modelData
                        readonly property bool active: modelData === root.active

                        Layout.fillWidth: true
                        implicitWidth: menuOptionRow.implicitWidth + Tokens.padding.normal * 2
                        implicitHeight: menuOptionRow.implicitHeight + Tokens.padding.normal * 2

                        radius: active ? 12 : Tokens.rounding.extraSmall // This should use a token, but tokens are currently extremely scuffed
                        topLeftRadius: index === 0 ? Tokens.rounding.small : radius
                        topRightRadius: index === 0 ? Tokens.rounding.small : radius
                        bottomLeftRadius: index === repeater.count - 1 ? Tokens.rounding.small : radius
                        bottomRightRadius: index === repeater.count - 1 ? Tokens.rounding.small : radius

                        color: Qt.alpha(Colours.palette.m3tertiaryContainer, active ? 1 : 0)

                        Behavior on radius {
                            Anim {}
                        }

                        StateLayer {
                            topLeftRadius: parent.topLeftRadius
                            topRightRadius: parent.topRightRadius
                            bottomLeftRadius: parent.bottomLeftRadius
                            bottomRightRadius: parent.bottomRightRadius

                            color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                            disabled: !root.expanded
                            onClicked: {
                                root.itemSelected(item.modelData);
                                root.active = item.modelData;
                                item.modelData.clicked();
                                root.expanded = false;
                            }
                        }

                        RowLayout {
                            id: menuOptionRow

                            anchors.fill: parent
                            anchors.margins: Tokens.padding.normal
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                Layout.alignment: Qt.AlignVCenter
                                text: item.modelData.icon
                                color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.fillWidth: true
                                text: item.modelData.text
                                color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                            }

                            Loader {
                                asynchronous: true
                                Layout.alignment: Qt.AlignVCenter
                                active: item.modelData.trailingIcon.length > 0
                                visible: active

                                sourceComponent: MaterialIcon {
                                    text: item.modelData.trailingIcon
                                    color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
