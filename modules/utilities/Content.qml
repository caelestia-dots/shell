import "cards"
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

        IdleInhibit {}

        Record {
            props: root.props
            visibilities: root.visibilities
            z: 1
        }

        Toggles {
            visibilities: root.visibilities
        }
    }

    RecordingDeleteModal {
        props: root.props
    }
}
