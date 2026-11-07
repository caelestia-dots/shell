pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

ConnectedRect {
    id: root

    property string icon: ""
    property string displayedIcon: icon
    property string transitionIcon: ""
    property bool iconTapEnabled: false
    property bool nightLightActive: false
    property bool sliderEnabled: true
    property real wheelStep: GlobalConfig.services.audioIncrement

    property alias label: label.text
    property alias valueLabel: valueLabel.text
    property real value

    signal iconTapped
    signal moved(value: real)

    function updateIcon(): void {
        if (!iconTapEnabled || !transitionIcon || (displayedIcon !== transitionIcon && icon !== transitionIcon)) {
            iconSwap.stop();
            iconShell.scale = 1;
            displayedIcon = icon;
        } else if (displayedIcon !== icon) {
            iconSwap.restart();
        }
    }

    onIconChanged: updateIcon()

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins + rowLayout.anchors.topMargin

    RowLayout {
        id: rowLayout

        anchors.fill: parent
        anchors.margins: Tokens.padding.largeIncreased
        anchors.topMargin: Tokens.padding.large
        spacing: Tokens.spacing.medium

        Item {
            id: iconShell

            Layout.preferredWidth: Math.max(24, iconGlyph.implicitWidth)
            Layout.preferredHeight: Math.max(24, iconGlyph.implicitHeight)
            transformOrigin: Item.Center

            Item {
                anchors.fill: parent
                scale: iconArea.pressed && root.iconTapEnabled ? 0.94 : 1

                Behavior on scale {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                MaterialIcon {
                    id: iconGlyph

                    anchors.centerIn: parent
                    text: root.displayedIcon
                    color: root.nightLightActive ? Qt.tint(Colours.palette.m3onSurfaceVariant, Qt.rgba(0.77, 0.63, 0.49, 0.34)) : Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                }
            }

            SequentialAnimation {
                id: iconSwap

                Anim {
                    target: iconShell
                    property: "scale"
                    to: 0.65
                    duration: Tokens.anim.durations.small / 2
                    easing: Tokens.anim.standardAccel
                }
                ScriptAction {
                    script: root.displayedIcon = root.icon
                }
                Anim {
                    target: iconShell
                    property: "scale"
                    to: 1
                    duration: Tokens.anim.durations.normal / 2
                    easing: Tokens.anim.standardDecel
                }
            }

            MouseArea {
                id: iconArea

                anchors.fill: parent
                enabled: root.iconTapEnabled
                hoverEnabled: root.iconTapEnabled
                cursorShape: Qt.PointingHandCursor
                onClicked: root.iconTapped()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    id: label

                    Layout.fillWidth: true
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    id: valueLabel

                    color: Colours.palette.m3outline
                    font: Tokens.font.body.small
                }
            }

            CustomMouseArea {
                function onWheel(event: WheelEvent): void {
                    if (!root.enabled || !root.sliderEnabled)
                        return;
                    const step = root.wheelStep;
                    if (event.angleDelta.y > 0)
                        root.moved(Math.min(1, root.value + step));
                    else if (event.angleDelta.y < 0)
                        root.moved(Math.max(0, root.value - step));
                }

                Layout.fillWidth: true
                implicitHeight: Tokens.padding.medium * 2

                StyledSlider {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    implicitHeight: parent.implicitHeight

                    radius: Tokens.rounding.small
                    value: root.value
                    enabled: root.enabled && root.sliderEnabled
                    onInteraction: v => root.moved(v)
                }
            }
        }
    }
}
