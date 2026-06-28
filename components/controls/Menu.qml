pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
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

    property real maxHeight: 320
    property real minHeight: 160
    property real edgeMargin: Tokens.spacing.small

    property real _attachTopY: 0
    property real _attachBottomY: 0

    readonly property real spaceAbove: Math.max(0, _attachTopY - edgeMargin)
    readonly property real spaceBelow: Math.max(0, root.height - _attachBottomY - edgeMargin)

    readonly property bool _preferBottom: attachSideY === Menu.Bottom
    readonly property bool _flipToBottom: !_preferBottom && spaceAbove < minHeight && spaceBelow > spaceAbove
    readonly property bool _flipToTop: _preferBottom && spaceBelow < minHeight && spaceAbove > spaceBelow
    readonly property bool effectiveBottom: _preferBottom ? !_flipToTop : _flipToBottom

    readonly property int effAttachSideY: effectiveBottom ? Menu.Bottom : Menu.Top
    readonly property int effThisSideY: effectiveBottom ? Menu.Top : Menu.Bottom

    readonly property real availableSpace: effectiveBottom ? spaceBelow : spaceAbove

    property list<MenuItem> items
    property MenuItem active: items[0] ?? null
    property bool expanded

    signal itemSelected(item: MenuItem)

    function _updateAttachY() {
        if (!root.attachTo || !root.parent)
            return;
        root._attachTopY = root.attachTo.mapToItem(root.parent, 0, 0).y;
        root._attachBottomY = root.attachTo.mapToItem(root.parent, 0, root.attachTo.height).y;
    }

    function scrollToActive() {
        if (!root.active)
            return;

        const idx = root.items.indexOf(root.active);
        if (idx < 0)
            return;

        const delegate = repeater.itemAt(idx);
        if (!delegate)
            return;

        const target = delegate.y + delegate.height / 2 - flick.height / 2;
        const maxContentY = Math.max(0, flick.contentHeight - flick.height);
        flick.contentY = Math.max(0, Math.min(target, maxContentY));
    }

    onExpandedChanged: {
        if (expanded)
            Qt.callLater(scrollToActive);
    }

    onParentChanged: _updateAttachY()
    Component.onCompleted: _updateAttachY()

    parent: {
        const win = QsWindow.window;
        const contentWin = win as ContentWindow;
        return contentWin ? contentWin.interactionWrapper : (win as QsWindow).contentItem;
    }
    anchors.fill: parent

    enabled: expanded
    onClicked: expanded = false

    opacity: expanded ? 1 : 0
    layer.enabled: opacity < 1

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    TransformWatcher {
        id: watcher

        a: root.parent
        b: root.attachTo
    }

    Connections {
        function onTransformChanged() {
            root._updateAttachY();
        }

        target: watcher
    }

    Connections {
        function onHeightChanged() {
            root._updateAttachY();
        }

        target: root.attachTo
    }

    Elevation {
        id: menu

        readonly property real _pad: Tokens.padding.extraSmall

        x: {
            watcher.transform;
            const item = root.attachTo;
            let off = root.attachSideX === Menu.Left ? 0 : item.width;
            if (root.thisSideX === Menu.Right)
                off -= width;
            return item.mapToItem(root.parent, off, 0).x + root.marginX;
        }
        y: {
            const attachY = root.effAttachSideY === Menu.Top ? root._attachTopY : root._attachBottomY;
            return (root.effThisSideY === Menu.Bottom ? attachY - height : attachY) + root.marginY;
        }

        radius: Tokens.rounding.large
        level: 2

        implicitWidth: Math.max(200, column.implicitWidth + menu._pad * 2 + scrollBar.implicitWidth + Tokens.spacing.extraSmall)

        transform: Scale {
            yScale: root.expanded ? 1 : 0.1
            origin.y: root.effThisSideY === Menu.Bottom ? menu.height : 0

            Behavior on yScale {
                Anim {}
            }
        }

        Binding {
            target: menu
            property: "implicitHeight"
            value: {
                const cap = Math.max(root.minHeight, Math.min(root.maxHeight, root.availableSpace));
                return Math.min(column.implicitHeight + menu._pad * 2, cap);
            }
            delayed: true
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onWheel: e => e.accepted = true
        }

        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: Colours.palette.m3surfaceContainerLow

            VerticalFadeFlickable {
                id: flick

                anchors.fill: parent
                anchors.margins: menu._pad
                anchors.rightMargin: menu._pad + scrollBar.implicitWidth + Tokens.spacing.extraSmall

                contentWidth: width
                contentHeight: column.implicitHeight
                clip: true

                ColumnLayout {
                    id: column

                    width: flick.width
                    spacing: 0

                    Repeater {
                        id: repeater

                        model: root.items

                        StyledRect {
                            id: item

                            required property int index
                            required property MenuItem modelData
                            readonly property bool active: modelData === root?.active

                            Layout.fillWidth: true
                            implicitWidth: menuOptionRow.implicitWidth + Tokens.padding.medium * 2
                            implicitHeight: menuOptionRow.implicitHeight + Tokens.padding.medium * 2

                            radius: active ? Tokens.rounding.medium : Tokens.rounding.extraSmall
                            topLeftRadius: index === 0 ? Tokens.rounding.medium : radius
                            topRightRadius: index === 0 ? Tokens.rounding.medium : radius
                            bottomLeftRadius: index === repeater?.count - 1 ? Tokens.rounding.medium : radius
                            bottomRightRadius: index === repeater?.count - 1 ? Tokens.rounding.medium : radius

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
                                anchors.margins: Tokens.padding.medium
                                spacing: Tokens.spacing.small

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: item.modelData?.icon ?? ""
                                    color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    text: item.modelData?.text ?? ""
                                    color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                                }

                                Loader {
                                    asynchronous: true
                                    Layout.alignment: Qt.AlignVCenter
                                    active: item.modelData?.trailingIcon.length > 0
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

            StyledScrollBar {
                id: scrollBar

                anchors.top: parent.top
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: menu._pad

                flickable: flick
            }
        }
    }
}
