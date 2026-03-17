import Quickshell.Io

JsonObject {
    property bool borderHover: true
    property int thinkness: Appearance.padding.normal
    readonly property int minThickness: !borderHover ? 0 : 2
    readonly property int thickness: Math.max(thinkness, minThickness)
    property int rounding: Appearance.rounding.large
}
