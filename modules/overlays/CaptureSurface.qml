pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Caelestia.Blobs
import Caelestia.Components
import Caelestia.Config
import Caelestia.Scheme
import qs.components
import qs.components.annotation
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
    readonly property real submenuHeight: submenuContent.implicitHeight + Tokens.padding.small * 2
    readonly property bool topOccluded: occluded(screen.y, screen.y + toolbar.implicitHeight)
    readonly property bool bottomOccluded: occluded(screen.y + height - toolbar.implicitHeight, screen.y + height - toolbar.implicitHeight - submenuHeight)
    readonly property bool wantsToolbarBottom: topOccluded === bottomOccluded ? topOccluded && toolbarBottom : topOccluded

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

    function occluded(toolbarY: real, submenuY: real): bool {
        if (!cState.annotating || height <= 0)
            return false;

        const r = cState.region;
        const overlaps = (w, y, h) => {
            const x = screen.x + (width - w) / 2;
            return r.x < x + w && r.x + r.width > x && r.y < y + h && r.y + r.height > y;
        };

        if (overlaps(toolbar.implicitWidth, toolbarY, toolbar.implicitHeight))
            return true;
        if (annotation.document.tool === AnnotationDocument.Select)
            return false;
        return overlaps(submenuContent.implicitWidth + Tokens.padding.small * 2, submenuY, submenuHeight);
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
        origin: Qt.point(root.screen.x, root.screen.y)
        base: capture.image
    }

    RegionSelect {
        anchors.fill: parent
        opacity: root.contentOpacity
        selection: root.cState.selection
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
                const h = submenu.fullHeight;
                if (root.picking)
                    return (root.height - h) / 2;

                const open = root.showToolbar && root.cState.annotating && annotation.document.tool !== AnnotationDocument.Select;
                if (root.toolbarBottom)
                    return open ? root.toolbarY - h : root.toolbarY + toolbarBg.height / 2;
                return open ? root.toolbarY + toolbarBg.height : root.toolbarY + toolbarBg.height / 2 - h;
            }

            radius: root.picking ? Tokens.rounding.extraLarge : Tokens.rounding.extraExtraLarge
            implicitWidth: submenu.implicitWidth
            implicitHeight: submenu.fullHeight

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
        readonly property real visibleBottom: root.toolbarBottom && !root.picking ? Math.min(submenuBg.y + submenuBg.height, toolbarEdge) : submenuBg.y + submenuBg.height
        readonly property real pivotY: submenuBg.y - y + submenuBg.height / 2

        x: submenuBg.x
        y: visibleTop

        clip: true
        implicitWidth: content.implicitWidth + Tokens.padding.small * 2
        implicitHeight: submenuBg.height
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

        RegionToolbar {
            rState: root.cState.selection
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
