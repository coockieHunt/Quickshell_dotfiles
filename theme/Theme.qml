// Used by: 21 file(s)
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property color bg: Qt.rgba(0.157, 0.157, 0.157, 0.88)
    readonly property real backgroundOpacity: 0.88
    property color surface: "#3c3836"
    property color text: "#ebdbb2"
    property color accent: "#fabd2f"
    property color textOnAccent: "#282828"
    property color buttonHover: "#504945"
    property color danger: "#fb4934"
    property real cornerRadius: 2
    property bool accentBorders: true
    readonly property color componentBackground: root.bg
    readonly property color componentSurface: root.surface
    readonly property color componentBorder: root.accentBorders
        ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.35)
        : root.buttonHover
    property string desktopWidgetPosition: "top-left"
    property int desktopWidgetMargin: 5
    property string weatherLocation: "Paris"
    property real weatherLatitude: 48.8566
    property real weatherLongitude: 2.3522
    property int weatherRefreshMinutes: 30
    property int statsRefreshSeconds: 2
    property int networkRefreshSeconds: 20
    property int performanceStatsRefreshSeconds: 1
    property int performanceProcessRefreshSeconds: 5
    property int performanceTemperatureRefreshSeconds: 10
    property bool batteryPerformanceFallbackEnabled: true
    property int batteryPerformanceFallbackThresholdPercent: 20
    property string batteryFallbackProfile: "balanced"
    property var tlpChargeModes: ({
        deplacement: { start: 0, stop: 95 },
        safe: { start: 75, stop: 80 }
    })
    property bool reduceBrightnessInEco: true
    property string controlPanelDefaultMode: "notifications"
    property var ecoSettings: ({
        ecoVolume: 30,
        ecoBrightness: 30,
        normalVolume: 60,
        normalBrightness: 100
    })
    property var wallpaperPaletteLabels: ({
        background: "Fond",
        surface: "Surface",
        primary: "Primaire",
        secondary: "Secondaire",
        tertiary: "Tertiaire"
    })
    property int configRevision: 0

    Behavior on bg { ColorAnimation { duration: 240 } }
    Behavior on surface { ColorAnimation { duration: 240 } }
    Behavior on text { ColorAnimation { duration: 240 } }
    Behavior on accent { ColorAnimation { duration: 240 } }
    Behavior on textOnAccent { ColorAnimation { duration: 240 } }
    Behavior on buttonHover { ColorAnimation { duration: 240 } }

    property string wallpaper: ""
    readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/wallpapers"
    readonly property string wallpaperScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/wallpaper.sh"

    readonly property int barHeight: 30
    readonly property int margin: 12
    readonly property int spacing: 8
    readonly property int workspaceSize: 20
    readonly property int buttonSize: 20

    readonly property string fontFamily: "sans-serif"
    readonly property int fontSize: 13
    readonly property string iconFont: "Material Symbols Rounded"
    readonly property int iconSize: 16

    function parseJsonc(source) {
        let uncommented = ""
        let inString = false
        let escaped = false

        for (let i = 0; i < source.length; i++) {
            const char = source[i]
            const next = source[i + 1]

            if (inString) {
                uncommented += char
                if (escaped)
                    escaped = false
                else if (char === "\\")
                    escaped = true
                else if (char === "\"")
                    inString = false
                continue
            }

            if (char === "\"") {
                inString = true
                uncommented += char
            } else if (char === "/" && next === "/") {
                while (i < source.length && source[i] !== "\n")
                    i++
                if (i < source.length)
                    uncommented += "\n"
            } else if (char === "/" && next === "*") {
                i += 2
                while (i < source.length && !(source[i] === "*" && source[i + 1] === "/")) {
                    if (source[i] === "\n")
                        uncommented += "\n"
                    i++
                }
                if (i >= source.length)
                    throw new Error("Unterminated block comment")
                i++
            } else {
                uncommented += char
            }
        }

        let normalized = ""
        inString = false
        escaped = false
        for (let i = 0; i < uncommented.length; i++) {
            const char = uncommented[i]
            if (inString) {
                normalized += char
                if (escaped)
                    escaped = false
                else if (char === "\\")
                    escaped = true
                else if (char === "\"")
                    inString = false
                continue
            }

            if (char === "\"") {
                inString = true
                normalized += char
            } else if (char === ",") {
                let next = i + 1
                while (next < uncommented.length && /\s/.test(uncommented[next]))
                    next++
                if (uncommented[next] !== "}" && uncommented[next] !== "]")
                    normalized += char
            } else {
                normalized += char
            }
        }
        return JSON.parse(normalized)
    }

    FileView {
        id: configFile
        path: Quickshell.env("HOME") + "/.config/quickshell/config.jsonc"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const config = root.parseJsonc(text())
                const c = config.theme
                const keys = ["bg", "surface", "text", "accent", "textOnAccent", "buttonHover"]
                if (!c || !keys.every(k => typeof c[k] === "string" && /^#?[0-9a-fA-F]{6}$/.test(c[k]))) {
                    console.warn("config.jsonc: theme colors must use six-digit hex values")
                    return
                }
                const ui = config.ui
                const widgets = config.desktopWidgets
                const controlPanel = config.controlPanel
                const performance = config.performance
                const powerProfile = config.powerProfile
                const tlpChargeModes = powerProfile?.tlpChargeModes || root.tlpChargeModes
                const weather = widgets?.weather
                const eco = config.eco
                const labels = config.wallpaperPaletteLabels
                const labelKeys = ["background", "surface", "primary", "secondary", "tertiary"]
                const ecoKeys = ["ecoVolume", "ecoBrightness", "normalVolume", "normalBrightness"]
                const validPositions = ["top-left", "top-right", "bottom-left", "bottom-right"]

                if (!ui || !Number.isFinite(ui.cornerRadius) || ui.cornerRadius < 0 || ui.cornerRadius > 8
                        || typeof ui.accentBorders !== "boolean"
                        || !widgets || !validPositions.includes(widgets.position)
                        || !controlPanel || !["notifications", "both"].includes(controlPanel.defaultMode)
                        || !performance
                        || !powerProfile
                        || typeof powerProfile.batteryFallbackEnabled !== "boolean"
                        || !Number.isInteger(powerProfile.batteryFallbackThresholdPercent)
                        || powerProfile.batteryFallbackThresholdPercent < 1
                        || powerProfile.batteryFallbackThresholdPercent > 100
                        || !["eco", "balanced"].includes(powerProfile.batteryFallbackProfile)
                        || typeof powerProfile.reduceBrightnessInEco !== "boolean"
                        || !tlpChargeModes
                        || !["deplacement", "safe"].every(mode => {
                            const limits = tlpChargeModes[mode]
                            return limits
                                && Number.isInteger(limits.start) && limits.start >= 0 && limits.start < 100
                                && Number.isInteger(limits.stop) && limits.stop > limits.start && limits.stop <= 100
                        })
                        || !Number.isInteger(performance.statsRefreshSeconds) || performance.statsRefreshSeconds < 1 || performance.statsRefreshSeconds > 60
                        || !Number.isInteger(performance.processRefreshSeconds) || performance.processRefreshSeconds < 5 || performance.processRefreshSeconds > 300
                        || !Number.isInteger(performance.temperatureRefreshSeconds) || performance.temperatureRefreshSeconds < 5 || performance.temperatureRefreshSeconds > 300
                        || !Number.isInteger(widgets.margin) || widgets.margin < 0
                        || typeof weather?.location !== "string" || weather.location.trim() === ""
                        || !Number.isFinite(weather.latitude) || weather.latitude < -90 || weather.latitude > 90
                        || !Number.isFinite(weather.longitude) || weather.longitude < -180 || weather.longitude > 180
                        || !Number.isInteger(weather.refreshMinutes) || weather.refreshMinutes < 5
                        || !Number.isInteger(widgets.statsRefreshSeconds) || widgets.statsRefreshSeconds < 1
                        || !Number.isInteger(widgets.networkRefreshSeconds) || widgets.networkRefreshSeconds < 5
                        || !eco || !ecoKeys.every(k => Number.isFinite(eco[k]) && eco[k] >= 0 && eco[k] <= 100)
                        || !labels || !labelKeys.every(k => typeof labels[k] === "string" && labels[k].trim() !== "")) {
                    console.warn("config.jsonc: invalid or missing configuration values")
                    return
                }

                root.applyThemeColors(c)
                root.cornerRadius = ui.cornerRadius
                root.accentBorders = ui.accentBorders
                root.desktopWidgetPosition = widgets.position
                root.desktopWidgetMargin = widgets.margin
                root.weatherLocation = weather.location.trim()
                root.weatherLatitude = weather.latitude
                root.weatherLongitude = weather.longitude
                root.weatherRefreshMinutes = weather.refreshMinutes
                root.statsRefreshSeconds = widgets.statsRefreshSeconds
                root.networkRefreshSeconds = widgets.networkRefreshSeconds
                root.performanceStatsRefreshSeconds = performance.statsRefreshSeconds
                root.performanceProcessRefreshSeconds = performance.processRefreshSeconds
                root.performanceTemperatureRefreshSeconds = performance.temperatureRefreshSeconds
                root.batteryPerformanceFallbackEnabled = powerProfile.batteryFallbackEnabled
                root.batteryPerformanceFallbackThresholdPercent = powerProfile.batteryFallbackThresholdPercent
                root.batteryFallbackProfile = powerProfile.batteryFallbackProfile
                root.tlpChargeModes = tlpChargeModes
                root.reduceBrightnessInEco = powerProfile.reduceBrightnessInEco
                root.controlPanelDefaultMode = controlPanel.defaultMode
                root.ecoSettings = eco
                root.wallpaperPaletteLabels = labels
                root.configRevision++
            } catch (e) {
                console.warn("Failed to load config.jsonc:", e)
            }
        }
    }

    FileView {
        path: Quickshell.env("HOME") + "/.cache/quickshell-theme-colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.applyThemeColors(JSON.parse(text()))
            } catch (error) {
                console.warn("Failed to load generated wallpaper colors:", error)
            }
        }
    }

    function applyThemeColors(c) {
        const keys = ["bg", "surface", "text", "accent", "textOnAccent", "buttonHover"]
        if (!c || !keys.every(k => typeof c[k] === "string" && /^#?[0-9a-fA-F]{6}$/.test(c[k]))) {
            console.warn("Theme colors must use six-digit hex values")
            return
        }

        const activeBorder = c.accent.match(/^#?([0-9a-fA-F]{6})$/)
        const inactiveBorder = c.buttonHover.match(/^#?([0-9a-fA-F]{6})$/)
        const bgColor = Qt.color(c.bg)
        root.bg = Qt.rgba(bgColor.r, bgColor.g, bgColor.b, root.backgroundOpacity)
        root.surface = c.surface
        root.text = c.text
        root.accent = c.accent
        root.textOnAccent = c.textOnAccent
        root.buttonHover = c.buttonHover
        Quickshell.execDetached([
            "hyprctl", "eval",
            `hl.config({ general = { col = { active_border = "rgb(${activeBorder[1]})", inactive_border = "rgb(${inactiveBorder[1]})" } } })`
        ])
    }

    FileView {
        path: Quickshell.env("HOME") + "/.cache/qs-wallpaper"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.wallpaper = text().trim()
    }
}
