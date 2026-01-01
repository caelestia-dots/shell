pragma Singleton

import qs.config
import qs.utils
import Caelestia
import Quickshell
import QtQuick

Singleton {
    id: root

    property string city
    property var cc
    property var forecast
    readonly property string icon: cc ? Icons.getWeatherIcon(cc.weatherCode) : "cloud_alert"
    readonly property string description: cc?.weatherDesc[0].value ?? qsTr("No weather")
    readonly property string temp: Config.services.useFahrenheit ? `${cc?.temp_F ?? 0}°F` : `${cc?.temp_C ?? 0}°C`
    readonly property string feelsLike: Config.services.useFahrenheit ? `${cc?.FeelsLikeF ?? 0}°F` : `${cc?.FeelsLikeC ?? 0}°C`
    readonly property int humidity: cc?.humidity ?? 0

    function reload(): void {
        if (Config.services.weatherLocation)
            city = Config.services.weatherLocation;
        else if (!city || timer.elapsed() > 900)
            Requests.get("https://ipinfo.io/json", text => {
                city = JSON.parse(text).city ?? "";
                timer.restart();
            });
    }

    onCityChanged: Requests.get(`https://wttr.in/${city}?format=j1`, text => {
        const json = JSON.parse(text);
        cc = json.current_condition[0];
        forecast = json.weather;
    })

    ElapsedTimer {
        id: timer
    }
}
