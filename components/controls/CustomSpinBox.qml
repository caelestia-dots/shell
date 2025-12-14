pragma ComponentBehavior: Bound

import ".."
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    property real value
    property real max: Infinity
    property real min: -Infinity
    property real step: 1
    property alias repeatRate: timer.interval

    signal valueModified(value: real)

    spacing: Appearance.spacing.small

    property bool isEditing: false
    property string displayText: root.value.toString()

    onValueChanged: {
        if (!root.isEditing) {
            root.displayText = root.value.toString();
        }
    }

    StyledTextField {
        id: textField

        inputMethodHints: Qt.ImhFormattedNumbersOnly
        text: root.isEditing ? text : root.displayText
        validator: DoubleValidator {
            bottom: root.min
            top: root.max
            decimals: root.step < 1 ? Math.max(1, Math.ceil(-Math.log10(root.step))) : 0
        }
        onActiveFocusChanged: {
            if (activeFocus) {
                root.isEditing = true;
            } else {
                root.isEditing = false;
                root.displayText = root.value.toString();
            }
        }
        onAccepted: {
            const numValue = parseFloat(text);
            if (!isNaN(numValue)) {
                const clampedValue = Math.max(root.min, Math.min(root.max, numValue));
                root.value = clampedValue;
                root.displayText = clampedValue.toString();
                root.valueModified(clampedValue);
            } else {
                text = root.displayText;
            }
            root.isEditing = false;
        }
        onEditingFinished: {
            if (text !== root.displayText) {
                const numValue = parseFloat(text);
                if (!isNaN(numValue)) {
                    const clampedValue = Math.max(root.min, Math.min(root.max, numValue));
                    root.value = clampedValue;
                    root.displayText = clampedValue.toString();
                    root.valueModified(clampedValue);
                } else {
                    text = root.displayText;
                }
            }
            root.isEditing = false;
        }

        padding: Appearance.padding.small
        leftPadding: Appearance.padding.normal
        rightPadding: Appearance.padding.normal

        background: StyledRect {
            implicitWidth: 100
            radius: Appearance.rounding.small
            color: Colours.tPalette.m3surfaceContainerHigh
        }
    }

    StyledRect {
        radius: Appearance.rounding.small
        color: Colours.palette.m3primary

        implicitWidth: implicitHeight
        implicitHeight: upIcon.implicitHeight + Appearance.padding.small * 2

        StateLayer {
            id: upState

            color: Colours.palette.m3onPrimary

            onPressAndHold: timer.start()
            onReleased: timer.stop()

            function onClicked(): void {
                let newValue = Math.min(root.max, root.value + root.step);
                // Round to avoid floating point precision errors
                const decimals = root.step < 1 ? Math.max(1, Math.ceil(-Math.log10(root.step))) : 0;
                newValue = Math.round(newValue * Math.pow(10, decimals)) / Math.pow(10, decimals);
                root.value = newValue;
                root.displayText = newValue.toString();
                root.valueModified(newValue);
            }
        }

        MaterialIcon {
            id: upIcon

            anchors.centerIn: parent
            text: "keyboard_arrow_up"
            color: Colours.palette.m3onPrimary
        }
    }

    StyledRect {
        radius: Appearance.rounding.small
        color: Colours.palette.m3primary

        implicitWidth: implicitHeight
        implicitHeight: downIcon.implicitHeight + Appearance.padding.small * 2

        StateLayer {
            id: downState

            color: Colours.palette.m3onPrimary

            onPressAndHold: timer.start()
            onReleased: timer.stop()

            function onClicked(): void {
                let newValue = Math.max(root.min, root.value - root.step);
                // Round to avoid floating point precision errors
                const decimals = root.step < 1 ? Math.max(1, Math.ceil(-Math.log10(root.step))) : 0;
                newValue = Math.round(newValue * Math.pow(10, decimals)) / Math.pow(10, decimals);
                root.value = newValue;
                root.displayText = newValue.toString();
                root.valueModified(newValue);
            }
        }

        MaterialIcon {
            id: downIcon

            anchors.centerIn: parent
            text: "keyboard_arrow_down"
            color: Colours.palette.m3onPrimary
        }
    }

    Timer {
        id: timer

        interval: 100
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (upState.pressed)
                upState.onClicked();
            else if (downState.pressed)
                downState.onClicked();
        }
    }
}
