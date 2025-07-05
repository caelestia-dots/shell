pragma ComponentBehavior: Bound

import "root:/widgets"
import "root:/services"
import "root:/config"
import "root:/utils"
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property Notifs.Notif modelData
    readonly property bool hasImage: modelData.image.length > 0
    readonly property bool hasAppIcon: modelData.appIcon.length > 0
    readonly property int nonAnimHeight: Math.max(image.height, details.implicitHeight) + Appearance.padding.normal * 2

    color: root.modelData.urgency === NotificationUrgency.Critical ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainer
    radius: Appearance.rounding.normal
    implicitWidth: Config.notifs.sizes.width

    Component.onCompleted: implicitHeight = Qt.binding(() => nonAnimHeight)

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }

    Behavior on x {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }

    RetainableLock {
        object: root.modelData.notification
        locked: true
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: pressed ? Qt.ClosedHandCursor : undefined
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        preventStealing: true

        onEntered: root.modelData.timer.stop()
        onExited: root.modelData.timer.start()

        drag.target: parent
        drag.axis: Drag.XAxis

        onPressed: event => {
            if (event.button === Qt.MiddleButton)
                root.modelData.notification.dismiss();
        }
        onReleased: event => {
            if (Math.abs(root.x) < Config.notifs.sizes.width * Config.notifs.clearThreshold)
                root.x = 0;
            else
                root.modelData.notification.dismiss(); // TODO: change back to popup when notif dock impled
        }
    }

    Loader {
        id: image

        active: root.hasImage
        asynchronous: true

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Appearance.padding.normal

        width: Config.notifs.sizes.image
        height: Config.notifs.sizes.image
        visible: root.hasImage || root.hasAppIcon

        sourceComponent: ClippingRectangle {
            radius: Appearance.rounding.full
            implicitWidth: Config.notifs.sizes.image
            implicitHeight: Config.notifs.sizes.image

            Image {
                anchors.fill: parent
                source: Qt.resolvedUrl(root.modelData.image)
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
            }
        }
    }

    Loader {
        id: appIcon

        active: root.hasAppIcon || !root.hasImage
        asynchronous: true

        anchors.horizontalCenter: root.hasImage ? undefined : image.horizontalCenter
        anchors.verticalCenter: root.hasImage ? undefined : image.verticalCenter
        anchors.right: root.hasImage ? image.right : undefined
        anchors.bottom: root.hasImage ? image.bottom : undefined

        sourceComponent: StyledRect {
            radius: Appearance.rounding.full
            color: root.modelData.urgency === NotificationUrgency.Critical ? Colours.palette.m3error : root.modelData.urgency === NotificationUrgency.Low ? Colours.palette.m3surfaceContainerHighest : Colours.palette.m3tertiaryContainer
            implicitWidth: root.hasImage ? Config.notifs.sizes.badge : Config.notifs.sizes.image
            implicitHeight: root.hasImage ? Config.notifs.sizes.badge : Config.notifs.sizes.image

            Loader {
                id: icon

                active: root.hasAppIcon
                asynchronous: true

                anchors.centerIn: parent

                width: Math.round(parent.width * 0.6)
                height: Math.round(parent.width * 0.6)

                sourceComponent: IconImage {
                    anchors.fill: parent
                    source: Quickshell.iconPath(root.modelData.appIcon)
                    asynchronous: true

                    layer.enabled: root.modelData.appIcon.endsWith("symbolic")
                    layer.effect: Colouriser {
                        colorizationColor: root.modelData.urgency === NotificationUrgency.Critical ? Colours.palette.m3onError : root.modelData.urgency === NotificationUrgency.Low ? Colours.palette.m3onSurface : Colours.palette.m3onTertiaryContainer
                    }
                }
            }

            Loader {
                active: !root.hasAppIcon
                asynchronous: true
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -Appearance.font.size.large * 0.02
                anchors.verticalCenterOffset: Appearance.font.size.large * 0.02

                sourceComponent: MaterialIcon {
                    text: Icons.getNotifIcon(root.modelData.summary.toLowerCase(), root.modelData.urgency)

                    color: root.modelData.urgency === NotificationUrgency.Critical ? Colours.palette.m3onError : root.modelData.urgency === NotificationUrgency.Low ? Colours.palette.m3onSurface : Colours.palette.m3onTertiaryContainer
                    font.pointSize: Appearance.font.size.large
                }
            }
        }
    }

    ColumnLayout {
        id: details

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: image.right
        anchors.right: parent.right
        anchors.leftMargin: Appearance.spacing.smaller
        anchors.rightMargin: Appearance.padding.larger

        spacing: 0

        RowLayout {
            Layout.fillWidth: true

            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                Layout.maximumWidth: implicitWidth

                animate: true
                text: root.modelData.summary
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            StyledText {
                text: "•"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
            }

            StyledText {
                animate: true
                text: root.modelData.timeStr
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
            }
        }

        StyledText {
            Layout.fillWidth: true

            animate: true
            text: root.modelData.body
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.small
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
