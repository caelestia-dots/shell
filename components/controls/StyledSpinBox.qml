import QtQuick
import QtQuick.Templates
import Caelestia.Config
import qs.components
import qs.services

DoubleSpinBox {
    id: root

    property int repeatRate: 400
    property int repeatDecay: 50
    property int cLayer: 1

    function increase(): void {
        let newValue = Math.min(to, value + stepSize);
        // Round to avoid floating point precision errors
        const decimals = stepSize < 1 ? Math.max(1, Math.ceil(-Math.log10(stepSize))) : 0;
        newValue = Math.round(newValue * Math.pow(10, decimals)) / Math.pow(10, decimals);
        value = newValue;
        valueModified();
    }

    function decrease(): void {
        let newValue = Math.max(from, value - stepSize);
        // Round to avoid floating point precision errors
        const decimals = stepSize < 1 ? Math.max(1, Math.ceil(-Math.log10(stepSize))) : 0;
        newValue = Math.round(newValue * Math.pow(10, decimals)) / Math.pow(10, decimals);
        value = newValue;
        valueModified();
    }

    editable: true
    decimals: stepSize < 1 ? Math.max(1, Math.ceil(-Math.log10(stepSize))) : 0
    spacing: Tokens.spacing.small

    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: Math.max(up.indicator.implicitHeight, down.indicator.implicitHeight, contentItem.implicitHeight) + topPadding + bottomPadding

    leftPadding: up.indicator.implicitWidth + Tokens.spacing.extraSmall / 2
    rightPadding: down.indicator.implicitWidth + Tokens.spacing.extraSmall / 2

    contentItem: TextFieldBase {
        text: root.textFromValue(root.value, root.locale)

        readOnly: !root.editable
        validator: root.validator
        inputMethodHints: Qt.ImhFormattedNumbersOnly

        leftPadding: Tokens.padding.medium
        rightPadding: Tokens.padding.medium

        implicitWidth: 65
        horizontalAlignment: TextField.AlignHCenter

        background: StyledRect {
            radius: Tokens.rounding.extraSmall
            color: Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer)
        }
    }

    down.indicator: IconButton {
        id: downButton

        topRightRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall
        bottomRightRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall

        icon: "remove"
        disabledColour: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.4)
        color: disabled ? disabledColour : Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer)
        type: IconButton.Text
        padding: Tokens.padding.extraSmall
        isRound: true
        label.anchors.horizontalCenterOffset: pressed ? 0 : 2
        disabled: !enabled

        Behavior on topRightRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on bottomRightRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on label.anchors.horizontalCenterOffset {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    up.indicator: IconButton {
        id: upButton

        anchors.right: parent.right

        topLeftRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall
        bottomLeftRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall

        icon: "add"
        disabledColour: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.4)
        color: disabled ? disabledColour : Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer)
        type: IconButton.Text
        padding: Tokens.padding.extraSmall
        isRound: true
        label.anchors.horizontalCenterOffset: pressed ? 0 : -2
        disabled: !enabled

        Behavior on topLeftRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on bottomLeftRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on label.anchors.horizontalCenterOffset {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Timer {
        id: timer

        running: upButton.pressed || downButton.pressed
        onRunningChanged: {
            if (!running)
                interval = root.repeatRate;
        }

        interval: root.repeatRate
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (upButton.pressed)
                root.increase();
            else if (downButton.pressed)
                root.decrease();
            if (interval > root.repeatDecay)
                interval -= root.repeatDecay;
        }
    }
}
