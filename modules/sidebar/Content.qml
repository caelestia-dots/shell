import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Props props
    required property var visibilities

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Appearance.spacing.normal

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainerLow

            NotifDock {
                props: root.props
                visibilities: root.visibilities
            }
        }

        StyledRect {
            Layout.topMargin: Appearance.padding.large - layout.spacing
            Layout.fillWidth: true
            implicitHeight: 1

            color: Colours.tPalette.m3outlineVariant
        }
    }
}
