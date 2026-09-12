import QtQuick 2.15
import QtQuick.Controls 2.15
// qmllint disable unqualified

import QtGraphicalEffects 1.12

TextField {
    id: usernameField

    height: inputHeight
    width: inputWidth
    selectByMouse: true
    leftPadding: 56 * config.Scale
    rightPadding: 12 * config.Scale

    font {
        family: config.FontFamily
        pointSize: config.FontSize
        bold: true
    }

    text: userModel.lastUser
    placeholderText: config.UserPlaceholderText
    horizontalAlignment: Text.AlignLeft

    color: config.InputTextColor
    selectionColor: config.InputTextColor
    renderType: Text.NativeRendering

    background: Item {
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: usernameField.activeFocus ? 2 : 1
            radius: height / 2
            color: usernameField.activeFocus ? config.InputBorderColor : config.DateColor
            opacity: usernameField.activeFocus ? 1 : 0.55

            Behavior on height {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            width: 40 * config.Scale
            height: width
            radius: width / 2
            color: config.ClockChipColor

            Text {
                anchors.centerIn: parent
                text: "person"
                color: config.DateColor
                font {
                    family: "Material Symbols Rounded"
                    pointSize: 20 * config.Scale
                }
                renderType: Text.NativeRendering
            }
        }
    }

    transitions: Transition {
        PropertyAnimation {
            properties: "color, border.width"
            duration: 150
        }
    }
}
