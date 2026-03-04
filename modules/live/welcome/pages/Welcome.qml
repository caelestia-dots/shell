import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.components.containers
import qs.config

Item {
    id: root

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
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Welcome to Caelestia")
                    font.pointSize: Appearance.font.size.extraLarge
                    font.bold: true
                    color: Colours.palette.m3onBackground
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("A modern, beautiful desktop shell for Wayland")
                    font.pointSize: Appearance.font.size.larger
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
