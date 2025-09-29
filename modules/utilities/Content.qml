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

        IdleInhibit {
            visible: Config.general.idle.enabled
            Layout.preferredHeight: Config.general.idle.enabled ? implicitHeight : 0
            Layout.fillHeight: Config.general.idle.enabled
        }

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
