pragma ComponentBehavior: Bound

import ".."
import "../../components"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.settings
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

    // Persistent settings
    Settings {
        id: themeSettings
        category: "appearance"
        property real savedHue: 180
        property bool savedDarkMode: true
        property string savedScheme: "monochromatic"
    }

    // State variable - load from settings on creation
    property real currentHue: themeSettings.savedHue
    property bool currentDarkMode: themeSettings.savedDarkMode
    property string currentScheme: themeSettings.savedScheme
    
    // Debounce timer
    Timer {
        id: debounceTimer
        interval: 500
        repeat: false
        onTriggered: executeThemeUpdate()
    }

    // Execute the actual theme update
    function executeThemeUpdate() {
        const mode = currentDarkMode ? "dark" : "light";
        const hueValue = Math.round(currentHue);
        
        // Save to settings
        themeSettings.savedHue = hueValue;
        themeSettings.savedDarkMode = currentDarkMode;
        themeSettings.savedScheme = currentScheme;
        
        // Execute the python script
        const command = ["sh", "-c", `python ~/.config/hypr/scheme/caelestia_hue_theme.py --hue ${hueValue} --mode ${mode} --scheme ${currentScheme}`];
        Quickshell.execDetached(command);
        
        console.log(`Theme updated: hue=${hueValue}, mode=${mode}`);
    }

    // Debounced update - restart timer on value change
    function updateThemeDebounced() {
        debounceTimer.restart();
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.normal
        
        // Custom slider with rainbow gradient
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            StyledText {
                text: qsTr("Theme Hue: %1°").arg(Math.round(root.currentHue))
                font.weight: 800
            }
            
            Slider {
                id: hueSlider
                Layout.fillWidth: true
                from: 0
                to: 360
                stepSize: 1
                value: root.currentHue
                
                onMoved: {
                    root.currentHue = value;
                    root.updateThemeDebounced();
                }
                
                background: Rectangle {
                    x: hueSlider.leftPadding
                    y: hueSlider.topPadding + hueSlider.availableHeight / 2 - height / 2
                    implicitWidth: 200
                    implicitHeight: 8
                    width: hueSlider.availableWidth
                    height: implicitHeight
                    radius: 4
                    
                    // Rainbow gradient background
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#FF0000" }     // Red
                        GradientStop { position: 0.167; color: "#FFFF00" }   // Yellow
                        GradientStop { position: 0.333; color: "#00FF00" }   // Green
                        GradientStop { position: 0.5; color: "#00FFFF" }     // Cyan
                        GradientStop { position: 0.667; color: "#0000FF" }   // Blue
                        GradientStop { position: 0.833; color: "#FF00FF" }   // Magenta
                        GradientStop { position: 1.0; color: "#FF0000" }     // Red
                    }
                }
                
                handle: Rectangle {
                    x: hueSlider.leftPadding + hueSlider.visualPosition * (hueSlider.availableWidth - width)
                    y: hueSlider.topPadding + hueSlider.availableHeight / 2 - height / 2
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: 10
                    color: "white"
                    border.color: "#333333"
                    border.width: 2
                    
                    // Hue indicator preview
                    Rectangle {
                        anchors.centerIn: parent
                        width: 12
                        height: 12
                        radius: 6
                        color: Qt.hsla(root.currentHue / 360, 0.8, 0.5, 1.0)
                    }
                }
            }
        }

        SwitchRow {
            Layout.fillWidth: true
            label: qsTr("Dark mode")
            checked: root.currentDarkMode
            onToggled: (checked) => {
                root.currentDarkMode = checked;
                root.updateThemeDebounced();
            }
        }
        
        // Status indicator
        StyledText {
            Layout.fillWidth: true
            text: debounceTimer.running ? qsTr("Updating theme...") : qsTr("Ready")
            color: debounceTimer.running ? Colours.palette.m3tertiary : Colours.palette.m3outlineVariant
            font.pointSize: 9
            opacity: 0.7
        }
    }
    
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small / 2

        StyledText {
            text: qsTr("Color Scheme")
            font.weight: 800
        }

        Repeater {
            model: ["Monochromatic", "Complementary", "Analogous", "Triadic", "Split-Complementary", "Tetradic"]

            delegate: StyledRect {
                required property var modelData
                required property int index

                Layout.fillWidth: true

                property var schemeNames: ["monochromatic", "complementary", "analogous", "triadic", "split-complementary", "tetradic"]
                color: Qt.alpha(Colours.tPalette.m3surfaceContainer, root.currentScheme === schemeNames[index] ? Colours.tPalette.m3surfaceContainer.a : 0)
                radius: Tokens.rounding.normal
                border.width: root.currentScheme === schemeNames[index] ? 1 : 0
                border.color: Colours.palette.m3primary
                implicitHeight: schemeRow.implicitHeight + Tokens.padding.normal * 2

                StateLayer {
                    onClicked: {
                        root.currentScheme = schemeNames[index];
                        root.updateThemeDebounced();
                    }
                }

                RowLayout {
                    id: schemeRow

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Tokens.padding.normal

                    spacing: Tokens.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData
                        font.weight: root.currentScheme === (index === 0 ? "monochromatic" : "complementary") ? 500 : 400
                    }

                    MaterialIcon {
                        visible: root.currentScheme === schemeNames[index]
                        text: "check"
                        color: Colours.palette.m3primary
                        font.pointSize: Tokens.font.size.large
                    }
                }
            }
        }
    }
}