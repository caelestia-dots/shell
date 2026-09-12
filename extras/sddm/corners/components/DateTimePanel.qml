// qmllint disable unqualified

import QtQuick 2.15

Item {
    id: dtRoot

    implicitWidth: timeRow.implicitWidth
    implicitHeight: timeRow.implicitHeight + dateLabel.implicitHeight + 10 * config.Scale

    Component.onCompleted: {
        updateTime();
        dateLabel.updateDate();
    }

    function updateTime() {
        const now = new Date();
        hourLabel.text = Qt.formatTime(now, "hh");
        minuteLabel.text = Qt.formatTime(now, "mm");
        amPmLabel.text = Qt.formatTime(now, "AP");
    }

    Row {
        id: timeRow

        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10 * config.Scale

        Text {
            id: hourLabel
            font {
                family: "Rubik"
                pointSize: Number(config.ClockHourSize)
                bold: true
            }

            color: config.TimeColor
            opacity: config.TimeOpacity
            renderType: Text.NativeRendering
        }

        Column {
            spacing: -8 * config.Scale

            Text {
                id: minuteLabel

                anchors.horizontalCenter: parent.horizontalCenter
                font {
                    family: "Rubik"
                    pointSize: Number(config.ClockMinuteSize)
                    bold: true
                }
                color: config.TimeSecondaryColor
                renderType: Text.NativeRendering
            }

            Rectangle {
                width: amPmLabel.implicitWidth + 18 * config.Scale
                height: amPmLabel.implicitHeight + 8 * config.Scale
                anchors.horizontalCenter: parent.horizontalCenter
                radius: height / 2
                color: config.ClockChipColor

                Text {
                    id: amPmLabel

                    anchors.centerIn: parent
                    font {
                        family: "Rubik"
                        pointSize: Number(config.ClockAmPmSize)
                        bold: true
                    }
                    color: config.ClockChipTextColor
                    renderType: Text.NativeRendering
                }
            }
        }
    }

    Text {
        id: dateLabel
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: timeRow.bottom
            topMargin: 10 * config.Scale
        }

        function updateDate() {
            text = new Date().toLocaleDateString(Qt.locale(), config.DateFormat).toUpperCase();
        }

        font {
            family: "Google Sans Flex"
            pointSize: config.DateSize
            bold: config.DateIsBold === "true"
            letterSpacing: 1.2
        }

        opacity: config.DateOpacity
        renderType: Text.NativeRendering
        color: config.DateColor
    }

    Timer {
        interval: 1000
        repeat: true
        running: true

        onTriggered: {
            dtRoot.updateTime();
            dateLabel.updateDate();
        }
    }
}
