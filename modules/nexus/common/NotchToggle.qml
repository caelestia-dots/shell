import QtQuick
import qs.services

// ToggleRow bound to a NotchSettings key
ToggleRow {
    required property string key

    checked: NotchSettings.values[key] ?? false
    onToggled: NotchSettings.set(key, checked)
}
