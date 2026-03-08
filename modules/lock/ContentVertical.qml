import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    required property var lock

    readonly property int gap: Appearance.spacing.normal
    spacing: gap

    readonly property int screenH: (lock.screen?.height ?? 900)

    readonly property int fetchH: Math.round(screenH * 0.13)
    readonly property int mediaH: Math.round(screenH * 0.105)
    readonly property int resourcesH: Math.round(screenH * 0.055)

    readonly property int middleH: fetchH + gap + mediaH
    readonly property int notifsH: Math.max(1, middleH - resourcesH - gap)

    Center {
        lock: root.lock
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        Layout.fillHeight: false
        Layout.bottomMargin: Appearance.spacing.large
    }

    RowLayout {
        id: middle
        Layout.fillWidth: true
        Layout.fillHeight: false
        implicitHeight: middleH
        spacing: gap

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: gap

            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: false
                implicitHeight: fetchH

                topLeftRadius: Appearance.rounding.large
                radius: Appearance.rounding.small
                color: Colours.tPalette.m3surfaceContainer

                Item {
                    anchors.fill: parent
                    Fetch { anchors.fill: parent }
                }
            }

            StyledClippingRect {
                Layout.fillWidth: true
                Layout.fillHeight: false
                implicitHeight: mediaH

                radius: Appearance.rounding.small
                color: Colours.tPalette.m3surfaceContainer

                Media { lock: root.lock }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: gap

            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: false
                implicitHeight: resourcesH

                topRightRadius: Appearance.rounding.large
                radius: Appearance.rounding.small
                color: Colours.tPalette.m3surfaceContainer

                Item {
                    anchors.fill: parent
                    clip: true
                    ResourcesVertical { anchors.fill: parent }
                }
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: false
                implicitHeight: notifsH

                bottomRightRadius: Appearance.rounding.large
                radius: Appearance.rounding.small
                color: Colours.tPalette.m3surfaceContainer

                Item {
                    anchors.fill: parent
                    NotifDock { lock: root.lock; anchors.fill: parent }
                }
            }
        }
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.fillHeight: false
        implicitHeight: weather.implicitHeight

        bottomLeftRadius: Appearance.rounding.large
        bottomRightRadius: Appearance.rounding.large
        radius: Appearance.rounding.small
        color: Colours.tPalette.m3surfaceContainer

        Item {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large

            WeatherInfo {
                id: weather
                anchors.centerIn: parent
                width: parent.width
                height: implicitHeight
                rootHeight: root.height
            }
        }
    }
}
