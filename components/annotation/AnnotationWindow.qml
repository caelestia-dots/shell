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

    signal saved
    signal copied
    signal cancelled

    contentItem.Config.screen: screen.name
    contentItem.Tokens.screen: screen.name

    minimumSize.width: toolbar.implicitWidth + contentItem.Tokens.padding.large * 2
    minimumSize.height: borderTop
    implicitWidth: Math.max(background.implicitWidth, toolbar.implicitWidth + contentItem.Tokens.padding.large * 2)
    implicitHeight: background.implicitHeight + borderTop

    color: Colours.tPalette.surface
    surfaceFormat.opaque: false
    title: Tr.tr("Annotate")

    onVisibleChanged: {
        if (!visible)
            cancelled();
    }

    contentItem.focus: true
    contentItem.Keys.onPressed: event => {
        if (annotation.handleKey(event) || event.key !== Qt.Key_Escape)
            return;

        if (picking)
            submenuContent.picking = null;
        else
            visible = false;
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

    Item {
        anchors.fill: parent
        anchors.topMargin: root.borderTop

        Image {
            id: background

            anchors.fill: parent
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: root.file

            onStatusChanged: {
                if (status === Image.Ready)
                    grabToImage(res => annotation.base = res.image);
            }
            Component.onCompleted: {
                if (status === Image.Ready)
                    grabToImage(res => annotation.base = res.image);
            }
        }

        Annotation {
            id: annotation

            anchors.fill: parent
            active: true
            document: document
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
        onSaved: root.saved()
        onCopied: root.copied()
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
