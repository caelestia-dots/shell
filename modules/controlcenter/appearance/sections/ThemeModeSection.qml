pragma ComponentBehavior: Bound

import ".."
import "../../components"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

CollapsibleSection {
    id: root
    title: qsTr("Theme mode")
    description: qsTr("Custom hue & Light/Dark theme")
    showBackground: true

    // State variable to track the hue value
    property real currentHue: 180

    // Reusable function to execute your script
    function updateTheme() {
        // Caelestia handles mode globally via Colours.currentLight
        const mode = Colours.currentLight ? "light" : "dark";
        const hueValue = Math.round(currentHue);
        
        // Execute the python script in a shell cleanly resolving '~'
        const command = ["sh", "-c", `python ~/.config/hypr/scheme/caelestia_hue_theme.py --hue ${hueValue} --mode ${mode}`];
        Quickshell.execDetached(command);
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.normal
        
        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Theme Hue")
            value: root.currentHue
            from: 0
            to: 360
            stepSize: 1
            decimals: 0
            onValueModified: (newValue) => {
                root.currentHue = newValue;
                updateTheme();
            }
        }

        SwitchRow {
            Layout.fillWidth: true
            label: qsTr("Dark mode")
            checked: !Colours.currentLight
            onToggled: checked => {
                // Change internal caelestia colors
                Colours.setMode(checked ? "dark" : "light");
                // Trigger the python script
                updateTheme();
            }
        }
    }
}