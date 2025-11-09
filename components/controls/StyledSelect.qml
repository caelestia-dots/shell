import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Templates
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

// Used the following source as a template:
// https://stackoverflow.com/questions/9634897/qt-qml-dropdown-list-like-in-html
// Posted by Paul Drummond
// Retrieved 2025-11-08, License - CC BY-SA 3.0
Rectangle {
    id: root
    required property list<string> items
    required property int defIndex
    property alias selectedItem: chosenItemText.text
    property alias selectedIndex: listView.currentIndex
    signal optionClicked(index: int)
    height: 30
    color: "transparent"

    Rectangle {
        id: chosenItem
        border.color: Colours.palette.m3outline
        border.width: 1
        radius: Appearance.rounding.normal
        width: parent.width
        height: root.height
        color: Colours.palette.m3surfaceContainer

        StyledText {
            id: chosenItemText
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 6
            anchors.leftMargin: 12
            anchors.rightMargin: 16
            elide: Text.ElideRight
            text: root.items[root.defIndex]
        }

        WrapperMouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                dropDown.open()
            }
        }
    }

    Popup {
        id: dropDown
        width: root.width
        height: 120
        clip: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.small
            color: Colours.palette.m3surfaceContainer
            ListView {
                id: listView
                height: dropDown.height;
                model: root.items
                currentIndex: 0

                delegate: Rectangle {
                    width: root.width
                    height: root.height
                    radius: Appearance.rounding.small
                    color: dropDownMa.containsMouse ? Colours.palette.m3outline : "transparent"

                    StyledText {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 5
                        elide: Text.ElideRight
                        text: modelData
                    }
                    WrapperMouseArea {
                        id: dropDownMa
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            root.state = "";
                            var prevSelection = chosenItemText.text;
                            chosenItemText.text = modelData;
                            if(chosenItemText.text != prevSelection){
                                root.optionClicked(index);
                            }
                            listView.currentIndex = index;
                            dropDown.close()
                        }
                    }
                }
            }
        }
        onVisibleChanged: {
            if (dropDown.visible) {
                dropDown.x = chosenItem.x;
                dropDown.y = chosenItem.y + chosenItem.height + Appearance.spacing.small;
            }
        }
    }
}
