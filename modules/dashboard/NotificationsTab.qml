pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    readonly property list<NotifData> notifs: Notifs.notClosed
    readonly property list<string> groups: {
        const map = new Map();
        for (const n of notifs)
            map.set(n.appName, null);
        return [...map.keys()];
    }

    implicitWidth: 840
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.leftMargin: Tokens.padding.large
            Layout.rightMargin: Tokens.padding.large
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            Column {
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    text: qsTr("Notifications")
                    font: Tokens.font.body.builders.large.size(28).weight(Font.DemiBold).build()
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    text: root.notifs.length === 1 ? qsTr("1 notification") : qsTr("%1 notifications").arg(root.notifs.length)
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            Item {
                Layout.fillWidth: true
            }

            IconButton {
                icon: "do_not_disturb_on"
                type: IconButton.Tonal
                isToggle: true
                checked: Notifs.dnd
                onClicked: Notifs.dnd = !Notifs.dnd
            }

            IconTextButton {
                icon: "clear_all"
                text: qsTr("Clear all")
                type: TextButton.Tonal
                disabled: root.notifs.length === 0
                onClicked: {
                    for (const notif of Notifs.list.slice())
                        notif.close();
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 220
            visible: root.notifs.length === 0

            radius: Tokens.rounding.extraLarge * 2
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: Notifs.dnd ? "do_not_disturb_on" : "notifications_paused"
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).build()
                    color: Colours.palette.m3secondary
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Notifs.dnd ? qsTr("Do not disturb is enabled") : qsTr("All caught up!")
                    font: Tokens.font.body.medium
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        StyledListView {
            id: list

            Layout.fillWidth: true
            implicitHeight: contentHeight > 0 ? Math.min(contentHeight, 560) : 560
            visible: root.notifs.length > 0

            clip: true
            spacing: Tokens.spacing.small

            model: ScriptModel {
                values: [...root.groups]
            }

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: list
            }

            delegate: NotifGroupCard {
                width: list.width
            }

            Behavior on implicitHeight {
                Anim {}
            }
        }
    }

    component NotifGroupCard: StyledRect {
        id: group

        required property string modelData
        property bool expanded

        readonly property list<NotifData> groupNotifs: root.notifs.filter(n => n.appName === group.modelData)
        readonly property int previewNum: Config.notifs.groupPreviewNum
        readonly property bool expandable: groupNotifs.length > previewNum
        readonly property list<NotifData> visibleNotifs: expanded ? groupNotifs : groupNotifs.slice(0, previewNum)
        readonly property bool critical: groupNotifs.some(n => n.urgency === NotificationUrgency.Critical)

        implicitHeight: groupContent.implicitHeight + Tokens.padding.medium * 2

        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: groupContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.medium

            spacing: Tokens.spacing.small

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                spacing: Tokens.spacing.small

                StyledText {
                    text: group.modelData || qsTr("Unknown")
                    font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                    color: Colours.palette.m3onSurface
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    animate: true
                    text: group.groupNotifs[0]?.timeStr ?? ""
                    font: Tokens.font.body.small
                    color: Colours.palette.m3outline
                    elide: Text.ElideRight
                }

                StyledRect {
                    implicitWidth: expandBtn.implicitWidth + Tokens.padding.large
                    implicitHeight: groupCount.implicitHeight + Tokens.padding.extraSmall

                    color: group.critical ? Colours.palette.m3error : Colours.tPalette.m3surfaceContainerHigh
                    radius: Tokens.rounding.full

                    StateLayer {
                        disabled: !group.expandable
                        color: group.critical ? Colours.palette.m3onError : Colours.palette.m3onSurface
                        onClicked: group.expanded = !group.expanded
                    }

                    RowLayout {
                        id: expandBtn

                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            id: groupCount

                            Layout.leftMargin: Tokens.padding.extraSmall / 2
                            animate: true
                            text: group.groupNotifs.length
                            color: group.critical ? Colours.palette.m3onError : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                        }

                        MaterialIcon {
                            Layout.rightMargin: -Tokens.padding.extraSmall / 2
                            visible: group.expandable
                            text: "expand_more"
                            color: group.critical ? Colours.palette.m3onError : Colours.palette.m3onSurfaceVariant
                            rotation: group.expanded ? 180 : 0

                            Behavior on rotation {
                                Anim {}
                            }
                        }
                    }
                }

                IconButton {
                    icon: "close"
                    type: IconButton.Text
                    onClicked: {
                        for (const notif of group.groupNotifs.slice())
                            notif.close();
                    }
                }
            }

            Repeater {
                model: ScriptModel {
                    values: [...group.visibleNotifs]
                }

                NotifCard {
                    Layout.fillWidth: true
                }
            }

            TextButton {
                Layout.alignment: Qt.AlignHCenter
                visible: group.expandable && !group.expanded
                text: qsTr("Show %1 more").arg(group.groupNotifs.length - group.previewNum)
                type: TextButton.Text
                onClicked: group.expanded = true
            }
        }

        Behavior on implicitHeight {
            Anim {}
        }
    }

    component NotifCard: StyledRect {
        id: card

        required property NotifData modelData
        property bool expanded

        readonly property bool hasImage: modelData?.image.length > 0
        readonly property bool hasAppIcon: modelData?.appIcon.length > 0
        readonly property var defaultAction: modelData?.actions.find(a => a.identifier === "default") ?? null

        implicitHeight: content.implicitHeight + Tokens.padding.medium * 2

        radius: Tokens.rounding.medium
        color: modelData?.urgency === NotificationUrgency.Critical ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainerHigh

        MouseArea {
            anchors.fill: parent

            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton

            onClicked: event => {
                if (event.button === Qt.MiddleButton)
                    card.modelData?.close();
                else if (card.defaultAction?.invoke)
                    card.defaultAction.invoke();
                else
                    card.expanded = !card.expanded;
            }
        }

        RowLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.medium

            spacing: Tokens.spacing.medium

            StyledClippingRect {
                Layout.alignment: Qt.AlignTop

                implicitWidth: Tokens.sizes.notifs.badge * 2
                implicitHeight: Tokens.sizes.notifs.badge * 2

                radius: Tokens.rounding.full
                color: card.modelData?.urgency === NotificationUrgency.Critical ? Colours.palette.m3error : Colours.palette.m3secondaryContainer

                Loader {
                    anchors.fill: parent
                    sourceComponent: card.hasImage ? imageComp : card.hasAppIcon ? appIconComp : fallbackIconComp
                }

                Component {
                    id: imageComp

                    Image {
                        source: Qt.resolvedUrl(card.modelData?.image ?? "")
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: {
                            const size = Tokens.sizes.notifs.badge * 2 * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1);
                            return Qt.size(size, size);
                        }
                        cache: false
                        asynchronous: true
                    }
                }

                Component {
                    id: appIconComp

                    IconImage {
                        source: Quickshell.iconPath(card.modelData?.appIcon ?? "", "dialog-information")
                    }
                }

                Component {
                    id: fallbackIconComp

                    MaterialIcon {
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: Icons.getNotifIcon(card.modelData?.summary ?? "", card.modelData?.urgency ?? NotificationUrgency.Normal)
                        color: card.modelData?.urgency === NotificationUrgency.Critical ? Colours.palette.m3onError : Colours.palette.m3onSecondaryContainer
                        fontStyle: Tokens.font.icon.large
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        text: card.modelData?.timeStr ?? ""
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                        elide: Text.ElideRight
                    }

                    IconButton {
                        icon: "close"
                        type: IconButton.Text
                        onClicked: card.modelData?.close()
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: card.modelData?.summary ?? ""
                    font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                    color: card.modelData?.urgency === NotificationUrgency.Critical ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    wrapMode: card.expanded ? Text.WordWrap : Text.NoWrap
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: (card.modelData?.body.length ?? 0) > 0
                    text: card.modelData?.body ?? ""
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                    textFormat: Text.StyledText
                    wrapMode: Text.WordWrap
                    maximumLineCount: card.expanded ? Number.MAX_SAFE_INTEGER : 2
                    elide: Text.ElideRight
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }

                RowLayout {
                    Layout.topMargin: Tokens.spacing.extraSmall
                    visible: (card.modelData?.actions.some(a => a.identifier !== "default") ?? false)
                    spacing: Tokens.spacing.small

                    Repeater {
                        model: card.modelData?.actions.filter(a => a.identifier !== "default") ?? []

                        TextButton {
                            required property var modelData

                            text: modelData.text || qsTr("Open")
                            type: TextButton.Tonal
                            onClicked: modelData.invoke()
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
        }

        Behavior on implicitHeight {
            Anim {}
        }
    }
}
