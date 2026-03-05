import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.components.live
import qs.components.containers
import qs.config

Item {
    id: root

    property bool animationHasRun: false
    signal animationCompleted()

    StyledFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: Math.max(contentColumn.implicitHeight, flickable.height)
        flickableDirection: Flickable.VerticalFlick

        ColumnLayout {
            id: contentColumn
            width: parent.width
            height: Math.max(implicitHeight, flickable.height)
            spacing: Appearance.padding.large

            Item { Layout.fillHeight: true }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                LogoIntro {
                    Layout.alignment: Qt.AlignHCenter
                    skipIntroAnimation: root.animationHasRun
                    onAnimationCompleted: root.animationCompleted()
                }

                StyledText {
                    id: title

                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Welcome to Caelestia")
                    font.pointSize: Appearance.font.size.extraLarge
                    font.bold: true
                    color: Colours.palette.m3onBackground
                    opacity: root.animationHasRun ? 1.0 : 0.0
                }

                StyledText {
                    id: subtitle

                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("A modern, beautiful desktop shell for Wayland")
                    font.pointSize: Appearance.font.size.larger
                    color: Colours.palette.m3onSurfaceVariant
                    opacity: root.animationHasRun ? 1.0 : 0.0
                }

                SequentialAnimation {
                    running: !root.animationHasRun

                    PauseAnimation { duration: 1500 }

                    NumberAnimation {
                        target: title
                        property: "opacity"
                        from: 0.0
                        to: 1.0
                        duration: 700
                        easing.type: Easing.InOutQuad
                    }

                    NumberAnimation {
                        target: subtitle
                        property: "opacity"
                        from: 0.0
                        to: 1.0
                        duration: 700
                        easing.type: Easing.InOutQuad
                    }

                    onFinished: {
                        root.animationCompleted()
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
