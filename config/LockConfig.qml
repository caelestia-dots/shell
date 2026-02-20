import Quickshell.Io

JsonObject {
    property bool recolourLogo: false
    property bool enableFprint: true
    property int maxFprintTries: 3

    property list<string> verticalScreens
    property list<string> excludedScreens

    property Sizes sizes: Sizes {}

    component Sizes: JsonObject {
        property real heightMult: 0.82
        property real ratio: 16 / 9
        property real ratioVertical: 9 / 16
        property int centerWidth: 600
    }
}
