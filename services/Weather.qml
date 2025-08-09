pragma Singleton

import qs.config
import qs.utils
import Quickshell
import QtQuick

Singleton {
    id: root

    property string loc
    property string icon
    property string description
    property string tempC: "0°C"
    property string tempF: "0°F"

    function reload(): void {
        if (Config.services.weatherLocation)
            loc = Config.services.weatherLocation;
        else if (!loc || timer.elapsed() > 900)
            Requests.get("https://ipinfo.io/json", text => {
                loc = JSON.parse(text).loc ?? "";
                timer.restart();
            });
    }

    onLocChanged: Requests.get(`https://wttr.in/${loc}?format=j1`, text => {
        const json = JSON.parse(text).current_condition[0];
        icon = Icons.getWeatherIcon(json.weatherCode);
        description = json.weatherDesc[0].value;
        tempC = `${parseFloat(json.temp_C)}°C`;
        tempF = `${parseFloat(json.temp_F)}°F`;
    })

    Component.onCompleted: reload()

    ElapsedTimer {
        id: timer
    }
}
