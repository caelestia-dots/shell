pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.config
import qs.modules.controlcenter.appearance

CollapsibleSection {
    title: qsTr("Theme mode")
    description: qsTr("Light or dark theme")
    showBackground: true

    SwitchRow {
        label: qsTr("Dark mode")
        checked: !Colours.currentLight
        onToggled: checked => {
            Colours.setMode(checked ? "dark" : "light");
        }
    }
}
