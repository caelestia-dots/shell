pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Caelestia.Blobs
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Scheme
import qs.components

Item {
    id: root

    required property CaptureState cState
    required property ShellScreen screen
    required property real contentOpacity
    property alias session: capture.session
    property bool hideToolbar
    property bool toolbarBottom: cState.annotating && cState.region.y - screen.y < toolbar.implicitHeight
    property bool moveModifier

    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Control)
            moveModifier = true;
        if (!annotation.handleKey(event) && event.key === Qt.Key_Escape)
            cState.cancelled();
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Control)
            moveModifier = false;
    }
    onActiveFocusChanged: {
        if (!activeFocus)
            moveModifier = false;
    }

    Behavior on toolbarBottom {
        SequentialAnimation {
            PropertyAction {
                target: root
                property: "hideToolbar"
                value: true
            }
            PauseAnimation {
                duration: toolbarAnim.duration
            }
            PropertyAction {
                target: toolbarBehaviour
                property: "enabled"
                value: false
            }
            PropertyAction {}
            PropertyAction {
                target: toolbarBehaviour
                property: "enabled"
                value: true
            }
            PropertyAction {
                target: root
                property: "hideToolbar"
                value: false
            }
        }
    }

    ScreenCapture {
        id: capture

        anchors.fill: parent
        opacity: root.contentOpacity
    }

    Annotation {
        id: annotation

        anchors.fill: parent
        opacity: root.contentOpacity
        active: root.cState.annotating
        document: capture.session.document
        screen: root.screen
        base: capture.image
    }

    // TODO: add sub toolbar for tool config

    RegionSelect {
        id: regionSelect

        anchors.fill: parent
        opacity: root.contentOpacity
        screen: root.screen
        freeze: true
        resizeMode: root.cState.annotating
        cursorShape: {
            if (!root.cState.annotating)
                return Qt.CrossCursor;
            if (root.moveModifier)
                return Qt.SizeAllCursor;
            return annotation.cursorShape;
        }
        selectClients: root.cState.selectClients
        showCrosshair: root.cState.showCrosshair

        onSelected: r => {
            const region = Qt.rect(r.x + screen.x, r.y + screen.y, r.width, r.height);
            if (root.cState.annotate) {
                root.cState.region = region;
                root.cState.annotating = true;
            } else {
                capture.session.save(region);
            }
        }

        onResized: r => root.cState.region = Qt.rect(r.x + screen.x, r.y + screen.y, r.width, r.height)
    }

    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha("black", 0.4)
        }

        BlobGroup {
            id: group

            smoothing: root.Tokens.rounding.extraLargeIncreased
            color: Colours.palette.secondaryContainer

            Behavior on color {
                CAnim {}
            }
        }

        BlobInvertedRect {
            group: group
            anchors.fill: parent
        }

        BlobRect {
            id: toolbarBg

            group: group
            anchors.horizontalCenter: parent.horizontalCenter
            y: {
                const open = root.cState.open && !root.hideToolbar && !regionSelect.selecting;
                if (root.toolbarBottom)
                    return open ? root.height - height : root.height + 10;
                return open ? 0 : -height - 10;
            }

            radius: Tokens.rounding.extraExtraLarge
            implicitWidth: toolbar.implicitWidth
            implicitHeight: toolbar.implicitHeight

            deformScale: 0.00005 * Config.appearance.deformScale

            Behavior on y {
                id: toolbarBehaviour

                Anim {
                    id: toolbarAnim

                    type: Anim.SlowEffects
                }
            }
        }
    }

    MouseArea {
        id: toolbar

        x: toolbarBg.x
        y: toolbarBg.y

        clip: true
        implicitWidth: toolbarContent.implicitWidth + Tokens.padding.small * 2
        implicitHeight: toolbarContent.implicitHeight + Tokens.padding.small * 2

        opacity: root.contentOpacity
        hoverEnabled: true

        transform: Matrix4x4 {
            matrix: toolbarBg.deformMatrix
        }

        onImplicitWidthChanged: {
            if (toolbarContent.status === Loader.Ready)
                toolbarWidthAnim.enabled = true;
        }

        Behavior on implicitWidth {
            id: toolbarWidthAnim

            enabled: false

            Anim {}
        }

        Loader {
            id: toolbarContent

            anchors.centerIn: parent
            asynchronous: true
            sourceComponent: root.cState.annotating ? annotateToolbar : regionToolbar
        }
    }

    Component {
        id: regionToolbar

        RowLayout {
            spacing: Tokens.spacing.medium

            MaterialIcon {
                id: topIcon

                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Tokens.padding.medium
                text: "screenshot_region"
                color: Colours.palette.onSecondaryContainer
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: Tr.tr("Drag to select a region")
                color: Colours.palette.onSecondaryContainer
                font: Tokens.font.body.medium
            }

            ButtonRow {
                spacing: Tokens.spacing.extraSmall

                ToolbarButton {
                    isToggle: true
                    checked: root.cState.showCrosshair
                    icon: "my_location"
                    onClicked: root.cState.showCrosshair = !root.cState.showCrosshair
                }

                ToolbarButton {
                    isToggle: true
                    checked: root.cState.selectClients
                    icon: "select_window_2"
                    onClicked: root.cState.selectClients = !root.cState.selectClients
                }

                ToolbarButton {
                    icon: "close"
                    onClicked: root.cState.cancelled()
                }
            }
        }
    }

    Component {
        id: annotateToolbar

        AnnotationToolbar {
            annotation: annotation
            onSaved: capture.session.save(root.cState.region)
            onCopied: capture.session.copy(root.cState.region)
            onCancelled: root.cState.cancelled()
        }
    }
}
