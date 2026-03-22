import "cards"
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property var props
    required property DrawerVisibilities visibilities
    required property BarPopouts.Wrapper popouts

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
            popouts: root.popouts
        }
    }

    RecordingDeleteModal {
        props: root.props
    }
}
