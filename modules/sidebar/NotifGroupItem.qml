pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Models
import Caelestia.Scheme
import qs.components
import qs.components.effects
import qs.utils

StyledRect {
    id: root

    required property NotifGroup modelData
    required property Props props
    required property Flickable container
    required property ScreenState screenState

    readonly property list<var> notifs: [...modelData.notifs]

    readonly property int nonAnimHeight: {
        const headerHeight = header.implicitHeight + (root.expanded ? Math.round(Tokens.spacing.extraSmall) : 0);
        const columnHeight = headerHeight + notifList.layoutHeight;
        return Math.round(Math.max(TokenConfig.sizes.notifs.image, columnHeight) + Tokens.padding.medium * 2);
    }
    readonly property bool expanded: props.expandedNotifs.includes(modelData.appName)

    function toggleExpand(expand: bool): void {
        if (expand) {
            if (!expanded)
                props.expandedNotifs.push(modelData.appName);
        } else if (expanded) {
            props.expandedNotifs.splice(props.expandedNotifs.indexOf(modelData.appName), 1);
        }
    }

    Component.onDestruction: {
        if (notifs.length === 0 && expanded)
            props.expandedNotifs.splice(props.expandedNotifs.indexOf(modelData.appName), 1);
    }

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: nonAnimHeight

    clip: true
    radius: Tokens.rounding.large
    color: Colours.layer(Colours.palette.surfaceContainer, 2)

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
                    source: Qt.resolvedUrl(root.modelData.image)
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
                    source: Quickshell.iconPath(root.modelData.icon)
                    colour: root.modelData.urgency === NotifData.Critical ? Colours.palette.onError : root.modelData.urgency === NotifData.Low ? Colours.palette.onSurface : Colours.palette.onSecondaryContainer
                    layer.enabled: root.modelData.icon.endsWith("symbolic")
                }
            }

            Component {
                id: materialIconComp

                MaterialIcon {
                    text: Icons.getNotifIcon(root.notifs[0]?.summary, root.modelData.urgency)
                    color: root.modelData.urgency === NotifData.Critical ? Colours.palette.onError : root.modelData.urgency === NotifData.Low ? Colours.palette.onSurface : Colours.palette.onSecondaryContainer
                    fontStyle: Tokens.font.icon.medium
                }
            }

            ClipRect {
                anchors.fill: parent
                color: root.modelData.urgency === NotifData.Critical ? Colours.palette.error : root.modelData.urgency === NotifData.Low ? Colours.layer(Colours.palette.surfaceContainerHigh, 3) : Colours.palette.secondaryContainer
                radius: Tokens.rounding.full

                Loader {
                    asynchronous: true
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: sourceComponent === materialIconComp ? 1 : 0
                    sourceComponent: root.modelData.image ? imageComp : root.modelData.icon ? appIconComp : materialIconComp
                }
            }

            Loader {
                asynchronous: true
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                active: root.modelData.icon && root.modelData.image

                sourceComponent: StyledRect {
                    implicitWidth: Tokens.sizes.notifs.badge
                    implicitHeight: Tokens.sizes.notifs.badge

                    color: root.modelData.urgency === NotifData.Critical ? Colours.palette.error : root.modelData.urgency === NotifData.Low ? Colours.palette.surfaceContainerHigh : Colours.palette.secondaryContainer
                    radius: Tokens.rounding.full

                    ColouredIcon {
                        anchors.centerIn: parent
                        implicitSize: Math.round(Tokens.sizes.notifs.badge * 0.6)
                        source: Quickshell.iconPath(root.modelData.icon)
                        colour: root.modelData.urgency === NotifData.Critical ? Colours.palette.onError : root.modelData.urgency === NotifData.Low ? Colours.palette.onSurface : Colours.palette.onSecondaryContainer
                        layer.enabled: root.modelData.icon.endsWith("symbolic")
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
                    text: root.modelData.appName
                    color: Colours.palette.onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    animate: true
                    text: Tr.trMarked(root.notifs[0]?.timeStr ?? "")
                    color: Colours.palette.outline
                    font: Tokens.font.body.small
                }

                StyledRect {
                    implicitWidth: expandBtn.implicitWidth + Tokens.padding.large
                    implicitHeight: groupCount.implicitHeight + Tokens.padding.extraSmall

                    color: root.modelData.urgency === NotifData.Critical ? Colours.palette.error : Colours.layer(Colours.palette.surfaceContainerHigh, 3)
                    radius: Tokens.rounding.full

                    StateLayer {
                        color: root.modelData.urgency === NotifData.Critical ? Colours.palette.onError : Colours.palette.onSurface
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
                            text: root.notifs.length
                            color: root.modelData.urgency === NotifData.Critical ? Colours.palette.onError : Colours.palette.onSurfaceVariant
                            font: Tokens.font.body.small
                        }

                        MaterialIcon {
                            Layout.rightMargin: -Tokens.padding.extraSmall / 2
                            text: "expand_more"
                            color: root.modelData.urgency === NotifData.Critical ? Colours.palette.onError : Colours.palette.onSurfaceVariant
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
                screenState: root.screenState
                onRequestToggleExpand: expand => root.toggleExpand(expand)
            }
        }
    }
}
