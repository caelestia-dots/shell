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

    readonly property list<var> notifs: [...modelData.notifs]
    readonly property string image: modelData.image
    readonly property string appIcon: modelData.icon
    readonly property int urgency: modelData.urgency

    property bool expanded

    Component.onCompleted: modelData.ref(this)

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: content.implicitHeight + Tokens.padding.medium * 2

    clip: true
    radius: Tokens.rounding.large
    color: root.urgency === NotifData.Critical ? Colours.palette.secondaryContainer : Colours.layer(Colours.palette.surfaceContainerHigh, 2)

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
                    colour: root.urgency === NotifData.Critical ? Colours.palette.onError : root.urgency === NotifData.Low ? Colours.palette.onSurface : Colours.palette.onSecondaryContainer
                    layer.enabled: root.appIcon.endsWith("symbolic")
                }
            }

            Component {
                id: materialIconComp

                MaterialIcon {
                    text: Icons.getNotifIcon(root.notifs[0]?.summary, root.urgency)
                    color: root.urgency === NotifData.Critical ? Colours.palette.onError : root.urgency === NotifData.Low ? Colours.palette.onSurface : Colours.palette.onSecondaryContainer
                    fontStyle: Tokens.font.icon.large
                }
            }

            ClipRect {
                anchors.fill: parent
                color: root.urgency === NotifData.Critical ? Colours.palette.error : root.urgency === NotifData.Low ? Colours.layer(Colours.palette.surfaceContainerHighest, 3) : Colours.palette.secondaryContainer
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

                    color: root.urgency === NotifData.Critical ? Colours.palette.error : root.urgency === NotifData.Low ? Colours.palette.surfaceContainerHighest : Colours.palette.secondaryContainer
                    radius: Tokens.rounding.full

                    ColouredIcon {
                        anchors.centerIn: parent
                        implicitSize: Math.round(Tokens.sizes.notifs.badge * 0.6)
                        source: Quickshell.iconPath(root.appIcon)
                        colour: root.urgency === NotifData.Critical ? Colours.palette.onError : root.urgency === NotifData.Low ? Colours.palette.onSurface : Colours.palette.onSecondaryContainer
                        layer.enabled: root.appIcon.endsWith("symbolic")
                    }
                }
            }
        }

        ColumnLayout {
            Layout.topMargin: -Tokens.padding.extraSmall
            Layout.bottomMargin: -Tokens.padding.extraSmall / 2 - (root.expanded ? 0 : spacing)
            Layout.fillWidth: true
            spacing: Math.round(Tokens.spacing.extraSmall)

            RowLayout {
                Layout.bottomMargin: -parent.spacing
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

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

                    color: root.urgency === NotifData.Critical ? Colours.palette.error : Colours.layer(Colours.palette.surfaceContainerHighest, 2)
                    radius: Tokens.rounding.full

                    opacity: root.notifs.length > Config.notifs.groupPreviewNum ? 1 : 0
                    Layout.preferredWidth: root.notifs.length > Config.notifs.groupPreviewNum ? implicitWidth : 0

                    StateLayer {
                        color: root.urgency === NotifData.Critical ? Colours.palette.onError : Colours.palette.onSurface
                        onClicked: root.expanded = !root.expanded
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
                            color: root.urgency === NotifData.Critical ? Colours.palette.onError : Colours.palette.onSurface
                            font: Tokens.font.body.small
                        }

                        MaterialIcon {
                            Layout.rightMargin: -Tokens.padding.extraSmall / 2
                            animate: true
                            text: root.expanded ? "expand_less" : "expand_more"
                            color: root.urgency === NotifData.Critical ? Colours.palette.onError : Colours.palette.onSurface
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    Behavior on Layout.preferredWidth {
                        Anim {}
                    }
                }
            }

            Repeater {
                model: ScriptModel {
                    values: root.notifs.slice(0, root.Config.notifs.groupPreviewNum) as Array
                }

                NotifLine {
                    id: notif

                    ParallelAnimation {
                        running: true

                        Anim {
                            type: Anim.DefaultEffects
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
                            values: root.notifs.slice(root.Config.notifs.groupPreviewNum) as Array
                        }

                        NotifLine {}
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }

    component NotifLine: StyledText {
        id: notifLine

        required property NotifData modelData

        Layout.fillWidth: true
        textFormat: Text.MarkdownText
        text: {
            const summary = modelData.summary.replace(/\n/g, " ");
            const body = modelData.body.replace(/\n/g, " ");
            const colour = root.urgency === NotifData.Critical ? Colours.palette.secondary : Colours.palette.outline;

            if (metrics.text === metrics.elidedText)
                return `${summary} <span style='color:${colour}'>${body}</span>`;

            const t = metrics.elidedText.length - 3;
            if (t < summary.length)
                return `${summary.slice(0, t)}...`;

            return `${summary} <span style='color:${colour}'>${body.slice(0, t - summary.length)}...</span>`;
        }
        color: root.urgency === NotifData.Critical ? Colours.palette.onSecondaryContainer : Colours.palette.onSurface

        Component.onCompleted: modelData.ref(this)

        TextMetrics {
            id: metrics

            text: `${notifLine.modelData.summary} ${notifLine.modelData.body}`.replace(/\n/g, " ")
            font: notifLine.font
            elideWidth: notifLine.width
            elide: Text.ElideRight
        }
    }
}
