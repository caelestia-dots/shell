pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

StyledRect {
    id: root

    required property string modelData

    readonly property list<var> notifs: Notifs.list.filter(notif => notif.appName === modelData)
    readonly property var props: {
        let img = "";
        let icon = "";
        let hasCritical = false;
        let hasNormal = false;
        for (const n of notifs) {
            if (!img && n.image.length > 0)
                img = n.image;
            if (!icon && n.appIcon.length > 0)
                icon = n.appIcon;
            if (n.urgency === NotificationUrgency.Critical)
                hasCritical = true;
            else if (n.urgency === NotificationUrgency.Normal)
                hasNormal = true;
        }
        return {
            img,
            icon,
            urgency: hasCritical ? "critical" : hasNormal ? "normal" : "low"
        };
    }
    readonly property string image: props.img
    readonly property string appIcon: props.icon
    readonly property string urgency: props.urgency

    property bool expanded

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: content.implicitHeight + Tokens.padding.normal * 2

    clip: true
    radius: Tokens.rounding.normal
    color: root.urgency === "critical" ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)

    RowLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.normal

        spacing: Tokens.spacing.normal

        Item {
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            implicitWidth: TokenConfig.sizes.notifs.image
            implicitHeight: TokenConfig.sizes.notifs.image

            Component {
                id: imageComp

                Image {
                    source: Qt.resolvedUrl(root.image)
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: TokenConfig.sizes.notifs.image
                    sourceSize.height: TokenConfig.sizes.notifs.image
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
                    colour: root.urgency === "critical" ? Colours.palette.m3onError : root.urgency === "low" ? Colours.palette.m3onSurface : Colours.palette.m3onSecondaryContainer
                    layer.enabled: root.appIcon.endsWith("symbolic")
                }
            }

            Component {
                id: materialIconComp

                MaterialIcon {
                    text: Icons.getNotifIcon(root.notifs[0]?.summary, root.urgency)
                    color: root.urgency === "critical" ? Colours.palette.m3onError : root.urgency === "low" ? Colours.palette.m3onSurface : Colours.palette.m3onSecondaryContainer
                    font.pointSize: Tokens.font.size.large
                }
            }

            ClippingRectangle {
                anchors.fill: parent
                color: root.urgency === "critical" ? Colours.palette.m3error : root.urgency === "low" ? Colours.layer(Colours.palette.m3surfaceContainerHighest, 3) : Colours.palette.m3secondaryContainer
                radius: Tokens.rounding.full

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
                    implicitWidth: Tokens.sizes.notifs.badge
                    implicitHeight: Tokens.sizes.notifs.badge

                    color: root.urgency === "critical" ? Colours.palette.m3error : root.urgency === "low" ? Colours.palette.m3surfaceContainerHighest : Colours.palette.m3secondaryContainer
                    radius: Tokens.rounding.full

                    ColouredIcon {
                        anchors.centerIn: parent
                        implicitSize: Math.round(Tokens.sizes.notifs.badge * 0.6)
                        source: Quickshell.iconPath(root.appIcon)
                        colour: root.urgency === "critical" ? Colours.palette.m3onError : root.urgency === "low" ? Colours.palette.m3onSurface : Colours.palette.m3onSecondaryContainer
                        layer.enabled: root.appIcon.endsWith("symbolic")
                    }
                }
            }
        }

        ColumnLayout {
            Layout.topMargin: -Tokens.padding.small
            Layout.bottomMargin: -Tokens.padding.small / 2 - (root.expanded ? 0 : spacing)
            Layout.fillWidth: true
            spacing: Math.round(Tokens.spacing.small / 2)

            RowLayout {
                Layout.bottomMargin: -parent.spacing
                Layout.fillWidth: true
                spacing: Tokens.spacing.smaller

                StyledText {
                    Layout.fillWidth: true
                    text: root.modelData
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Tokens.font.size.small
                    elide: Text.ElideRight
                }

                StyledText {
                    animate: true
                    text: root.notifs[0]?.timeStr ?? ""
                    color: Colours.palette.m3outline
                    font.pointSize: Tokens.font.size.small
                }

                StyledRect {
                    implicitWidth: expandBtn.implicitWidth + Tokens.padding.smaller * 2
                    implicitHeight: groupCount.implicitHeight + Tokens.padding.small

                    color: root.urgency === "critical" ? Colours.palette.m3error : Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
                    radius: Tokens.rounding.full

                    opacity: root.notifs.length > Config.notifs.groupPreviewNum ? 1 : 0
                    Layout.preferredWidth: root.notifs.length > Config.notifs.groupPreviewNum ? implicitWidth : 0

                    StateLayer {
                        color: root.urgency === "critical" ? Colours.palette.m3onError : Colours.palette.m3onSurface
                        onClicked: root.expanded = !root.expanded
                    }

                    RowLayout {
                        id: expandBtn

                        anchors.centerIn: parent
                        spacing: Tokens.spacing.small / 2

                        StyledText {
                            id: groupCount

                            Layout.leftMargin: Tokens.padding.small / 2
                            animate: true
                            text: root.notifs.length
                            color: root.urgency === "critical" ? Colours.palette.m3onError : Colours.palette.m3onSurface
                            font.pointSize: Tokens.font.size.small
                        }

                        MaterialIcon {
                            Layout.rightMargin: -Tokens.padding.small / 2
                            animate: true
                            text: root.expanded ? "expand_less" : "expand_more"
                            color: root.urgency === "critical" ? Colours.palette.m3onError : Colours.palette.m3onSurface
                        }
                    }

                    Behavior on opacity {
                        Anim {}
                    }

                    Behavior on Layout.preferredWidth {
                        Anim {}
                    }
                }
            }

            Repeater {
                model: ScriptModel {
                    values: root.notifs.slice(0, root.Config.notifs.groupPreviewNum)
                }

                NotifLine {
                    id: notif

                    ParallelAnimation {
                        running: true

                        Anim {
                            target: notif
                            property: "opacity"
                            from: 0
                            to: 1
                        }
                        Anim {
                            target: notif
                            property: "scale"
                            from: 0.7
                            to: 1
                        }
                        Anim {
                            target: notif.Layout
                            property: "preferredHeight"
                            from: 0
                            to: notif.implicitHeight
                        }
                    }

                    ParallelAnimation {
                        running: notif.modelData.closed
                        onFinished: notif.modelData.unlock(notif)

                        Anim {
                            target: notif
                            property: "opacity"
                            to: 0
                        }
                        Anim {
                            target: notif
                            property: "scale"
                            to: 0.7
                        }
                        Anim {
                            target: notif.Layout
                            property: "preferredHeight"
                            to: 0
                        }
                    }
                }
            }

            Loader {
                asynchronous: true
                Layout.fillWidth: true

                opacity: root.expanded ? 1 : 0
                Layout.preferredHeight: root.expanded ? implicitHeight : 0
                active: opacity > 0

                sourceComponent: ColumnLayout {
                    Repeater {
                        model: ScriptModel {
                            values: root.notifs.slice(root.Config.notifs.groupPreviewNum)
                        }

                        NotifLine {}
                    }
                }

                Behavior on opacity {
                    Anim {}
                }
            }
        }
    }

    Behavior on implicitHeight {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    component NotifLine: StyledText {
        id: notifLine

        required property NotifData modelData

        Layout.fillWidth: true
        textFormat: Text.MarkdownText
        text: {
            const summary = modelData.summary.replace(/\n/g, " ");
            const body = modelData.body.replace(/\n/g, " ");
            const colour = root.urgency === "critical" ? Colours.palette.m3secondary : Colours.palette.m3outline;

            if (metrics.text === metrics.elidedText)
                return `${summary} <span style='color:${colour}'>${body}</span>`;

            const t = metrics.elidedText.length - 3;
            if (t < summary.length)
                return `${summary.slice(0, t)}...`;

            return `${summary} <span style='color:${colour}'>${body.slice(0, t - summary.length)}...</span>`;
        }
        color: root.urgency === "critical" ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface

        Component.onCompleted: modelData.lock(this)
        Component.onDestruction: modelData.unlock(this)

        TextMetrics {
            id: metrics

            text: `${notifLine.modelData.summary} ${notifLine.modelData.body}`.replace(/\n/g, " ")
            font.pointSize: notifLine.font.pointSize
            font.family: notifLine.font.family
            elideWidth: notifLine.width
            elide: Text.ElideRight
        }
    }
}
