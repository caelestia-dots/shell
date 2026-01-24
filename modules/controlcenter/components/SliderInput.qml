pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property string label: ""
    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 0
    property var validator: null
    property string suffix: "" // Optional suffix text (e.g., "×", "px")
    property int decimals: 1 // Number of decimal places to show (default: 1)
    property var formatValueFunction: null // Optional custom format function
    property var parseValueFunction: null // Optional custom parse function
    
    function formatValue(val: real): string {
        if (formatValueFunction) {
            return formatValueFunction(val);
        }
        // Default format function
        // Check if it's an IntValidator (IntValidator doesn't have a 'decimals' property)
        if (validator && validator.bottom !== undefined && validator.decimals === undefined) {
            return Math.round(val).toString();
        }
        // For DoubleValidator or no validator, use the decimals property
        return val.toFixed(root.decimals);
    }
    
    function parseValue(text: string): real {
        if (parseValueFunction) {
            return parseValueFunction(text);
        }
        // Default parse function
        if (validator && validator.bottom !== undefined) {
            // Check if it's an integer validator
            if (validator.top !== undefined && validator.top === Math.floor(validator.top)) {
                return parseInt(text);
            }
        }
        return parseFloat(text);
    }
    
    signal valueModified(real newValue)

    property bool _initialized: false

    spacing: Appearance.spacing.small
    
    Component.onCompleted: {
        // Set initialized flag after a brief delay to allow component to fully load
        Qt.callLater(() => {
            _initialized = true;
        });
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            visible: root.label !== ""
            text: root.label
            font.pointSize: Appearance.font.size.normal
        }

        Item {
            Layout.fillWidth: true
        }

        StyledInputField {
            id: inputField
            Layout.preferredWidth: 70
            validator: root.validator
            
            Component.onCompleted: {
                // Initialize text without triggering valueModified signal
                text = root.formatValue(root.value);
            }
            
            onTextEdited: (text) => {
                if (hasFocus) {
                    const val = root.parseValue(text);
                    if (!isNaN(val)) {
                        // Validate against validator bounds if available
                        let isValid = true;
                        if (root.validator) {
                            if (root.validator.bottom !== undefined && val < root.validator.bottom) {
                                isValid = false;
                            }
                            if (root.validator.top !== undefined && val > root.validator.top) {
                                isValid = false;
                            }
                        }
                        
                        if (isValid) {
                            root.valueModified(val);
                        }
                    }
                }
            }
            
            onEditingFinished: {
                const val = root.parseValue(text);
                let isValid = true;
                if (root.validator) {
                    if (root.validator.bottom !== undefined && val < root.validator.bottom) {
                        isValid = false;
                    }
                    if (root.validator.top !== undefined && val > root.validator.top) {
                        isValid = false;
                    }
                }
                
                if (isNaN(val) || !isValid) {
                    text = root.formatValue(root.value);
                }
            }
        }

        StyledText {
            visible: root.suffix !== ""
            text: root.suffix
            color: Colours.palette.m3outline
            font.pointSize: Appearance.font.size.normal
        }
    }

    StyledSlider {
        id: slider

        Layout.fillWidth: true
        implicitHeight: Appearance.padding.normal * 3

        from: root.from
        to: root.to
        stepSize: root.stepSize
        
        // Use Binding to allow slider to move freely during dragging
        Binding {
            target: slider
            property: "value"
            value: root.value
            when: !slider.pressed
        }
        
        onValueChanged: {
            // Update input field text in real-time as slider moves during dragging
            // Always update when slider value changes (during dragging or external updates)
            if (!inputField.hasFocus) {
                const newValue = root.stepSize > 0 ? Math.round(value / root.stepSize) * root.stepSize : value;
                inputField.text = root.formatValue(newValue);
            }
        }
        
        onMoved: {
            const newValue = root.stepSize > 0 ? Math.round(value / root.stepSize) * root.stepSize : value;
            root.valueModified(newValue);
            if (!inputField.hasFocus) {
                inputField.text = root.formatValue(newValue);
            }
        }
    }
    
    // Update input field when value changes externally (slider is already bound)
    onValueChanged: {
        // Only update if component is initialized to avoid issues during creation
        if (root._initialized && !inputField.hasFocus) {
            inputField.text = root.formatValue(root.value);
        }
    }
}

