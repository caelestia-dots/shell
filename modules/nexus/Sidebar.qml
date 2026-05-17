pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus
import qs.modules.nexus.components

Item {
    id: root

    required property NexusSession session

    property string flyoutCategory: ""
    property real flyoutTop: 0
    property string _pendingCategory: ""

    function openFlyout(categoryId, itemGlobalY) {
        flyoutCloseTimer.stop();

        const cat = NexusRegistry.getById(categoryId);
        const childCount = cat && cat.children ? cat.children.length : 0;
        const flyoutHeight = childCount * 68 + 36;
        let top = itemGlobalY - flyoutHeight / 2 + 20;
        if (top < 10)
            top = 10;

        root.flyoutTop = top;
        _pendingCategory = categoryId;
        openDelayTimer.start();
    }
    function scheduleFlyoutClose() {
        flyoutCloseTimer.restart();
    }

    function cancelFlyoutClose() {
        flyoutCloseTimer.stop();
    }

    Timer {
        id: openDelayTimer

        interval: 50
        onTriggered: {
            root.flyoutCategory = root._pendingCategory;
            root._pendingCategory = "";
        }
    }

    Timer {
        id: flyoutCloseTimer

        interval: 250
        onTriggered: root.flyoutCategory = ""
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.small
        anchors.rightMargin: Tokens.padding.small
        anchors.topMargin: Tokens.padding.large
        anchors.bottomMargin: Tokens.padding.smaller
        spacing: 0

        SidebarHeader {
            z: 10
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.normal
            session: root.session // qmllint disable incompatible-type
        }

        Flickable {
            id: navFlick

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Tokens.spacing.normal
            clip: true
            contentHeight: navColumn.height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: navColumn

                width: navFlick.width
                spacing: Tokens.spacing.small

                Repeater {
                    model: NexusRegistry.getCategories()

                    delegate: Column {
                        id: catDelegate

                        required property var modelData
                        required property int index

                        readonly property string catId: modelData.id
                        readonly property bool hasChildren: modelData.children && modelData.children.length > 0

                        width: navColumn.width

                        SidebarNavItem {
                            session: root.session // qmllint disable incompatible-type
                            modelData: catDelegate.modelData
                            flyoutActive: root.flyoutCategory === catDelegate.catId
                            onFlyoutRequested: function (itemY) {
                                root.openFlyout(catDelegate.catId, itemY);
                            }
                            onFlyoutCloseRequested: root.scheduleFlyoutClose()
                        }

                        SidebarAccordion {
                            visible: !root.session.sidebarCollapsed && catDelegate.hasChildren
                            session: root.session // qmllint disable incompatible-type
                            childItems: catDelegate.hasChildren ? catDelegate.modelData.children : []
                            open: root.session.expandedCategory === catDelegate.catId
                        }
                    }
                }
            }
        }

        // Spacer
        Item {
            Layout.fillHeight: false
            Layout.preferredHeight: Tokens.spacing.large
        }

        // Bottom items
        Column {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            Repeater {
                model: NexusRegistry.getBottomItems()

                delegate: SidebarBottomItem {
                    session: root.session // qmllint disable incompatible-type
                }
            }
        }

        // Separator above collapse toggle
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.bottomMargin: Tokens.spacing.normal
            Layout.topMargin: Tokens.spacing.normal
            Layout.leftMargin: Tokens.padding.large
            color: Qt.alpha(Colours.palette.m3onSurface, 0.08)
        }

        // Collapse toggle
        Item {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.large / 1.5
            Layout.preferredHeight: 48

            StyledRect {
                width: parent.width
                height: 40
                radius: Tokens.rounding.full
                color: "transparent"

                Behavior on width {
                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }

                StateLayer {
                    color: Colours.palette.m3onSurface
                    onClicked: root.session.toggleSidebar()
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: root.session.sidebarCollapsed ? "keyboard_double_arrow_right" : "keyboard_double_arrow_left"
                    color: Colours.palette.m3onSurface
                    font.pointSize: Tokens.font.size.large
                }
            }
        }
    }
}
