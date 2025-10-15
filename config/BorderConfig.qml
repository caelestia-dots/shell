import Quickshell.Io

JsonObject {
    property int thickness: Appearance.padding.normal
    property int fullscreenThickness: 0
    property int rounding: Appearance.rounding.large

    function effectiveThickness(hasFullscreen: bool): int {
        return hasFullscreen ? fullscreenThickness : thickness;
    }
}
