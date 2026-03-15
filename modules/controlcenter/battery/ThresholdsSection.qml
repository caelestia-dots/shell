pragma ComponentBehavior: Bound

import ".."
import "../components"
import "." as Power
import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

SectionContainer {
    id: root

    required property var rootItem

    Layout.fillWidth: true
    Layout.fillHeight: true
    alignTop: true

    Component.onCompleted: {
        const configThresholds = Config.general.battery.powerManagement.thresholds || [];
        thresholdsModel.clear();
        for (let i = 0; i < configThresholds.length; i++) {
            const t = configThresholds[i];
            thresholdsModel.append({
                level: t.level || 40,
                setPowerProfile: t.setPowerProfile || "",
                setRefreshRate: t.setRefreshRate || "",
                disableAnimations: t.disableAnimations || "",
                disableBlur: t.disableBlur || "",
                disableRounding: t.disableRounding || "",
                disableShadows: t.disableShadows || ""
            });
        }
    }

    function saveThresholds() {
        const thresholds = [];
        for (let i = 0; i < thresholdsModel.count; i++) {
            const item = thresholdsModel.get(i);
            thresholds.push({
                level: item.level,
                setPowerProfile: item.setPowerProfile,
                setRefreshRate: item.setRefreshRate,
                disableAnimations: item.disableAnimations,
                disableBlur: item.disableBlur,
                disableRounding: item.disableRounding,
                disableShadows: item.disableShadows
            });
        }
        Config.general.battery.powerManagement.thresholds = thresholds;
        Config.save();
    }

    ListModel {
        id: thresholdsModel
    }

    StyledText {
        text: qsTr("Battery Level Thresholds")
        font.pointSize: Appearance.font.size.normal
    }

    StyledText {
        text: qsTr("Define actions to take at specific battery levels")
        font.pointSize: Appearance.font.size.smaller
        opacity: 0.7
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }

    SectionContainer {
        Layout.fillWidth: true
        alignTop: true

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal
            
            Behavior on implicitHeight {
                Anim {}
            }

            // Add threshold button
        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            radius: Appearance.rounding.normal
            color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
            border.width: 2
            border.color: Qt.alpha(Colours.palette.m3primary, 0.3)

            StateLayer {
                function onClicked() {
                    thresholdsModel.append({
                        level: 50,
                        setPowerProfile: "",
                        setRefreshRate: "auto",
                        disableAnimations: "",
                        disableBlur: "",
                        disableRounding: "",
                        disableShadows: ""
                    });
                    root.saveThresholds();
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: Appearance.padding.normal
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: "add_circle"
                    font.pointSize: Appearance.font.size.large
                    color: Colours.palette.m3primary
                }

                StyledText {
                    text: qsTr("Add Threshold")
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3primary
                }
                
                Item { Layout.fillWidth: true }
            }
        }

        // Threshold cards
        Repeater {
            model: thresholdsModel

            delegate: StyledRect {
                id: card
                
                required property int index
                required property int level
                required property string setPowerProfile
                required property string setRefreshRate
                required property string disableAnimations
                required property string disableBlur
                required property string disableRounding
                required property string disableShadows

                property bool editing: false
                property bool removing: false

                Layout.fillWidth: true
                Layout.preferredHeight: editing ? contentColumn.implicitHeight + Appearance.padding.normal * 2 : 60
                radius: Appearance.rounding.normal
                color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
                scale: removing ? 0 : 1
                opacity: removing ? 0 : 1

                Behavior on Layout.preferredHeight {
                    Anim {}
                }

                Behavior on scale {
                    Anim {
                        duration: Appearance.anim.durations.normal
                        easing.bezierCurve: Appearance.anim.curves.standardAccel
                    }
                }

                Behavior on opacity {
                    Anim {
                        duration: Appearance.anim.durations.normal
                        easing.bezierCurve: Appearance.anim.curves.standardAccel
                    }
                }

                SequentialAnimation {
                    id: removeAnimation
                    
                    PropertyAction {
                        target: card
                        property: "removing"
                        value: true
                    }
                    PauseAnimation {
                        duration: Appearance.anim.durations.normal
                    }
                    ScriptAction {
                        script: {
                            thresholdsModel.remove(card.index);
                            root.saveThresholds();
                        }
                    }
                }

                ColumnLayout {
                    id: contentColumn
                    
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Appearance.padding.normal
                    spacing: Appearance.spacing.normal

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: card.level + "% Battery"
                            font.pointSize: Appearance.font.size.normal
                            font.weight: 500
                        }

                        TextButton {
                            text: card.editing ? qsTr("Done") : qsTr("Edit")
                            onClicked: card.editing = !card.editing
                        }

                        IconButton {
                            icon: "delete"
                            onClicked: removeAnimation.start()
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        active: true
                        asynchronous: false
                        visible: opacity > 0
                        opacity: card.editing ? 1 : 0
                        
                        Behavior on opacity {
                            Anim {
                                duration: Appearance.anim.durations.normal
                                easing.bezierCurve: Appearance.anim.curves.standard
                            }
                        }
                        
                        sourceComponent: ColumnLayout {
                            spacing: Appearance.spacing.normal
                            
                            StyledRect {
                                Layout.fillWidth: true
                                implicitHeight: batteryLevelRow.implicitHeight + Appearance.padding.large * 2
                                radius: Appearance.rounding.normal
                                color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                
                                Behavior on implicitHeight {
                                    Anim {}
                                }
                                
                                RowLayout {
                                    id: batteryLevelRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: Appearance.padding.large
                                    spacing: Appearance.spacing.normal
                                    
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: qsTr("Battery Level")
                                    }
                                    
                                    CustomSpinBox {
                                        min: 5
                                        max: 95
                                        step: 1
                                        value: card.level
                                        onValueModified: newValue => {
                                            if (newValue !== card.level) {
                                                thresholdsModel.setProperty(card.index, "level", Math.round(newValue));
                                                root.saveThresholds();
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Power.PowerProfileSelector {
                                Layout.fillWidth: true
                                label: qsTr("Power Profile")
                                value: card.setPowerProfile
                                onProfileChanged: newValue => {
                                    thresholdsModel.setProperty(card.index, "setPowerProfile", newValue);
                                    root.saveThresholds();
                                }
                            }
                            
                            Power.RefreshRateSelector {
                                Layout.fillWidth: true
                                label: qsTr("Refresh Rate")
                                showUnchanged: true
                                value: card.setRefreshRate
                                onRateChanged: newValue => {
                                    thresholdsModel.setProperty(card.index, "setRefreshRate", newValue);
                                    root.saveThresholds();
                                }
                            }
                            
                            TriStateRow {
                                Layout.fillWidth: true
                                label: qsTr("Animations")
                                value: card.disableAnimations
                                onTriStateValueChanged: newValue => {
                                    thresholdsModel.setProperty(card.index, "disableAnimations", newValue);
                                    root.saveThresholds();
                                }
                            }
                            
                            TriStateRow {
                                Layout.fillWidth: true
                                label: qsTr("Blur")
                                value: card.disableBlur
                                onTriStateValueChanged: newValue => {
                                    thresholdsModel.setProperty(card.index, "disableBlur", newValue);
                                    root.saveThresholds();
                                }
                            }
                            
                            TriStateRow {
                                Layout.fillWidth: true
                                label: qsTr("Rounding")
                                value: card.disableRounding
                                onTriStateValueChanged: newValue => {
                                    thresholdsModel.setProperty(card.index, "disableRounding", newValue);
                                    root.saveThresholds();
                                }
                            }
                            
                            TriStateRow {
                                Layout.fillWidth: true
                                label: qsTr("Shadows")
                                value: card.disableShadows
                                onTriStateValueChanged: newValue => {
                                    thresholdsModel.setProperty(card.index, "disableShadows", newValue);
                                    root.saveThresholds();
                                }
                            }
                        }
                    }
                }
                
                Component.onCompleted: {
                    scale = 0;
                    opacity = 0;
                    scaleInAnimation.start();
                }
                
                ParallelAnimation {
                    id: scaleInAnimation
                    
                    Anim {
                        target: card
                        property: "scale"
                        from: 0.7
                        to: 1
                        duration: Appearance.anim.durations.normal
                        easing.bezierCurve: Appearance.anim.curves.standardDecel
                    }
                    Anim {
                        target: card
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Appearance.anim.durations.normal
                        easing.bezierCurve: Appearance.anim.curves.standardDecel
                    }
                }
            }
        }
        }
    }
}
