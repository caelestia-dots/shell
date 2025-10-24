import Quickshell.Io

JsonObject {
    property bool enabled: true
    property string model: "gemini-2.0-flash"
    property string tool: "search"
    property real temperature: 0.5
    property string systemPrompt: ""
    property list<var> extraModels: []

    // Policies
    property PolicyConfig policies: PolicyConfig {}

    component PolicyConfig: JsonObject {
        // 0 = allow all, 1 = warn for online, 2 = block online models
        property int restrictOnlineModels: 0
    }
}
