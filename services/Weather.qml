pragma Singleton

import qs.config
import qs.utils
import Caelestia
import Quickshell
import QtQuick

Singleton {
    id: root

    property string city
    property string loc
    property var cc
    property var forecast

    readonly property string icon: cc ? Icons.getWeatherIcon(cc.weatherCode) : "cloud_alert"
    readonly property string description: cc?.weatherDesc[0].value ?? qsTr("No weather")
    readonly property string temp: Config.services.useFahrenheit ? `${cc?.temp_F ?? 0}°F` : `${cc?.temp_C ?? 0}°C`
    readonly property string feelsLike: Config.services.useFahrenheit ? `${cc?.FeelsLikeF ?? 0}°F` : `${cc?.FeelsLikeC ?? 0}°C`
    readonly property int humidity: cc?.humidity ?? 0
    readonly property real windSpeed: cc?.windSpeed ?? 0.0

    function reload(): void {
        let configLocation = Config.services.weatherLocation;

        if (configLocation && configLocation !== "") {
            if (configLocation.indexOf(",") !== -1 && !isNaN(parseFloat(configLocation.split(",")[0]))) {
                loc = configLocation;
            } else {
                fetchCoordsFromCity(configLocation);
            }
        } 
        else if (!loc || timer.elapsed() > 900) {
            Requests.get("https://ipinfo.io/json", text => {
                const response = JSON.parse(text);
                if (response.loc) {
                    loc = response.loc;
                    city = response.city ?? "";
                    timer.restart();
                }
            });
        }
    }

    function fetchCoordsFromCity(cityName) {
        const url = "https://geocoding-api.open-meteo.com/v1/search?name=" 
                    + encodeURIComponent(cityName) 
                    + "&count=1&language=en&format=json";

        Requests.get(url, text => {
            const json = JSON.parse(text);
            if (json.results && json.results.length > 0) {
                const result = json.results[0];
                loc = result.latitude + "," + result.longitude;
                city = result.name;
            } else {
                loc = ""; 
                reload(); 
            }
        });
    }

    onLocChanged: {
        fetchWeatherData()
    }
    
    function fetchWeatherData() {
        let url = getWeatherUrl();
        if (url === "") return;

        Requests.get(url, text => {
            const json = JSON.parse(text);
            if (!json.current || !json.daily) return;

            cc = {
                "weatherCode": String(json.current.weather_code),
                "weatherDesc": [{ "value": getWeatherCondition(String(json.current.weather_code))}],
                "temp_C": Math.round(json.current.temperature_2m),
                "temp_F": Math.round(json.current.temperature_2m * 9/5 + 32),
                "FeelsLikeC": Math.round(json.current.apparent_temperature),
                "FeelsLikeF": Math.round(json.current.apparent_temperature * 9/5 + 32),
                "humidity": json.current.relative_humidity_2m,
                "windSpeed": json.current.wind_speed_10m,
                "isDay": json.current.is_day,
                "sunrise": Qt.formatDateTime(new Date(json.daily.sunrise[0]), Config.services.useTwelveHourClock ? "h:mm A" : "h:mm"),
                "sunset": Qt.formatDateTime(new Date(json.daily.sunset[0]), Config.services.useTwelveHourClock ? "h:mm A" : "h:mm")
            };

            let forecastList = []
            for (let i = 0; i < json.daily.time.length; i++) {
                forecastList.push({
                    "date": json.daily.time[i],
                    "maxTempC": Math.round(json.daily.temperature_2m_max[i]),
                    "maxTempF": Math.round(json.daily.temperature_2m_max[i] * 9/5 + 32),
                    "minTempC": Math.round(json.daily.temperature_2m_min[i]),
                    "minTempF": Math.round(json.daily.temperature_2m_min[i] * 9/5 + 32),
                    "weatherCode": String(json.daily.weather_code[i]),
                    "icon": Icons.getWeatherIcon(String(json.daily.weather_code[i]))
                });
            }
            forecast = forecastList;
        });
    }

    function getWeatherUrl() {
        if (!loc || loc.indexOf(",") === -1) return "";

        let coords = loc.split(",");
        let lat = coords[0];
        let lon = coords[1];

        const baseUrl = "https://api.open-meteo.com/v1/forecast";
        const params = [
            "latitude=" + lat,
            "longitude=" + lon,
            "daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset",
            "current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m",
            "timezone=auto",
            "forecast_days=7"
        ];

        return baseUrl + "?" + params.join("&");
    }

    function getWeatherCondition(code: string) {
        const conditions = {
            "0": "Clear",
            "1": "Clear",
            "2": "Partly cloudy",
            "3": "Overcast",
            "45": "Fog",
            "48": "Fog",
            "51": "Drizzle",
            "53": "Drizzle",
            "55": "Drizzle",
            "56": "Freezing drizzle",
            "57": "Freezing drizzle",
            "61": "Light rain",
            "63": "Rain",
            "65": "Heavy rain",
            "66": "Light rain",
            "67": "Heavy rain",
            "71": "Light snow",
            "73": "Snow",
            "75": "Heavy snow",
            "77": "Snow",
            "80": "Light rain",
            "81": "Rain",
            "82": "Heavy rain",
            "85": "Light snow showers",
            "86": "Heavy snow showers",
            "95": "Thunderstorm",
            "96": "Thunderstorm with hail",
            "99": "Thunderstorm with hail"
        };
        return conditions[code] || "Unknown";
    }
    // Refresh current location hourly
    Timer {
        interval: 3600000 // 1 hour
        running: true
        repeat: true
        onTriggered: fetchWeatherData()
    }

    ElapsedTimer {
        id: timer
    }
}
