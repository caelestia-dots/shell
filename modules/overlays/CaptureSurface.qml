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
import qs.components.controls

Item {
    id: root

    required property CaptureState cState
    required property ShellScreen screen
    required property real contentOpacity
    property alias session: capture.session
    property bool hideToolbar
    property real toolbarOpacity: showToolbar ? 1 : 0
    property real submenuOpacity: showToolbar && cState.annotating && annotation.document.tool !== AnnotationDocument.Select ? 1 : 0
    property bool toolbarBottom
    readonly property bool wantsToolbarBottom: {
        if (!cState.annotating)
            return false;

        const r = cState.region;
        const overlaps = (w, y, h) => {
            const x = screen.x + (width - w) / 2;
            return r.x < x + w && r.x + r.width > x && r.y < y + h && r.y + r.height > y;
        };

        if (overlaps(toolbar.implicitWidth, screen.y, toolbar.implicitHeight))
            return true;
        if (annotation.document.tool === AnnotationDocument.Select)
            return false;
        return overlaps(submenuContent.implicitWidth + Tokens.padding.small * 2, screen.y + toolbar.implicitHeight, submenuContent.implicitHeight + Tokens.padding.small * 2);
    }
    readonly property bool regionOnScreen: {
        if (!cState.annotating)
            return true;

        const r = cState.region;
        return r.x < screen.x + width && r.x + r.width > screen.x && r.y < screen.y + height && r.y + r.height > screen.y;
    }
    readonly property bool showToolbar: cState.open && !hideToolbar && regionOnScreen
    property bool moveModifier
    property bool picking: submenuContent.picking !== null

    readonly property real toolbarY: {
        const open = showToolbar && !cState.selection.selecting;
        if (toolbarBottom)
            return open ? height - toolbarBg.height : height + 10;
        return open ? 0 : -toolbarBg.height - 10;
    }

    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Control)
            moveModifier = true;
        if (annotation.handleKey(event) || event.key !== Qt.Key_Escape)
            return;
        if (picking)
            submenuContent.picking = null;
        else
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

    Behavior on toolbarOpacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    Behavior on submenuOpacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    Behavior on picking {
        SequentialAnimation {
            PropertyAction {
                target: submenuAnim
                property: "type"
                value: Anim.DefaultSpatial
            }
            PropertyAction {
                target: submenuBg
                property: "deformScale"
                value: 0.00002 * root.Config.appearance.deformScale
            }
            PropertyAction {}
            PauseAnimation {
                duration: Tokens.anim.durations.expressiveDefaultSpatial
            }
            PropertyAction {
                target: submenuBg
                property: "deformScale"
                value: 0.00005 * root.Config.appearance.deformScale
            }
            PropertyAction {
                target: submenuAnim
                property: "type"
                value: toolbarAnim.type
            }
        }
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
                targets: [toolbarBehaviour, submenuBehaviour]
                property: "enabled"
                value: false
            }
            PropertyAction {}
            PropertyAction {
                targets: [toolbarBehaviour, submenuBehaviour]
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

    Binding {
        target: root
        property: "toolbarBottom"
        value: root.wantsToolbarBottom
        when: !root.picking
        restoreMode: Binding.RestoreNone
    }

    Item {
        id: captureContent

        anchors.fill: parent
        opacity: root.contentOpacity

        ScreenCapture {
            id: capture

            anchors.fill: parent
        }

        Annotation {
            id: annotation

            anchors.fill: parent
            active: root.cState.annotating
            document: capture.session.document
            screen: root.screen
            base: capture.image
        }
    }

    RegionSelect {
        anchors.fill: parent
        opacity: root.contentOpacity
        selection: root.cState.selection
        source: captureContent
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

        onSelected: region => {
            if (root.cState.annotate)
                root.cState.annotating = true;
            else
                capture.session.save(region);
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: root.picking
        enabled: root.picking
        onClicked: submenuContent.picking = null
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
            y: root.toolbarY

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

        BlobRect {
            id: submenuBg

            group: root.cState.annotating ? group : null
            anchors.horizontalCenter: parent.horizontalCenter
            y: {
                const h = submenu.implicitHeight;
                if (root.picking)
                    return (root.height - h) / 2;

                const open = root.showToolbar && root.cState.annotating && annotation.document.tool !== AnnotationDocument.Select;
                if (root.toolbarBottom)
                    return open ? root.toolbarY - h : root.toolbarY + toolbarBg.height / 2;
                return open ? root.toolbarY + toolbarBg.height : root.toolbarY + toolbarBg.height / 2 - h;
            }

            radius: root.picking ? Tokens.rounding.extraLarge : Tokens.rounding.extraExtraLarge
            implicitWidth: submenu.implicitWidth
            implicitHeight: submenu.implicitHeight

            deformScale: 0.00005 * Config.appearance.deformScale

            Behavior on y {
                id: submenuBehaviour

                Anim {
                    id: submenuAnim

                    type: toolbarAnim.type
                }
            }

            Behavior on implicitHeight {
                Anim {}
            }

            Behavior on radius {
                Anim {
                    type: Anim.DefaultEffects
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

        opacity: root.contentOpacity * root.toolbarOpacity
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

    MouseArea {
        id: submenu

        readonly property Item content: root.picking ? (picker.item ?? submenuContent) : submenuContent
        readonly property real fullHeight: content.implicitHeight + Tokens.padding.small * 2
        readonly property real toolbarEdge: root.toolbarBottom ? toolbarBg.y : toolbarBg.y + toolbarBg.height
        readonly property real visibleTop: root.toolbarBottom || root.picking ? submenuBg.y : Math.max(submenuBg.y, toolbarEdge)
        readonly property real visibleBottom: root.toolbarBottom && !root.picking ? Math.min(submenuBg.y + fullHeight, toolbarEdge) : submenuBg.y + fullHeight
        readonly property real pivotY: submenuBg.y - y + fullHeight / 2

        x: submenuBg.x
        y: visibleTop

        clip: true
        implicitWidth: content.implicitWidth + Tokens.padding.small * 2
        implicitHeight: fullHeight
        height: Math.max(0, visibleBottom - visibleTop)

        opacity: root.contentOpacity * root.submenuOpacity
        hoverEnabled: true

        transform: [
            Translate {
                x: -submenu.width / 2
                y: -submenu.pivotY
            },
            Matrix4x4 {
                matrix: submenuBg.rawDeformMatrix
            },
            Translate {
                x: submenu.width / 2
                y: submenu.pivotY
            }
        ]

        Behavior on implicitWidth {
            Anim {}
        }

        AnnotationSubmenu {
            id: submenuContent

            anchors.horizontalCenter: parent.horizontalCenter
            y: submenuBg.y - submenu.y + Tokens.padding.small
            document: annotation.document
            customColour: root.cState.customColour
            customBackgroundColour: root.cState.customBackgroundColour
            opacity: root.picking ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Loader {
            id: picker

            anchors.horizontalCenter: parent.horizontalCenter
            y: submenuBg.y - submenu.y + Tokens.padding.small
            active: opacity > 0
            opacity: root.picking ? 1 : 0

            sourceComponent: ColourPicker {
                anchors.centerIn: parent
                onInteraction: c => {
                    const swatches = submenuContent.picking;
                    if (!swatches)
                        return;

                    swatches.selected(c);
                    if (swatches.background)
                        root.cState.customBackgroundColour = c;
                    else
                        root.cState.customColour = c;
                }

                Binding on colour {
                    when: submenuContent.picking !== null
                    value: submenuContent.picking?.selectedColour
                    restoreMode: Binding.RestoreNone
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
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
