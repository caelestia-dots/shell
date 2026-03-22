pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.components
import qs.components.effects
import qs.services
import qs.config
import qs.utils

StyledRect {
    id: root

    required property string modelData
    required property Props props
    required property Flickable container
    required property DrawerVisibilities visibilities

    readonly property list<var> notifs: Notifs.list.filter(n => n.appName === modelData)
    readonly property var groupProps: {
        let count = 0;
        let img = "";
        let icon = "";
        let hasCritical = false;
        let hasNormal = false;
        for (const n of notifs) {
            if (!n.closed) {
                count++;
                if (!img && n.image.length > 0)
                    img = n.image;
                if (!icon && n.appIcon.length > 0)
                    icon = n.appIcon;
                if (n.urgency === NotificationUrgency.Critical)
                    hasCritical = true;
                else if (n.urgency === NotificationUrgency.Normal)
                    hasNormal = true;
            }
        }
        return {
            count,
            img,
            icon,
            urgency: hasCritical ? NotificationUrgency.Critical : hasNormal ? NotificationUrgency.Normal : NotificationUrgency.Low
        };
    }
    readonly property int notifCount: groupProps.count
    readonly property string image: groupProps.img
    readonly property string appIcon: groupProps.icon
    readonly property int urgency: groupProps.urgency

    readonly property int nonAnimHeight: {
        const headerHeight = header.implicitHeight + (root.expanded ? Math.round(Appearance.spacing.small / 2) : 0);
        const columnHeight = headerHeight + notifList.nonAnimHeight + column.Layout.topMargin + column.Layout.bottomMargin;
        return Math.round(Math.max(Config.notifs.sizes.image, columnHeight) + Appearance.padding.normal * 2);
    }
    readonly property bool expanded: props.expandedNotifs.includes(modelData)

    function toggleExpand(expand: bool): void {
        if (expand) {
            if (!expanded)
                props.expandedNotifs.push(modelData);
        } else if (expanded) {
            props.expandedNotifs.splice(props.expandedNotifs.indexOf(modelData), 1);
        }
    }

    Component.onDestruction: {
        if (notifCount === 0 && expanded)
            props.expandedNotifs.splice(props.expandedNotifs.indexOf(modelData), 1);
    }

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: content.implicitHeight + Appearance.padding.normal * 2

    clip: true
    radius: Appearance.rounding.normal
    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

    RowLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Appearance.padding.normal

        spacing: Appearance.spacing.normal

        Item {
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            implicitWidth: Config.notifs.sizes.image
            implicitHeight: Config.notifs.sizes.image

            Component {
                id: imageComp

                Image {
                    source: Qt.resolvedUrl(root.image)
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: Config.notifs.sizes.image
                    sourceSize.height: Config.notifs.sizes.image
                    cache: false
                    asynchronous: true
                    width: Config.notifs.sizes.image
                    height: Config.notifs.sizes.image
                }
            }

            Component {
                id: appIconComp

                ColouredIcon {
                    implicitSize: Math.round(Config.notifs.sizes.image * 0.6)
                    source: Quickshell.iconPath(root.appIcon)
                    colour: root.urgency === NotificationUrgency.Critical ? Colours.palette.m3onError : root.urgency === NotificationUrgency.Low ? Colours.palette.m3onSurface : Colours.palette.m3onSecondaryContainer
                    layer.enabled: root.appIcon.endsWith("symbolic")
                }
            }

            Component {
                id: materialIconComp

                MaterialIcon {
                    text: Icons.getNotifIcon(root.notifs[0]?.summary, root.urgency)
                    color: root.urgency === NotificationUrgency.Critical ? Colours.palette.m3onError : root.urgency === NotificationUrgency.Low ? Colours.palette.m3onSurface : Colours.palette.m3onSecondaryContainer
                    font.pointSize: Appearance.font.size.large
                }
            }

            StyledClippingRect {
                anchors.fill: parent
                color: root.urgency === NotificationUrgency.Critical ? Colours.palette.m3error : root.urgency === NotificationUrgency.Low ? Colours.layer(Colours.palette.m3surfaceContainerHigh, 3) : Colours.palette.m3secondaryContainer
                radius: Appearance.rounding.full

                Loader {
                    asynchronous: true
                    anchors.centerIn: parent
                    sourceComponent: root.image ? imageComp : root.appIcon ? appIconComp : materialIconComp
                }
            }

            Loader {
                asynchronous: true
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                active: root.appIcon && root.image

                sourceComponent: StyledRect {
                    implicitWidth: Config.notifs.sizes.badge
                    implicitHeight: Config.notifs.sizes.badge

                    color: root.urgency === NotificationUrgency.Critical ? Colours.palette.m3error : root.urgency === NotificationUrgency.Low ? Colours.palette.m3surfaceContainerHigh : Colours.palette.m3secondaryContainer
                    radius: Appearance.rounding.full

                    ColouredIcon {
                        anchors.centerIn: parent
                        implicitSize: Math.round(Config.notifs.sizes.badge * 0.6)
                        source: Quickshell.iconPath(root.appIcon)
                        colour: root.urgency === NotificationUrgency.Critical ? Colours.palette.m3onError : root.urgency === NotificationUrgency.Low ? Colours.palette.m3onSurface : Colours.palette.m3onSecondaryContainer
                        layer.enabled: root.appIcon.endsWith("symbolic")
                    }
                }
            }
        }

        ColumnLayout {
            id: column

            Layout.topMargin: -Appearance.padding.small
            Layout.bottomMargin: -Appearance.padding.small / 2
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                id: header

                Layout.bottomMargin: root.expanded ? Math.round(Appearance.spacing.small / 2) : 0
                Layout.fillWidth: true
                spacing: Appearance.spacing.smaller

                StyledText {
                    Layout.fillWidth: true
                    text: root.modelData
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.small
                    elide: Text.ElideRight
                }

                StyledText {
                    animate: true
                    text: root.notifs.find(n => !n.closed)?.timeStr ?? ""
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.small
                }

                StyledRect {
                    implicitWidth: expandBtn.implicitWidth + Appearance.padding.smaller * 2
                    implicitHeight: groupCount.implicitHeight + Appearance.padding.small

                    color: root.urgency === NotificationUrgency.Critical ? Colours.palette.m3error : Colours.layer(Colours.palette.m3surfaceContainerHigh, 3)
                    radius: Appearance.rounding.full

                    StateLayer {
                        function onClicked(): void {
                            root.toggleExpand(!root.expanded);
                        }

                        color: root.urgency === NotificationUrgency.Critical ? Colours.palette.m3onError : Colours.palette.m3onSurface
                    }

                    RowLayout {
                        id: expandBtn

                        anchors.centerIn: parent
                        spacing: Appearance.spacing.small / 2

                        StyledText {
                            id: groupCount

                            Layout.leftMargin: Appearance.padding.small / 2
                            animate: true
                            text: root.notifCount
                            color: root.urgency === NotificationUrgency.Critical ? Colours.palette.m3onError : Colours.palette.m3onSurface
                            font.pointSize: Appearance.font.size.small
                        }

                        MaterialIcon {
                            Layout.rightMargin: -Appearance.padding.small / 2
                            text: "expand_more"
                            color: root.urgency === NotificationUrgency.Critical ? Colours.palette.m3onError : Colours.palette.m3onSurface
                            rotation: root.expanded ? 180 : 0
                            Layout.topMargin: root.expanded ? -Math.floor(Appearance.padding.smaller / 2) : 0

                            Behavior on rotation {
                                Anim {
                                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                                }
                            }

                            Behavior on Layout.topMargin {
                                Anim {
                                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                                }
                            }
                        }
                    }
                }

                Behavior on Layout.bottomMargin {
                    Anim {}
                }
            }

            NotifGroupList {
                id: notifList

                props: root.props
                notifs: root.notifs
                expanded: root.expanded
                container: root.container
                visibilities: root.visibilities
                onRequestToggleExpand: expand => root.toggleExpand(expand)
            }
        }
    }
}
