// qmllint disable unqualified
// qmllint disable Quick.property-changes-parsed

import QtQuick 2.15
import QtQuick.Controls 2.15

import QtQml.Models 2.15

Item {
    property int session: sessionList.currentIndex

    implicitHeight: sessionButton.height
    implicitWidth: sessionButton.width

    DelegateModel {
        id: sessionWrapper

        model: sessionModel

        delegate: ItemDelegate {
            id: sessionEntry

            height: inputHeight
            width: parent.width
            highlighted: sessionList.currentIndex === index

            states: [
                State {
                    name: "hovered"
                    when: sessionEntry.hovered

                    PropertyChanges {
                        target: sessionEntryBg
                        color: highlighted ? Qt.darker(config.PopupActiveColor, 1.2) : Qt.darker(config.PopupColor, 1.2)
                    }
                }
            ]

            MouseArea {
                anchors {
                    fill: parent
                }

                onClicked: {
                    sessionList.currentIndex = index;
                    sessionPopup.close();
                }
            }

            contentItem: Text {
                font {
                    family: config.FontFamily
                    pointSize: config.FontSize
                    bold: true
                }

                renderType: Text.NativeRendering
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: highlighted ? config.PopupActiveTextColor : config.PopupActiveColor
                text: name
            }

            background: Rectangle {
                id: sessionEntryBg

                color: highlighted ? config.PopupActiveColor : config.PopupColor
                radius: config.Radius
            }

            transitions: Transition {
                PropertyAnimation {
                    property: "color"
                    duration: 150
                }
            }
        }
    }

    Button {
        id: sessionButton

        icon {
            source: Qt.resolvedUrl("../icons/settings.svg")
            height: height * 0.6
            width: width * 0.6
            color: config.SessionIconColor
        }

        height: inputHeight
        width: inputHeight
        hoverEnabled: true

        onClicked: {
            sessionPopup.visible ? sessionPopup.close() : sessionPopup.open();
            sessionButton.state = "pressed";
        }

        states: [
            State {
                name: "pressed"
                when: sessionButton.down

                PropertyChanges {
                    target: sessionButtonBg
                    color: Qt.darker(config.SessionButtonColor, 1.2)
                }
            },
            State {
                name: "hovered"
                when: sessionButton.hovered

                PropertyChanges {
                    target: sessionButtonBg
                    color: Qt.darker(config.SessionButtonColor, 1.2)
                }
            },
            State {
                name: "selection"
                when: sessionPopup.visible

                PropertyChanges {
                    target: sessionButtonBg
                    color: Qt.darker(config.SessionButtonColor, 1.2)
                }
            }
        ]

        background: Rectangle {
            id: sessionButtonBg

            color: config.SessionButtonColor

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
        id: sessionPopup

        width: inputWidth + padding * 2
        x: sessionButton.width + sessionList.spacing
        y: -(contentHeight + padding * 2) + sessionButton.height
        padding: 15

        background: Rectangle {
            radius: config.Radius * 1.8
            color: config.PopupColor
        }

        contentItem: ListView {
            id: sessionList

            implicitHeight: contentHeight
            spacing: 8
            model: sessionWrapper
            currentIndex: sessionModel.lastIndex
            clip: true
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
                    from: sessionPopup.x - (inputWidth * 0.1)
                    to: sessionPopup.x
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
