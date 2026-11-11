pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Scheme
import Caelestia.State
import qs.components

RowLayout {
    id: root

    property color colour
    readonly property int maxRecents: 8

    property vector3d lch

    readonly property real lightness: lch.x
    readonly property real chromaFraction: lch.y
    readonly property real hue: lch.z

    property color lastColour
    property bool hadInteraction

    readonly property real chroma: chromaFraction * Colours.maxChroma(lightness, hue)
    readonly property color lchColour: Colours.oklch(lightness, chroma, hue)

    readonly property string hex: lchColour.toString().toUpperCase()
    readonly property string rgb: `${Math.round(lchColour.r * 255)}, ${Math.round(lchColour.g * 255)}, ${Math.round(lchColour.b * 255)}`
    readonly property string hsl: `${Math.round(Math.max(lchColour.hslHue, 0) * 360)}°, ${Math.round(lchColour.hslSaturation * 100)}%, ${Math.round(lchColour.hslLightness * 100)}%`
    readonly property string oklch: `${lightness.toFixed(2)}, ${chroma.toFixed(2)}, ${Math.round(hue)}°`

    readonly property color lchOnColour: onColourFor(lchColour)
    readonly property bool dragging: wheel.pressed

    signal interaction(colour: color)

    function syncFromColour(): void {
        if (Qt.colorEqual(colour, lchColour))
            return;

        const c = Colours.toOklch(colour);
        const max = Colours.maxChroma(c.x, c.z);
        lch = Qt.vector3d(c.x, max > 0.001 ? CUtils.clamp(c.y / max, 0, 1) : chromaFraction, c.y > 0.01 ? c.z : hue);
    }

    function onColourFor(c: color): color {
        return (Colours.toOklch(c).x > 0.6) ^ (Colours.mode === Colours.Light) ? Colours.palette.surface : Colours.palette.inverseSurface;
    }

    function commitRecent(c: color): void {
        const hex = c.toString();
        const recents = PersistentState.recentColours.filter(h => h !== hex);
        recents.unshift(hex);
        PersistentState.recentColours = recents.slice(0, maxRecents);
    }

    spacing: Tokens.spacing.large

    onColourChanged: {
        if (!dragging)
            syncFromColour();
    }
    Component.onCompleted: syncFromColour()
    Component.onDestruction: {
        if (hadInteraction)
            commitRecent(lastColour);
    }

    onInteraction: c => {
        lastColour = c;
        hadInteraction = true;
    }

    MouseArea {
        id: wheel

        readonly property real ringWidth: Tokens.padding.large
        readonly property real gap: Tokens.padding.small
        readonly property real innerRadius: oklchWheel.outerRadius - ringWidth
        readonly property real triRadius: innerRadius - gap
        readonly property real triLeft: -triRadius / 2
        readonly property real triHeight: triRadius * Math.sqrt(3)
        property bool inRing

        function rowWidth(l: real): real {
            return triRadius * 1.5 * (1 - Math.abs(2 * l - 1));
        }

        function update(e: MouseEvent): void {
            const x = e.x - width / 2;
            const y = height / 2 - e.y;
            if (inRing) {
                const deg = Math.atan2(y, x) * 180 / Math.PI;
                root.lch = Qt.vector3d(root.lightness, root.chromaFraction, (deg + 360) % 360);
            } else {
                const l = CUtils.clamp((y + triHeight / 2) / triHeight, 0, 1);
                const w = rowWidth(l);
                root.lch = Qt.vector3d(l, w > 0 ? CUtils.clamp((x - triLeft) / w, 0, 1) : root.chromaFraction, root.hue);
            }

            root.interaction(root.lchColour);
        }

        Layout.margins: Tokens.padding.extraLarge
        Layout.rightMargin: 0
        implicitWidth: 400
        implicitHeight: 400

        preventStealing: true
        onPressed: e => {
            inRing = Math.hypot(e.x - width / 2, e.y - height / 2) > innerRadius - gap / 2;
            update(e);
        }
        onPositionChanged: e => update(e)

        OklchWheel {
            id: oklchWheel

            anchors.fill: parent
            ringWidth: wheel.ringWidth
            gap: wheel.gap
            cornerRadius: Tokens.rounding.extraSmall
            hue: root.hue
        }

        Handle {
            id: triHandle

            x: wheel.width / 2 + wheel.triLeft + root.chromaFraction * wheel.rowWidth(root.lightness)
            y: wheel.height / 2 + wheel.triHeight / 2 - root.lightness * wheel.triHeight
            color: root.lchColour
            pressed: wheel.pressed && !wheel.inRing

            transform: Translate {
                x: -triHandle.width / 2
                y: -triHandle.height / 2
            }

            Behavior on x {
                Anim {
                    type: Anim.FastEffects
                }
            }

            Behavior on y {
                Anim {
                    type: Anim.FastEffects
                }
            }
        }

        Handle {
            id: hueHandle

            readonly property real ringRadius: wheel.innerRadius + wheel.ringWidth / 2
            property real angle: root.hue

            x: wheel.width / 2 + ringRadius * Math.cos(angle * Math.PI / 180)
            y: wheel.height / 2 - ringRadius * Math.sin(angle * Math.PI / 180)
            color: Colours.oklch(oklchWheel.ringLightness, oklchWheel.ringChroma, root.hue)
            pressed: wheel.pressed && wheel.inRing

            transform: Translate {
                x: -hueHandle.width / 2
                y: -hueHandle.height / 2
            }

            Behavior on angle {
                RotationAnimation {
                    direction: RotationAnimation.Shortest
                    easing: Tokens.anim.expressiveFastEffects
                    duration: Tokens.anim.durations.expressiveFastEffects
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.margins: Tokens.padding.extraLarge
        spacing: Tokens.spacing.small

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.bottomMargin: Tokens.spacing.small

            implicitWidth: heroLayout.implicitWidth + Tokens.padding.largeIncreased * 2
            implicitHeight: heroLayout.implicitHeight + Tokens.padding.largeIncreased * 2

            color: root.lchColour
            radius: Tokens.rounding.extraLarge
            bottomLeftRadius: Tokens.rounding.medium

            ColumnLayout {
                id: heroLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: Tokens.padding.small
                        Layout.leftMargin: Tokens.padding.small

                        text: Tr.tr("Selected")
                        color: root.lchOnColour
                        opacity: 0.78
                        font: Tokens.font.label.builders.medium.capitalisation(Font.AllUppercase).letterSpacing(1).build()
                    }

                    IconButton {
                        icon: "content_copy"
                        type: IconButton.Tonal
                        inactiveColour: Qt.alpha(root.lchOnColour, 0.18)
                        inactiveOnColour: root.lchOnColour
                        onClicked: Quickshell.execDetached(["wl-copy", root.hex])
                    }
                }

                StyledText {
                    Layout.fillHeight: true
                    Layout.leftMargin: Tokens.padding.extraSmall
                    verticalAlignment: Text.AlignBottom
                    text: root.hex
                    color: root.lchOnColour
                    font: Tokens.font.mono.builders.large.size(Tokens.font.headline.large.pointSize).build()
                }
            }
        }

        ValueRow {
            label: Tr.tr("RGB")
            value: root.rgb
        }

        ValueRow {
            label: Tr.tr("HSL")
            value: root.hsl
        }

        ValueRow {
            label: Tr.tr("OKLCH")
            value: root.oklch
        }

        StyledText {
            Layout.leftMargin: Tokens.padding.small
            Layout.topMargin: Tokens.spacing.extraSmall
            Layout.bottomMargin: Tokens.spacing.extraSmall - parent.spacing
            text: Tr.tr("Recent")
            color: Colours.palette.onSurfaceVariant
            font: Tokens.font.label.large
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: Tokens.padding.extraLargeIncreased + Tokens.padding.medium + Tokens.padding.medium * 2

            color: Colours.tPalette.surfaceContainer
            radius: Tokens.rounding.extraLarge

            StyledText {
                anchors.centerIn: parent
                text: Tr.tr("No recent colours")
                color: Colours.palette.outline

                opacity: recentRepeater.count === 0 ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            RowLayout {
                id: recentsLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.rightMargin: anchors.margins - spacing
                spacing: Tokens.spacing.small

                Repeater {
                    id: recentRepeater

                    model: PersistentState.recentColours

                    StyledRect {
                        id: recent

                        required property string modelData
                        readonly property bool active: modelData === root.lchColour.toString()

                        Layout.fillWidth: true
                        Layout.maximumWidth: Tokens.padding.extraLargeIncreased * 2
                        Layout.preferredWidth: Layout.maximumWidth
                        implicitHeight: Tokens.padding.extraLargeIncreased + Tokens.padding.medium
                        radius: active || recentStateLayer.pressed ? Tokens.rounding.small : Math.max(width, height) / 2
                        color: modelData

                        MaterialIcon {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: 2

                            text: "check"
                            color: root.onColourFor(recent.color)
                            fontStyle: Tokens.font.icon.medium
                            scale: recent.active ? 1 : 0

                            Behavior on scale {
                                Anim {
                                    type: Anim.FastSpatial
                                }
                            }
                        }

                        StateLayer {
                            id: recentStateLayer

                            color: root.onColourFor(recent.color)
                            onClicked: {
                                root.colour = recent.modelData;
                                root.interaction(root.colour);
                            }
                        }

                        Behavior on radius {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }

    component ValueRow: StyledRect {
        id: valueRow

        required property string label
        required property string value

        Layout.fillWidth: true
        implicitWidth: rowLayout.implicitWidth + Tokens.padding.large + Tokens.padding.extraSmall
        implicitHeight: rowLayout.implicitHeight + Tokens.padding.extraSmall * 2
        color: Colours.palette.surfaceContainerHigh
        radius: Tokens.rounding.full

        RowLayout {
            id: rowLayout

            anchors.fill: parent
            anchors.leftMargin: Tokens.padding.large
            anchors.rightMargin: Tokens.padding.extraSmall
            anchors.topMargin: Tokens.padding.extraSmall
            anchors.bottomMargin: Tokens.padding.extraSmall
            spacing: Tokens.spacing.medium

            StyledText {
                id: valueRowLabel

                Layout.preferredWidth: Math.max(rgbLabelWidth.width, hslLabelWidth.width, oklchLabelWidth.width)
                text: valueRow.label
                color: Colours.palette.onSurfaceVariant
                font: Tokens.font.label.builders.medium.letterSpacing(1).build()

                TextMetrics {
                    id: rgbLabelWidth

                    font: valueRowLabel.font
                    text: Tr.tr("RGB")
                }

                TextMetrics {
                    id: hslLabelWidth

                    font: valueRowLabel.font
                    text: Tr.tr("HSL")
                }

                TextMetrics {
                    id: oklchLabelWidth

                    font: valueRowLabel.font
                    text: Tr.tr("OKLCH")
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.preferredWidth: valueWidth.width
                text: valueRow.value
                color: Colours.palette.onSurface
                font: Tokens.font.mono.medium

                TextMetrics {
                    id: valueWidth

                    font: Tokens.font.mono.medium
                    text: "360°, 100%, 100%"
                }
            }

            IconButton {
                icon: "content_copy"
                type: IconButton.Tonal
                isRound: true
                radiusMorph: false
                onClicked: Quickshell.execDetached(["wl-copy", valueRow.value])
            }
        }
    }

    component Handle: StyledRect {
        required property bool pressed
        property real implicitSize: pressed ? Tokens.padding.largeIncreased : Tokens.padding.large

        implicitWidth: implicitSize
        implicitHeight: implicitSize
        radius: Tokens.rounding.full
        border.width: 3
        border.color: root.onColourFor(color)

        Behavior on implicitSize {
            Anim {
                type: Anim.FastSpatial
            }
        }

        Behavior on border.color {
            CAnim {}
        }
    }
}
