pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

StyledRect {
    id: root

    required property string modelData
    required property Props props
    required property Flickable container
    required property DrawerVisibilities visibilities

    readonly property list<var> notifs: Notifs.list.filter(n => n.appName === modelData)
    readonly property list<var> activeNotifs: notifs.filter(n => !n.closed)
    readonly property int notifCount: activeNotifs.length
    readonly property string image: activeNotifs.find(n => n.image.length > 0)?.image ?? ""
    readonly property string appIcon: activeNotifs.find(n => n.appIcon.length > 0)?.appIcon ?? ""
    readonly property int urgency: {
        if (activeNotifs.find(n => n.urgency === NotificationUrgency.Critical))
            return NotificationUrgency.Critical;
        if (activeNotifs.find(n => n.urgency === NotificationUrgency.Normal))
            return NotificationUrgency.Normal;
        return NotificationUrgency.Low;
    }

    readonly property int nonAnimHeight: {
        const headerHeight = header.implicitHeight + (root.expanded ? Math.round(Tokens.spacing.extraSmall) : 0);
        const columnHeight = headerHeight + notifList.layoutHeight;
        return Math.round(Math.max(TokenConfig.sizes.notifs.image, columnHeight) + Tokens.padding.medium * 2);
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
    implicitHeight: nonAnimHeight

    clip: true
    radius: Tokens.rounding.large
    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

    Behavior on implicitHeight {
        Anim {}
    }

    RowLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.medium

        spacing: Tokens.spacing.medium

        Item {
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            implicitWidth: TokenConfig.sizes.notifs.image
            implicitHeight: TokenConfig.sizes.notifs.image

            Component {
                id: imageComp

                Image {
                    source: Qt.resolvedUrl(root.image)
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: {
                        const size = TokenConfig.sizes.notifs.image * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1);
                        return Qt.size(size, size);
                    }
                    cache: false
                    asynchronous: true
                    width: TokenConfig.sizes.notifs.image
                    height: TokenConfig.sizes.notifs.image
                }
            }

            Component {
                id: appIconComp

                ColouredIcon {
                    implicitSize: Math.round(TokenConfig.sizes.notifs.image * 0.6)
                    source: Quickshell.iconPath(root.appIcon)
                    colour: root.urgency === NotificationUrgency.Critical ? Colours.palette.m3onError : root.urgency === NotificationUrgency.Low ? Colours.palette.m3onSurface : Colours.palette.m3onSecondaryContainer
                    layer.enabled: root.appIcon.endsWith("symbolic")
                }
            }

            Component {
                id: materialIconComp

                MaterialIcon {
                    text: Icons.getNotifIcon(root.activeNotifs[0]?.summary, root.urgency)
                    color: root.urgency === NotificationUrgency.Critical ? Colours.palette.m3onError : root.urgency === NotificationUrgency.Low ? Colours.palette.m3onSurface : Colours.palette.m3onSecondaryContainer
                    fontStyle: Tokens.font.icon.medium
                }
            }

            StyledClippingRect {
                anchors.fill: parent
                color: root.urgency === NotificationUrgency.Critical ? Colours.palette.m3error : root.urgency === NotificationUrgency.Low ? Colours.layer(Colours.palette.m3surfaceContainerHigh, 3) : Colours.palette.m3secondaryContainer
                radius: Tokens.rounding.full

                Loader {
                    asynchronous: true
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: sourceComponent === materialIconComp ? 1 : 0
                    sourceComponent: root.image ? imageComp : root.appIcon ? appIconComp : materialIconComp
                }
            }

            Loader {
                asynchronous: true
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                active: root.appIcon && root.image

                sourceComponent: StyledRect {
                    implicitWidth: Tokens.sizes.notifs.badge
                    implicitHeight: Tokens.sizes.notifs.badge

                    color: root.urgency === NotificationUrgency.Critical ? Colours.palette.m3error : root.urgency === NotificationUrgency.Low ? Colours.palette.m3surfaceContainerHigh : Colours.palette.m3secondaryContainer
                    radius: Tokens.rounding.full

                    ColouredIcon {
                        anchors.centerIn: parent
                        implicitSize: Math.round(Tokens.sizes.notifs.badge * 0.6)
                        source: Quickshell.iconPath(root.appIcon)
                        colour: root.urgency === NotificationUrgency.Critical ? Colours.palette.m3onError : root.urgency === NotificationUrgency.Low ? Colours.palette.m3onSurface : Colours.palette.m3onSecondaryContainer
                        layer.enabled: root.appIcon.endsWith("symbolic")
                    }
                }
            }
        }

        Column {
            id: column

            Layout.fillWidth: true
            spacing: root.expanded ? Math.round(Tokens.spacing.extraSmall) : 0

            Behavior on spacing {
                Anim {}
            }

            RowLayout {
                id: header

                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: root.modelData
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    animate: true
                    text: root.activeNotifs[0]?.timeStr ?? ""
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.small
                }

                StyledRect {
                    implicitWidth: expandBtn.implicitWidth + Tokens.padding.large
                    implicitHeight: groupCount.implicitHeight + Tokens.padding.extraSmall

                    color: root.urgency === NotificationUrgency.Critical ? Colours.palette.m3error : Colours.layer(Colours.palette.m3surfaceContainerHigh, 3)
                    radius: Tokens.rounding.full

                    StateLayer {
                        color: root.urgency === NotificationUrgency.Critical ? Colours.palette.m3onError : Colours.palette.m3onSurface
                        onClicked: root.toggleExpand(!root.expanded)
                    }

                    RowLayout {
                        id: expandBtn

                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            id: groupCount

                            Layout.leftMargin: Tokens.padding.extraSmall / 2
                            animate: true
                            text: root.notifCount
                            color: root.urgency === NotificationUrgency.Critical ? Colours.palette.m3onError : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                        }

                        MaterialIcon {
                            Layout.rightMargin: -Tokens.padding.extraSmall / 2
                            text: "expand_more"
                            color: root.urgency === NotificationUrgency.Critical ? Colours.palette.m3onError : Colours.palette.m3onSurfaceVariant
                            rotation: root.expanded ? 180 : 0
                            Layout.topMargin: root.expanded ? -Math.floor(Tokens.padding.extraSmall) : 0

                            Behavior on rotation {
                                Anim {}
                            }

                            Behavior on Layout.topMargin {
                                Anim {}
                            }
                        }
                    }
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
