import Quickshell.Io
import qs.config

JsonObject {
    property int thickness: Config.appearance.padding.normal
    property int rounding: Config.appearance.rounding.large

    readonly property int minThickness: 2
    readonly property int clampedThickness: Math.max(minThickness, thickness)
}
