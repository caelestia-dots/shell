import QtQuick
import qs.services

// StepperRow bound to a NotchSettings key
StepperRow {
    required property string key

    value: NotchSettings.values[key] ?? 0
    onMoved: v => NotchSettings.set(key, v)
}
