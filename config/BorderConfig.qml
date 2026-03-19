import Quickshell.Io

JsonObject {
    property int thickness: Appearance.padding.normal
    property int rounding: Appearance.rounding.large

    readonly property int minThickness: 2
    readonly property int clampedThickness: Math.max(minThickness, thickness)
}
