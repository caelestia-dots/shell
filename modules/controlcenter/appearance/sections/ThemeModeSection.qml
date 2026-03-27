pragma ComponentBehavior: Bound

import ".."
import QtQuick
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.config

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
