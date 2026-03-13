import Quickshell.Io
import QtQuick

JsonObject {
    property string weatherLocation: "" // A lat,long pair or empty for autodetection, e.g. "37.8267,-122.4233"
    property bool useFahrenheit: [Locale.ImperialUSSystem, Locale.ImperialSystem].includes(Qt.locale().measurementSystem)
    property bool useFahrenheitPerformance: [Locale.ImperialUSSystem, Locale.ImperialSystem].includes(Qt.locale().measurementSystem)
    property bool useTwelveHourClock: Qt.locale().timeFormat(Locale.ShortFormat).toLowerCase().includes("a")
    property string gpuType: ""
    property int visualiserBars: 45
    property real audioIncrement: 0.1
    property real brightnessIncrement: 0.1
    property real maxVolume: 1.0
    property bool smartScheme: true
    property string defaultPlayer: "Spotify"
    property list<var> playerAliases: [
        {
            "from": "com.github.th_ch.youtube_music",
            "to": "YT Music"
        }
    ]
    property GCalendarConfig calendar: GCalendarConfig {}

    component GCalendarConfig: JsonObject {
        property bool enabled: false // Requires gws CLI in PATH
        property string command: "gws" // Path or name of the gws CLI binary
        property int agendaDays: 30 // How many days ahead to fetch events
        property int upcomingHours: 24 // Hours ahead to show in upcoming list
        property int reminderMinutes: 10 // Minutes before event to send notification, 0 to disable
        property int refreshInterval: 900 // Refresh interval in seconds
    }
}
