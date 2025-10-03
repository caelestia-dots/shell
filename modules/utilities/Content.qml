import "cards" as UtilCards
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var props
    required property var visibilities

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Appearance.spacing.normal

    UtilCards.IdleInhibit {}

        // Combined media card: Screenshots + Recordings in tabs
        UtilCards.Media {
            props: root.props
            visibilities: root.visibilities
            z: 1
        }

        UtilCards.Toggles {
            visibilities: root.visibilities
        }
    }

    RecordingDeleteModal {
        props: root.props
    }

    ScreenshotDeleteModal {
        props: root.props
    }
}
