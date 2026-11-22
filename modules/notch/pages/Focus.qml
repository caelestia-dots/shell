import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.hallownest
import qs.modules.notch

NotchPage {
    id: root

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        spacing: Tokens.spacing.small + 2

        Pomodoro {
            Layout.fillWidth: true
            screenState: root.screenState
            page: root.page
        }

        HkDivider {
            Layout.fillWidth: true
            opacity: 0.55
        }

        Todo {
            Layout.fillWidth: true
            screenState: root.screenState
            page: root.page
        }
    }
}
