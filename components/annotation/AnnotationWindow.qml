pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Caelestia.Blobs
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Scheme
import qs.components
import qs.components.controls

FloatingWindow {
    id: root

    required property string file

    property color customColour: Colours.palette.outline
    property color customBackgroundColour: Colours.palette.outlineVariant

    property bool picking: submenuContent.picking !== null
    readonly property bool submenuOpen: document.tool !== AnnotationDocument.Select
    readonly property real borderTop: toolbar.implicitHeight + toolbar.y * 2

    readonly property real initialScale: fitScale(screen.width * 0.8, screen.height * 0.8)
    readonly property real minZoom: fitScale(viewport.width, viewport.height)
    readonly property real maxZoom: 8

    readonly property real zoom: Math.exp(logZoom)
    readonly property real targetZoom: Math.exp(targetLogZoom)
    readonly property point origin: clampedOrigin(Qt.point(anchorDoc.x - anchorViewX / zoom, anchorDoc.y - anchorViewY / zoom), zoom)

    property real logZoom: targetLogZoom
    property real targetLogZoom

    property real anchorViewX: targetAnchorViewX
    property real anchorViewY: targetAnchorViewY
    property real targetAnchorViewX
    property real targetAnchorViewY

    property point anchorDoc
    property bool fitted: true
    property bool instant

    signal saved(path: string)
    signal copied(path: string)
    signal failed
    signal cancelled

    function fitScale(width: real, height: real): real {
        if (loader.implicitWidth <= 0 || loader.implicitHeight <= 0 || width <= 0 || height <= 0)
            return 1;
        return Math.min(1, width / loader.implicitWidth, height / loader.implicitHeight);
    }

    function clampedOrigin(value: point, zoom: real): point {
        return Qt.point(clampAxis(value.x, loader.implicitWidth, viewport.width / zoom), clampAxis(value.y, loader.implicitHeight, viewport.height / zoom));
    }

    function clampAxis(value: real, image: real, view: real): real {
        if (image <= view)
            return (image - view) / 2;
        return Math.max(0, Math.min(value, image - view));
    }

    function setTargetView(x: real, y: real, zoom: real): void {
        const o = clampedOrigin(Qt.point(anchorDoc.x - x / zoom, anchorDoc.y - y / zoom), zoom);
        targetAnchorViewX = (anchorDoc.x - o.x) * zoom;
        targetAnchorViewY = (anchorDoc.y - o.y) * zoom;
    }

    function anchorAt(pos: point): void {
        instant = true;
        anchorDoc = Qt.point(origin.x + pos.x / zoom, origin.y + pos.y / zoom);
        targetAnchorViewX = pos.x;
        targetAnchorViewY = pos.y;
        instant = false;
    }

    function panBy(dx: real, dy: real): void {
        setTargetView(targetAnchorViewX - dx, targetAnchorViewY - dy, targetZoom);
    }

    function setZoom(next: real, pos: point): void {
        anchorAt(pos);
        fitted = next === minZoom;
        targetLogZoom = Math.log(next);
        setTargetView(targetAnchorViewX, targetAnchorViewY, next);
    }

    function zoomAt(pos: point, factor: real): void {
        setZoom(Math.max(minZoom, Math.min(maxZoom, targetZoom * factor)), pos);
    }

    function refit(animate: bool): void {
        instant = !animate;
        setZoom(minZoom, Qt.point(viewport.width / 2, viewport.height / 2));
        instant = false;
    }

    contentItem.Config.screen: screen.name
    contentItem.Tokens.screen: screen.name

    minimumSize.width: toolbar.implicitWidth + contentItem.Tokens.padding.large * 2
    minimumSize.height: borderTop
    implicitWidth: Math.max(loader.implicitWidth * initialScale, toolbar.implicitWidth + contentItem.Tokens.padding.large * 2)
    implicitHeight: loader.implicitHeight * initialScale + borderTop

    color: Colours.tPalette.surface
    surfaceFormat.opaque: false
    title: Tr.tr("Annotate")

    onVisibleChanged: {
        if (!visible)
            cancelled();
    }
    onMinZoomChanged: {
        if (fitted || targetZoom <= minZoom)
            refit(false);
    }

    contentItem.focus: true
    contentItem.Keys.onPressed: event => {
        if (event.key === Qt.Key_0 && event.modifiers & Qt.ControlModifier) {
            refit(true);
            return;
        }

        if (annotation.handleKey(event) || event.key !== Qt.Key_Escape)
            return;

        if (picking)
            submenuContent.picking = null;
        else
            visible = false;
    }

    Behavior on logZoom {
        enabled: !root.instant

        Anim {
            type: Anim.FastEffects
        }
    }

    Behavior on anchorViewX {
        enabled: !root.instant && !panArea.pressed

        Anim {
            type: Anim.FastEffects
        }
    }

    Behavior on anchorViewY {
        enabled: !root.instant && !panArea.pressed

        Anim {
            type: Anim.FastEffects
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
                value: 0.00002 * root.contentItem.Config.appearance.deformScale
            }
            PropertyAction {}
            PauseAnimation {
                duration: Tokens.anim.durations.expressiveDefaultSpatial
            }
            PropertyAction {
                target: submenuBg
                property: "deformScale"
                value: 0.00005 * root.contentItem.Config.appearance.deformScale
            }
            PropertyAction {
                target: submenuAnim
                property: "type"
                value: Anim.SlowEffects
            }
        }
    }

    AnnotationDocument {
        id: document

        font: Tokens.font.body.medium
        color: Colours.palette.primary
        backgroundColor: Colours.palette.surface
        textPadding: TokenConfig.appearance.padding.small
        radius: TokenConfig.appearance.rounding.small
    }

    ImageExporter {
        id: exporter

        onSaved: path => root.saved(path)
        onCopied: path => root.copied(path)
        onSaveFailed: root.failed()
        onCopyFailed: root.failed()
    }

    Item {
        id: viewport

        anchors.fill: parent
        anchors.topMargin: root.borderTop
        clip: true

        ImageLoader {
            id: loader

            anchors.fill: parent
            source: root.file
            sourceRect: Qt.rect(root.origin.x, root.origin.y, width / root.zoom, height / root.zoom)
        }

        Annotation {
            id: annotation

            anchors.fill: parent
            active: true
            document: document
            base: loader.image
            baseRect: Qt.rect(0, 0, loader.implicitWidth, loader.implicitHeight)
            origin: root.origin
            zoom: root.zoom
        }

        MouseArea {
            id: panArea

            property point pressAnchor
            property point pressPos

            anchors.fill: parent
            acceptedButtons: Qt.MiddleButton
            cursorShape: pressed ? Qt.ClosedHandCursor : annotation.cursorShape

            onPressed: event => {
                pressAnchor = Qt.point(root.targetAnchorViewX, root.targetAnchorViewY);
                pressPos = Qt.point(event.x, event.y);
            }
            onPositionChanged: event => root.setTargetView(pressAnchor.x + event.x - pressPos.x, pressAnchor.y + event.y - pressPos.y, root.targetZoom)
            onWheel: event => {
                if (event.modifiers & Qt.ControlModifier) {
                    root.zoomAt(Qt.point(event.x, event.y), Math.pow(1.15, event.angleDelta.y / 120));
                    return;
                }

                if (event.modifiers & Qt.ShiftModifier)
                    root.panBy(-event.angleDelta.y, 0);
                else
                    root.panBy(-event.angleDelta.x, -event.angleDelta.y);
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.picking
            onClicked: submenuContent.picking = null
        }
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

            smoothing: root.contentItem.Tokens.rounding.extraLargeIncreased
            color: Colours.palette.secondaryContainer

            Behavior on color {
                CAnim {}
            }
        }

        BlobInvertedRect {
            group: group
            anchors.fill: parent
            radius: Tokens.rounding.large
            borderTop: root.borderTop
            borderBottom: -radius // Don't show bottom radius
        }

        BlobRect {
            id: submenuBg

            group: group
            anchors.horizontalCenter: parent.horizontalCenter
            y: {
                const h = submenu.fullHeight;
                if (root.picking)
                    return Math.max(root.borderTop, (root.height - h) / 2);
                return root.submenuOpen ? root.borderTop : root.borderTop / 2 - h;
            }

            radius: root.picking ? Tokens.rounding.extraLarge : Tokens.rounding.extraExtraLarge
            implicitWidth: submenu.implicitWidth
            implicitHeight: submenu.fullHeight

            deformScale: 0.00005 * Config.appearance.deformScale

            Behavior on y {
                Anim {
                    id: submenuAnim

                    type: Anim.SlowEffects
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

    AnnotationToolbar {
        id: toolbar

        anchors.horizontalCenter: parent.horizontalCenter
        y: Tokens.padding.medium

        annotation: annotation
        onSaved: exporter.save(annotation.composite())
        onCopied: exporter.copy(annotation.composite())
        onCancelled: root.visible = false
    }

    MouseArea {
        id: submenu

        readonly property Item content: root.picking ? ((picker.item as Item) ?? submenuContent) : submenuContent
        readonly property real fullHeight: content.implicitHeight + Tokens.padding.small * 2
        readonly property real visibleTop: root.picking ? submenuBg.y : Math.max(submenuBg.y, root.borderTop)
        readonly property real pivotY: submenuBg.y - y + submenuBg.height / 2

        x: submenuBg.x
        y: visibleTop

        clip: true
        implicitWidth: content.implicitWidth + Tokens.padding.small * 2
        implicitHeight: submenuBg.height
        height: Math.max(0, submenuBg.y + submenuBg.height - visibleTop)

        opacity: root.submenuOpen ? 1 : 0
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

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        AnnotationSubmenu {
            id: submenuContent

            anchors.horizontalCenter: parent.horizontalCenter
            y: submenuBg.y - submenu.y + Tokens.padding.small
            document: document
            customColour: root.customColour
            customBackgroundColour: root.customBackgroundColour
            opacity: root.picking || !root.submenuOpen ? 0 : 1

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
                onInteraction: c => {
                    const swatches = submenuContent.picking;
                    if (!swatches)
                        return;

                    swatches.selected(c);
                    if (swatches.background)
                        root.customBackgroundColour = c;
                    else
                        root.customColour = c;
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
}
