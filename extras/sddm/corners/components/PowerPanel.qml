// qmllint disable unqualified
// qmllint disable Quick.property-changes-parsed
// qmllint disable unresolved-type
// qmllint disable incompatible-type

import QtQuick 2.15
import QtQuick.Controls 2.15

import QtGraphicalEffects 1.15

Item {
    implicitHeight: powerButton.height
    implicitWidth: powerButton.width

    ListModel {
        id: powerModel

        ListElement {
            name: "Sleep"
        }

        ListElement {
            name: "Restart"
        }

        ListElement {
            name: "Shut\nDown"
        }
    }

    Button {
        id: powerButton

        icon {
            source: Qt.resolvedUrl("../icons/power.svg")
            height: height
            width: width
            color: config.PowerIconColor
        }

        height: inputHeight
        width: inputHeight
        hoverEnabled: true

        onClicked: {
            powerPopup.visible ? powerPopup.close() : powerPopup.open();
            powerButton.state = "pressed";
        }

        states: [
            State {
                name: "pressed"
                when: powerButton.down

                PropertyChanges {
                    target: powerButtonBg
                    color: Qt.darker(config.PowerButtonColor, 1.2)
                }
            },
            State {
                name: "hovered"
                when: powerButton.hovered

                PropertyChanges {
                    target: powerButtonBg
                    color: Qt.darker(config.PowerButtonColor, 1.2)
                }
            },
            State {
                name: "selection"
                when: powerPopup.visible

                PropertyChanges {
                    target: powerButtonBg
                    color: Qt.darker(config.PowerButtonColor, 1.2)
                }
            }
        ]

        background: Rectangle {
            id: powerButtonBg

            color: config.PowerButtonColor

            radius: config.Radius
        }

        transitions: Transition {
            PropertyAnimation {
                properties: "color"
                duration: 150
            }
        }
    }

    Popup {
        id: powerPopup

        height: inputHeight * 2.2 + padding * 2
        x: powerButton.width + powerList.spacing
        y: -height + powerButton.height
        padding: 15

        background: Rectangle {
            radius: config.Radius * 1.8
            color: config.PopupColor
        }

        contentItem: ListView {
            id: powerList

            implicitWidth: contentWidth
            spacing: 8
            orientation: Qt.Horizontal
            clip: true
            model: powerModel

            delegate: ItemDelegate {
                id: powerEntry

                height: inputHeight * 2.2
                width: inputHeight * 2.2
                display: AbstractButton.TextUnderIcon

                states: [
                    State {
                        name: "hovered"
                        when: powerEntry.hovered

                        PropertyChanges {
                            target: powerEntryBg
                            color: Qt.darker(config.PopupActiveColor, 1.2)
                        }

                        PropertyChanges {
                            target: iconOverlay
                            color: Qt.darker(config.PopupActiveColor, 1.2)
                        }

                        PropertyChanges {
                            target: powerText
                            opacity: 1
                        }
                    }
                ]

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        powerPopup.close();

                        if (index === 0) {
                            sddm.suspend();
                        } else if (index === 1) {
                            sddm.reboot();
                        } else if (index === 2) {
                            sddm.powerOff();
                        }
                    }
                }

                contentItem: Item {
                    Image {
                        id: powerIcon

                        anchors.centerIn: parent
                        source: index == 0 ? Qt.resolvedUrl("../icons/sleep.svg") : (index == 1 ? Qt.resolvedUrl("../icons/restart.svg") : Qt.resolvedUrl("../icons/power.svg"))
                        sourceSize: Qt.size(powerEntry.width * 0.5, powerEntry.height * 0.5)
                    }

                    ColorOverlay {
                        id: iconOverlay

                        anchors.fill: powerIcon
                        source: powerIcon
                        color: config.PopupColor
                    }

                    Text {
                        id: powerText

                        font {
                            family: config.FontFamily
                            pointSize: config.FontSize
                            bold: true
                        }

                        anchors.centerIn: parent
                        renderType: Text.NativeRendering
                        horizontalAlignment: Text.AlignHCenter
                        color: config.PopupColor
                        text: name
                        opacity: 0
                    }
                }

                background: Rectangle {
                    id: powerEntryBg

                    color: config.PopupActiveColor
                    radius: config.Radius
                }

                transitions: Transition {
                    PropertyAnimation {
                        properties: "color, opacity"
                        duration: 150
                    }
                }
            }
        }

        enter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 400
                    easing.type: Easing.OutExpo
                }

                NumberAnimation {
                    property: "x"
                    from: powerPopup.x - (inputWidth * 0.1)
                    to: powerPopup.x
                    duration: 500
                    easing.type: Easing.OutExpo
                }
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 300
                easing.type: Easing.OutExpo
            }
        }
    }
}
