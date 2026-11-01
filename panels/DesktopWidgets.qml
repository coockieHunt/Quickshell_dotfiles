// Used by: 1 file(s)
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "../theme"

Scope {
    id: root

    readonly property string position: Theme.desktopWidgetPosition
    readonly property int widgetMargin: Theme.desktopWidgetMargin
    readonly property string location: Theme.weatherLocation
    readonly property real latitude: Theme.weatherLatitude
    readonly property real longitude: Theme.weatherLongitude
    readonly property int weatherRefreshMinutes: Theme.weatherRefreshMinutes
    readonly property int statsRefreshSeconds: Theme.statsRefreshSeconds
    readonly property int networkRefreshSeconds: Theme.networkRefreshSeconds
    property string weatherTemperature: "--°"
    property string weatherDescription: "Chargement..."
    property string weatherIcon: "cloud"
    property bool weatherAvailable: false
    property real cpuUsage: 0
    property real previousCpuTotal: 0
    property real previousCpuIdle: 0
    property real memoryUsed: 0
    property real memoryTotal: 0
    property bool hasCpuSample: false
    property string networkStatus: "Vérification..."

    function refreshWeather() {
        if (!weatherProcess.running)
            weatherProcess.running = true
    }

    function updateWeather(output) {
        try {
            const data = JSON.parse(output)
            const current = data.current
            if (!current || !Number.isFinite(Number(current.temperature_2m))
                    || !Number.isFinite(Number(current.weather_code))) {
                throw new Error("Réponse météo incomplète")
            }

            const code = Number(current.weather_code)
            weatherTemperature = `${Math.round(Number(current.temperature_2m))}°`
            weatherIcon = code === 0 ? "sunny"
                : code <= 2 ? "partly_cloudy_day"
                : code === 3 ? "cloud"
                : code <= 48 ? "foggy"
                : code <= 67 ? "rainy"
                : code <= 77 ? "weather_snowy"
                : code <= 82 ? "rainy"
                : code <= 86 ? "weather_snowy"
                : "thunderstorm"
            weatherDescription = code === 0 ? "Ciel dégagé"
                : code === 1 ? "Peu nuageux"
                : code === 2 ? "Partiellement nuageux"
                : code === 3 ? "Couvert"
                : code <= 48 ? "Brouillard"
                : code <= 67 ? "Pluie"
                : code <= 77 ? "Neige"
                : code <= 82 ? "Averses"
                : code <= 86 ? "Averses de neige"
                : "Orage"
            weatherAvailable = true
        } catch (error) {
            weatherAvailable = false
            weatherDescription = "Météo indisponible"
            console.warn("Impossible de lire la météo:", error)
        }
    }

    function updateStats(output) {
        const lines = output.trim().split("\n")
        if (lines.length === 0 || !lines[0].startsWith("cpu ")) {
            console.warn("Lecture des statistiques système invalide")
            return
        }

        const cpuFields = lines[0].trim().split(/\s+/).slice(1, 9).map(Number)
        if (cpuFields.length === 8 && cpuFields.every(Number.isFinite)) {
            const total = cpuFields.reduce((sum, value) => sum + value, 0)
            const idle = cpuFields[3] + cpuFields[4]
            if (hasCpuSample) {
                const totalDelta = total - previousCpuTotal
                const idleDelta = idle - previousCpuIdle
                if (totalDelta > 0)
                    cpuUsage = Math.max(0, Math.min(100, (totalDelta - idleDelta) / totalDelta * 100))
            }
            previousCpuTotal = total
            previousCpuIdle = idle
            hasCpuSample = true
        }

        let totalMemory = 0
        let availableMemory = 0
        for (const line of lines) {
            if (line.startsWith("MemTotal:"))
                totalMemory = Number(line.split(/\s+/)[1])
            else if (line.startsWith("MemAvailable:"))
                availableMemory = Number(line.split(/\s+/)[1])
        }
        if (totalMemory > 0 && Number.isFinite(availableMemory)) {
            memoryTotal = totalMemory
            memoryUsed = Math.max(0, totalMemory - availableMemory)
        } else {
            console.warn("Impossible de lire la mémoire système")
        }
    }

    function updateNetwork(output) {
        const connections = output.trim().split("\n").filter(line => line.length > 0)
        for (const line of connections) {
            const fields = line.split(":")
            if (fields.length < 4)
                continue
            const type = fields[1]
            const state = fields[2]
            const name = fields.slice(3).join(":").replace(/\\:/g, ":").replace(/\\\\/g, "\\")
            if ((type === "wifi" || type === "ethernet") && state.startsWith("connected")) {
                networkStatus = `${type === "wifi" ? "Wi-Fi" : "Ethernet"} · ${name || fields[0]}`
                return
            }
        }
        networkStatus = "Déconnecté"
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Process {
        id: weatherProcess
        command: [
            "curl", "--fail", "--silent", "--show-error", "--max-time", "10",
            `https://api.open-meteo.com/v1/forecast?latitude=${root.latitude}&longitude=${root.longitude}&current=temperature_2m,weather_code&timezone=auto`
        ]
        stdout: StdioCollector {
            onStreamFinished: root.updateWeather(text)
        }
        stderr: SplitParser {
            onRead: line => console.warn("Météo:", line)
        }
    }

    Process {
        id: statsProcess
        command: ["cat", "/proc/stat", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: root.updateStats(text)
        }
        stderr: SplitParser {
            onRead: line => console.warn("Statistiques système:", line)
        }
    }

    Process {
        id: networkProcess
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: root.updateNetwork(text)
        }
        stderr: SplitParser {
            onRead: line => {
                root.networkStatus = "Indisponible"
                console.warn("État réseau:", line)
            }
        }
    }

    Timer {
        interval: root.weatherRefreshMinutes * 60000
        repeat: true
        running: true
        onTriggered: root.refreshWeather()
    }

    Timer {
        interval: root.statsRefreshSeconds * 1000
        repeat: true
        running: true
        onTriggered: {
            if (!statsProcess.running)
                statsProcess.running = true
        }
    }

    Timer {
        interval: root.networkRefreshSeconds * 1000
        repeat: true
        running: true
        onTriggered: {
            if (!networkProcess.running)
                networkProcess.running = true
        }
    }

    Connections {
        target: Theme
        function onConfigRevisionChanged() { root.refreshWeather() }
    }

    Component.onCompleted: {
        if (Theme.configRevision > 0)
            refreshWeather()
        statsProcess.running = true
        networkProcess.running = true
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            anchors {
                top: root.position.startsWith("top")
                bottom: root.position.startsWith("bottom")
                left: root.position.endsWith("left")
                right: root.position.endsWith("right")
            }
            margins {
                top: root.position.startsWith("top") ? root.widgetMargin + Theme.barHeight + Theme.spacing : root.widgetMargin
                bottom: root.widgetMargin
                left: root.widgetMargin
                right: root.widgetMargin
            }
            implicitWidth: 280
            implicitHeight: content.implicitHeight + Theme.margin * 2
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "quickshell-desktop-widgets"

            Rectangle {
                anchors.fill: parent
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.componentBackground.r, Theme.componentBackground.g, Theme.componentBackground.b, 0.68)
                border.color: Qt.rgba(Theme.componentBorder.r, Theme.componentBorder.g, Theme.componentBorder.b, 0.28)
                border.width: 1

                Column {
                    id: content
                    anchors.fill: parent
                    anchors.margins: Theme.margin
                    spacing: Theme.spacing

                    Text {
                        width: parent.width
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 42
                        font.weight: Font.Light
                    }

                    Text {
                        width: parent.width
                        text: clock.date.toLocaleString(Qt.locale("fr_FR"), "dddd d MMMM yyyy")
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.72)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacing

                        Text {
                            text: root.weatherIcon
                            color: Theme.accent
                            font.family: Theme.iconFont
                            font.pixelSize: 32
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 32 - refreshButton.width - Theme.spacing * 2
                            spacing: 2

                            Text {
                                width: parent.width
                                text: root.weatherAvailable ? `${root.weatherTemperature} · ${root.location}` : root.location
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize + 2
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: root.weatherDescription
                                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.68)
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 1
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            id: refreshButton
                            anchors.verticalCenter: parent.verticalCenter
                            width: 28
                            height: 28
                            radius: Theme.cornerRadius
                            color: refreshMouse.containsMouse
                                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                                : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "refresh"
                                color: Theme.accent
                                opacity: weatherProcess.running ? 0.45 : 1
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.iconSize + 2
                            }

                            MouseArea {
                                id: refreshMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !weatherProcess.running
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: root.refreshWeather()
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacing * 2

                        Text {
                            text: `CPU  ${root.hasCpuSample ? Math.round(root.cpuUsage) : "--"}%`
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        Text {
                            text: `RAM  ${root.memoryTotal > 0 ? Math.round(root.memoryUsed / root.memoryTotal * 100) : "--"}%`
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }
                    }

                    Text {
                        width: parent.width
                        text: root.networkStatus
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.72)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
