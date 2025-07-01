pragma Singleton

import "root:/config"
import "root:/utils"
import Quickshell
import QtQuick

Singleton {
    id: root

    property string loc
    property bool useFahrenheit 
    property string icon
    property string description
    property string temperature

    function reload(): void {
        useFahrenheit = Config.dashboard.useFahrenheit
        if (Config.dashboard.weatherLocation)
            loc = Config.dashboard.weatherLocation;
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
        temperature = useFahrenheit ? `${parseFloat(json.temp_F)}°F` : `${parseFloat(json.temp_C)}°C`;
    })

    Component.onCompleted: reload()

    ElapsedTimer {
        id: timer
    }
}
