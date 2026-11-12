pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import M3Shapes
import Caelestia
import Caelestia.Components
import Caelestia.Config
import Caelestia.Scheme
import qs.components
import qs.components.controls

Item {
    id: root

    required property AnnotationDocument document
    property color customColour
    property color customBackgroundColour
    property Item picking

    implicitWidth: loader.implicitWidth
    implicitHeight: dummySizing.implicitHeight

    // Use the toggle button as the height to keep it all uniform (the toggle is the tallest item)
    ToggleButton {
        id: dummySizing

        visible: false
    }

    AnimLoader {
        id: loader

        anchors.centerIn: parent
        onSourceCompChanged: root.picking = null
        sourceComp: {
            switch (root.document.tool) {
            case AnnotationDocument.Select:
                return null;
            case AnnotationDocument.Pencil:
            case AnnotationDocument.Highlighter:
            case AnnotationDocument.Line:
            case AnnotationDocument.Arrow:
                return penControls;
            case AnnotationDocument.Rect:
                return rectControls;
            case AnnotationDocument.Ellipse:
                return ellipseControls;
            case AnnotationDocument.Text:
                return textControls;
            case AnnotationDocument.Counter:
                return counterControls;
            case AnnotationDocument.Blur:
            case AnnotationDocument.Pixelate:
                return effectControls;
            }
        }
    }

    Component {
        id: penControls

        RowLayout {
            spacing: Tokens.spacing.large

            Swatches {
                custom: root.customColour
                selectedColour: root.document.color
                onSelected: c => root.document.color = c
            }

            IconLabel {
                text: "line_weight"
            }

            SliderControl {
                Layout.rightMargin: Tokens.padding.extraSmall
                value: root.document.strokeWidth
                onInteraction: v => root.document.strokeWidth = v
            }
        }
    }

    Component {
        id: rectControls

        RowLayout {
            spacing: Tokens.spacing.large

            Swatches {
                custom: root.customColour
                selectedColour: root.document.color
                onSelected: c => root.document.color = c
            }

            IconLabel {
                text: "line_weight"
            }

            SliderControl {
                value: root.document.strokeWidth
                onInteraction: v => root.document.strokeWidth = v
            }

            ToggleButton {
                checked: root.document.fill
                onClicked: root.document.fill = !root.document.fill
            }

            IconLabel {
                text: "rounded_corner"
            }

            SliderControl {
                Layout.rightMargin: Tokens.padding.extraSmall
                from: 0
                to: 20
                stepSize: 0
                value: root.document.radius
                onInteraction: v => root.document.radius = v
            }
        }
    }

    Component {
        id: ellipseControls

        RowLayout {
            spacing: Tokens.spacing.large

            Swatches {
                custom: root.customColour
                selectedColour: root.document.color
                onSelected: c => root.document.color = c
            }

            IconLabel {
                text: "line_weight"
            }

            SliderControl {
                value: root.document.strokeWidth
                onInteraction: v => root.document.strokeWidth = v
            }

            ToggleButton {
                checked: root.document.fill
                onClicked: root.document.fill = !root.document.fill
            }
        }
    }

    Component {
        id: textControls

        RowLayout {
            spacing: Tokens.spacing.large

            IconLabel {
                Layout.leftMargin: Tokens.padding.extraSmall
                text: "format_color_text"
            }

            Swatches {
                custom: root.customColour
                selectedColour: root.document.color
                onSelected: c => root.document.color = c
            }

            IconLabel {
                text: "format_color_fill"
            }

            Swatches {
                background: true
                custom: root.customBackgroundColour
                colours: [Colours.palette.surface, Colours.palette.surfaceContainerHighest, Colours.palette.primaryContainer, Colours.palette.errorContainer]
                selectedColour: root.document.backgroundColor
                onSelected: c => root.document.backgroundColor = c
            }

            IconLabel {
                text: "format_size"
            }

            SliderControl {
                from: 8
                to: 96
                stepSize: 0
                value: root.document.font.pointSize
                onInteraction: v => root.document.font.pointSize = v
            }

            ToggleButton {
                checked: root.document.textBackground
                onClicked: root.document.textBackground = !root.document.textBackground
            }

            IconLabel {
                text: "rounded_corner"
            }

            SliderControl {
                Layout.rightMargin: Tokens.padding.extraSmall
                from: 0
                to: 20
                stepSize: 0
                value: root.document.radius
                onInteraction: v => root.document.radius = v
            }
        }
    }

    Component {
        id: counterControls

        RowLayout {
            spacing: Tokens.spacing.large

            IconLabel {
                Layout.leftMargin: Tokens.padding.extraSmall
                text: "format_color_text"
            }

            Swatches {
                custom: root.customColour
                selectedColour: root.document.color
                onSelected: c => root.document.color = c
            }

            IconLabel {
                text: "format_color_fill"
            }

            Swatches {
                background: true
                custom: root.customBackgroundColour
                colours: [Colours.palette.surface, Colours.palette.surfaceContainerHighest, Colours.palette.primaryContainer, Colours.palette.errorContainer]
                selectedColour: root.document.backgroundColor
                onSelected: c => root.document.backgroundColor = c
            }

            IconLabel {
                text: "format_size"
            }

            SliderControl {
                Layout.rightMargin: Tokens.padding.extraSmall
                from: 8
                to: 96
                stepSize: 0
                value: root.document.font.pointSize
                onInteraction: v => root.document.font.pointSize = v
            }
        }
    }

    Component {
        id: effectControls

        RowLayout {
            spacing: Tokens.spacing.large

            IconLabel {
                Layout.leftMargin: Tokens.padding.extraSmall
                text: "wand_shine"
            }

            SliderControl {
                Layout.rightMargin: Tokens.padding.extraSmall
                from: 0
                to: 1
                stepSize: 0
                value: root.document.effectStrength
                onInteraction: v => root.document.effectStrength = v
            }
        }
    }

    component ToggleButton: IconButton {
        icon: "texture"
        isRound: true
        isToggle: true
        inactiveColour: Colours.palette.primaryContainer
        inactiveOnColour: Colours.palette.onPrimaryContainer
        font: Tokens.font.body.medium
        padding: Tokens.padding.extraSmall
    }

    component IconLabel: MaterialIcon {
        Layout.rightMargin: -Tokens.spacing.small
        color: Colours.palette.onSecondaryContainer
        fontStyle: Tokens.font.icon.medium
    }

    component SliderControl: RowLayout {
        id: slider

        property alias from: sliderControl.from
        property alias to: sliderControl.to
        property alias stepSize: sliderControl.stepSize
        property alias value: sliderControl.value

        signal interaction(v: real)

        spacing: Tokens.spacing.small

        StyledText {
            text: slider.from
            color: Colours.palette.onSecondaryContainer
            font: Tokens.font.label.small
        }

        StyledSlider {
            id: sliderControl

            handleHeight: dragging ? 2.8 : 2.4
            bgColour: Colours.palette.primaryContainer
            from: 1
            to: 10
            stepSize: 1
            onInteraction: v => slider.interaction(valueAt(v))
        }

        StyledText {
            text: slider.to
            color: Colours.palette.onSecondaryContainer
            font: Tokens.font.label.small
        }
    }

    component Swatches: RowLayout {
        id: swatches

        required property color selectedColour
        required property color custom
        property bool background
        property alias colours: swatchRepeater.model

        signal selected(colour: color)

        spacing: Tokens.spacing.extraSmall

        Repeater {
            id: swatchRepeater

            model: [Colours.palette.primary, Colours.palette.secondary, Colours.palette.tertiary, Colours.palette.error]

            Swatch {
                selected: modelData === swatches.selectedColour
                onClicked: swatches.selected(modelData)
            }
        }

        Swatch {
            id: pickerSwatch

            modelData: selected ? swatches.selectedColour : swatches.custom
            selected: !swatchRepeater.model.includes(swatches.selectedColour)
            onClicked: {
                if (!selected)
                    swatches.selected(modelData);
                root.picking = swatches;
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: "more_horiz"
                color: (Colours.toOklch(pickerSwatch.modelData).x > 0.6) ^ (Colours.mode === Colours.Light) ? Colours.palette.inverseOnSurface : Colours.palette.onSurface
                font: Tokens.font.icon.small

                opacity: pickerSwatch.selected ? 0 : 1

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }
    }

    component Swatch: MouseArea {
        id: swatch

        required property color modelData
        required property bool selected

        readonly property real spacing: Tokens.spacing.extraSmall

        implicitWidth: swatchShape.implicitSize + (spacing + swatchOutline.strokeWidth) * 2
        implicitHeight: swatchShape.implicitSize + (spacing + swatchOutline.strokeWidth) * 2

        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        MaterialShape {
            id: swatchShape

            anchors.centerIn: parent
            implicitSize: Tokens.padding.large
            shape: swatch.selected ? MaterialShape.VerySunny : MaterialShape.Circle
            color: swatch.modelData

            Behavior on color {
                CAnim {}
            }
        }

        Shape {
            preferredRendererType: Shape.CurveRenderer
            opacity: swatch.selected || swatch.pressed ? 1 : swatch.containsMouse ? 0.7 : 0

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            ShapePath {
                id: swatchOutline

                capStyle: ShapePath.RoundCap
                fillColor: "transparent"
                strokeWidth: 2
                strokeColor: Colours.palette.primary

                PathPolyline {
                    function pointAt(angle: real): point {
                        const dist = swatchShape.distanceAtAngle(angle) + swatchOutline.strokeWidth / 2 + swatch.spacing;
                        const rad = angle * Math.PI / 180;
                        return Qt.point(swatch.width / 2 + dist * Math.sin(rad), swatch.height / 2 - dist * Math.cos(rad));
                    }

                    path: {
                        CUtils.dependency(swatchShape.morphProgress);
                        const points = [];
                        for (let angle = 0; angle < 360; angle += 3)
                            points.push(pointAt(angle));
                        points.push(pointAt(360));
                        return points;
                    }
                }

                Behavior on strokeColor {
                    CAnim {}
                }
            }
        }
    }
}
