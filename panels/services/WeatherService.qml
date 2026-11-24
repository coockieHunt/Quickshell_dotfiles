import Quickshell
import QtQuick
import "../../theme"

Scope {
    id: root

    property real latitude: Theme.weather.latitude
    property real longitude: Theme.weather.longitude

    readonly property bool active: Theme.weather.enabled && Theme.configRevision > 0

    property bool available: false

    property real temperature: 0
    property real feelsLike: 0
    property real humidity: 0
    property real windSpeed: 0
    property int weatherCode: 0
    property bool isDay: true

    property var daily: []

    readonly property string temperatureText: Math.round(temperature) + "°"
    readonly property string feelsLikeText: Math.round(feelsLike) + "°"
    readonly property string humidityText: Math.round(humidity) + " %"
    readonly property string windText: Math.round(windSpeed) + " km/h"
    readonly property string icon: iconFor(weatherCode, isDay)
    readonly property string description: descriptionFor(weatherCode)

    function iconFor(code, day) {
        if (code === 0)
            return day ? "clear_day" : "clear_night"
        if (code === 1 || code === 2)
            return day ? "partly_cloudy_day" : "partly_cloudy_night"
        if (code === 3)
            return "cloud"
        if (code === 45 || code === 48)
            return "foggy"
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82))
            return "rainy"
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return "weather_snowy"
        if (code >= 95)
            return "thunderstorm"
        return "cloud"
    }

    function descriptionFor(code) {
        switch (code) {
        case 0: return "Ciel dégagé"
        case 1: return "Plutôt dégagé"
        case 2: return "Partiellement nuageux"
        case 3: return "Couvert"
        case 45:
        case 48: return "Brouillard"
        case 51:
        case 53:
        case 55: return "Bruine"
        case 56:
        case 57: return "Bruine verglaçante"
        case 61: return "Pluie faible"
        case 63: return "Pluie"
        case 65: return "Forte pluie"
        case 66:
        case 67: return "Pluie verglaçante"
        case 71: return "Neige faible"
        case 73: return "Neige"
        case 75: return "Forte neige"
        case 77: return "Grains de neige"
        case 80: return "Averses faibles"
        case 81: return "Averses"
        case 82: return "Fortes averses"
        case 85:
        case 86: return "Averses de neige"
        case 95: return "Orage"
        case 96:
        case 99: return "Orage avec grêle"
        default: return "Conditions inconnues"
        }
    }

    function refresh() {
        if (!root.active)
            return

        const url = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + latitude
            + "&longitude=" + longitude
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,"
            + "weather_code,is_day,wind_speed_10m"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,"
            + "precipitation_probability_max"
            + "&forecast_days=6"
            + "&timezone=auto"

        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== 4)
                return

            if (xhr.status !== 200) {
                console.warn("Météo indisponible (HTTP " + xhr.status + ")")
                retryTimer.restart()
                return
            }

            try {
                const json = JSON.parse(xhr.responseText)
                const current = json.current

                root.temperature = current.temperature_2m
                root.feelsLike = current.apparent_temperature
                root.humidity = current.relative_humidity_2m
                root.windSpeed = current.wind_speed_10m
                root.weatherCode = current.weather_code
                root.isDay = current.is_day === 1

                const d = json.daily
                const days = []
                if (d && d.time) {
                    for (let i = 0; i < d.time.length; i++) {
                        days.push({
                            date: d.time[i],
                            code: d.weather_code[i],
                            min: d.temperature_2m_min[i],
                            max: d.temperature_2m_max[i],
                            rain: d.precipitation_probability_max[i]
                        })
                    }
                }
                root.daily = days

                root.available = true
            } catch (error) {
                console.warn("Réponse météo illisible:", error)
                retryTimer.restart()
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    onActiveChanged: {
        if (active)
            fetchSoon.restart()
        else
            available = false
    }

    onLatitudeChanged: if (active) fetchSoon.restart()
    onLongitudeChanged: if (active) fetchSoon.restart()

    Timer {
        id: fetchSoon
        interval: 500
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        interval: Theme.weather.refreshMinutes * 60 * 1000
        running: root.active
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: retryTimer
        interval: 2 * 60 * 1000
        repeat: false
        onTriggered: root.refresh()
    }
}
