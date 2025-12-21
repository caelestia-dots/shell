import "."
import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

FloatingWindow {
    id: win

    required property ShellScreen screen

    property string activeSection: "appearance"

    color: Colours.tPalette.m3surface
    visible: ConfigEditor.visible

    onVisibleChanged: {
        if (!visible) {
            ConfigEditor.hide();
        }
    }

    minimumSize.width: 1000
    minimumSize.height: 700

    implicitWidth: 1200
    implicitHeight: 800

    title: qsTr("Caelestia Configuration Editor")

    RowLayout {
        anchors.fill: parent
        spacing: 0

        NavRail {
            id: navRail

            Layout.fillHeight: true
            Layout.preferredWidth: implicitWidth

            activeSection: win.activeSection
            onActiveSectionChanged: win.activeSection = activeSection
        }

        ConfigPane {
            id: configPane

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Appearance.padding.large

            activeSection: win.activeSection
        }
    }

    Behavior on color {
        CAnim {}
    }
}
