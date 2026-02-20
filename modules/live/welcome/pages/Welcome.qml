import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
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

                VectorImage {
                    Layout.alignment: Qt.AlignHCenter
                    preferredRendererType: VectorImage.CurveRenderer
                    source: Colours.currentLight ? "../../assets/logo-light.svg" : "../../assets/logo-dark.svg"
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Welcome to Caelestia"
                    font.pointSize: Appearance.font.size.extraLarge
                    font.bold: true
                    color: Colours.palette.m3onBackground
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "A modern, beautiful desktop shell for Wayland"
                    font.pointSize: Appearance.font.size.larger
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
