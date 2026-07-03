import "cards"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property var props
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property matrix4x4 deformMatrix

    readonly property real nonAnimHeight: idleInhibit.nonAnimHeight + record.nonAnimHeight + toggles.implicitHeight + layout.spacing * 2

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        IdleInhibit {
            id: idleInhibit

            objectName: "utilities-keep-awake"
        }

        Record {
            id: record

            objectName: "utilities-screen-recorder"

            props: root.props
            screenState: root.screenState
            z: 1
        }

        Toggles {
            id: toggles

            objectName: "utilities-quick-toggles"

            screenState: root.screenState
            popouts: root.popouts
        }
    }

    RecordingDeleteModal {
        props: root.props
        deformMatrix: root.deformMatrix
    }
}
