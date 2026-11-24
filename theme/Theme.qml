pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool themeReady: false
    property bool splashDone: false
    property bool minTimeElapsed: false

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
    property string launcherSearchUrl: "https://duckduckgo.com/?q={query}"

    property var weather: ({
        enabled: true,
        latitude: 48.8566,
        longitude: 2.3522,
        refreshMinutes: 30
    })

    property string wifiApplication: "nm-connection-editor"
    property string barWifiRightClick: "toggle"
    property string bluetoothApplication: "blueman-manager"
    property string barBluetoothRightClick: "toggle"
    property string fileManagerApplication: "dolphin"
    property string textEditorApplication: "kate"

    readonly property string configFilePath: Quickshell.env("HOME") + "/.config/quickshell/config.jsonc"
    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/quickshell/scripts"
    readonly property string powerProfileScript: scriptsDir + "/tlp-power-profile.sh"
    readonly property string wallpaperScript: scriptsDir + "/wallpaper-apply.sh"
    readonly property string openUserAppsScript: scriptsDir + "/open-apps-folder.sh"

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

    property string soundDir: "/usr/share/sounds/freedesktop/stereo"
    property string soundExt: "oga"
    property var sounds: ({
        plug: "power-plug",
        unplug: "power-unplug",
        batteryLow: "battery-low",
        usbAdd: "device-added",
        usbRemove: "device-removed"
    })

    property int configRevision: 0

    property string wallpaper: ""
    property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/wallpapers"
    property string keybindingFile:
        Quickshell.env("HOME") + "/.config/hypr/keybinding.lua"

    readonly property int barHeight: 30
    readonly property int dropdownGap: 6
    readonly property int margin: 12
    readonly property int spacing: 8
    readonly property int workspaceSize: 20
    readonly property int buttonSize: 20

    property string fontFamily: "sans-serif"
    property string monoFont: "monospace"
    property int fontSize: 13
    property string iconFont: "Material Symbols Rounded"
    property string brandFont: "JetBrainsMono Nerd Font"
    property string archLogo: "\uf303"
    property int iconSize: 16

    function soundPath(event) {
        const name = root.sounds[event]
        if (!name)
            return ""

        if (name.startsWith("/"))
            return name

        return root.soundDir.replace(/\/+$/, "") + "/" + name + "." + root.soundExt
    }

    function isValidTheme(theme) {
        const keys = [
            "bg",
            "surface",
            "text",
            "accent",
            "textOnAccent",
            "buttonHover"
        ]

        return theme
            && keys.every(key =>
                typeof theme[key] === "string"
                && /^#?[0-9a-fA-F]{6}$/.test(theme[key])
            )
    }

    function applyThemeColors(theme) {
        if (!isValidTheme(theme)) {
            console.warn(
                "Thème invalide : les couleurs doivent être au format hexadécimal à 6 chiffres"
            )
            return false
        }

        const bgColor = Qt.color(theme.bg)
        root.bg = Qt.rgba(
            bgColor.r,
            bgColor.g,
            bgColor.b,
            root.backgroundOpacity
        )
        root.surface = theme.surface
        root.text = theme.text
        root.accent = theme.accent
        root.textOnAccent = theme.textOnAccent
        root.buttonHover = theme.buttonHover

        const activeBorder = theme.accent.replace("#", "")
        const inactiveBorder = theme.buttonHover.replace("#", "")

        Quickshell.execDetached([
            "hyprctl",
            "eval",
            `hl.config({ general = { col = { active_border = "rgb(${activeBorder})", inactive_border = "rgb(${inactiveBorder})" } } })`
        ])

        return true
    }

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

                while (
                    i < source.length
                    && !(source[i] === "*" && source[i + 1] === "/")
                ) {
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

                while (
                    next < uncommented.length
                    && /\s/.test(uncommented[next])
                ) {
                    next++
                }

                if (
                    uncommented[next] !== "}"
                    && uncommented[next] !== "]"
                ) {
                    normalized += char
                }
            } else {
                normalized += char
            }
        }

        return JSON.parse(normalized)
    }

    FileView {
        id: configFile
        path: root.configFilePath
        watchChanges: true

        onFileChanged: reload()

        onLoaded: {
            try {
                const config = root.parseJsonc(text())
                const c = config.theme

                if (!root.isValidTheme(c)) {
                    console.warn("config.jsonc: thème absent ou invalide")
                    return
                }

                const ui = config.ui
                const controlPanel = config.controlPanel
                const performance = config.performance
                const powerProfile = config.powerProfile
                const wallpaperConfig = config.wallpaper
                const keybindingsConfig = config.keybindings
                const updates = config.updates
                const launcher = config.launcher
                const weatherConfig = config.weather
                const watchers = config.watchers
                const panel = config.panel || config.bar
                const wifiPanel = panel?.wifi
                const bluetoothPanel = panel?.bluetooth
                const apps = config.apps
                const tlpChargeModes =
                    powerProfile?.tlpChargeModes || root.tlpChargeModes
                const eco = config.eco
                const fonts = config.fonts
                const labels = config.wallpaperPaletteLabels

                const labelKeys = [
                    "background",
                    "surface",
                    "primary",
                    "secondary",
                    "tertiary"
                ]
                const ecoKeys = [
                    "ecoVolume",
                    "ecoBrightness",
                    "normalVolume",
                    "normalBrightness"
                ]
                const fontKeys = [
                    "text",
                    "mono",
                    "icons",
                    "brand",
                    "logo"
                ]

                if (
                    !ui
                    || !Number.isFinite(ui.cornerRadius)
                    || ui.cornerRadius < 0
                    || ui.cornerRadius > 8
                    || typeof ui.accentBorders !== "boolean"
                    || !controlPanel
                    || !["notifications", "both"].includes(controlPanel.defaultMode)
                    || (launcher && (
                        typeof launcher.searchUrl !== "string"
                        || !/^https?:\/\/\S*\{query\}\S*$/i.test(launcher.searchUrl)
                    ))
                    || (weatherConfig && (
                        typeof weatherConfig.enabled !== "boolean"
                        || !Number.isFinite(weatherConfig.latitude)
                        || weatherConfig.latitude < -90
                        || weatherConfig.latitude > 90
                        || !Number.isFinite(weatherConfig.longitude)
                        || weatherConfig.longitude < -180
                        || weatherConfig.longitude > 180
                        || !Number.isInteger(weatherConfig.refreshMinutes)
                        || weatherConfig.refreshMinutes < 1
                    ))
                    || (watchers && (
                        typeof watchers.soundDir !== "string"
                        || watchers.soundDir.trim() === ""
                        || typeof watchers.soundExt !== "string"
                        || !watchers.sounds
                        || typeof watchers.sounds !== "object"
                        || !Object.keys(watchers.sounds).every(
                            key => typeof watchers.sounds[key] === "string"
                        )
                    ))
                    || (panel && (
                        !wifiPanel
                        || !bluetoothPanel
                        || (
                            wifiPanel.rightClick !== undefined
                            && !["toggle", "none"].includes(wifiPanel.rightClick)
                        )
                        || (
                            bluetoothPanel.rightClick !== undefined
                            && !["toggle", "none"].includes(bluetoothPanel.rightClick)
                        )
                    ))
                    || (apps && !["wifi", "bluetooth", "fileManager"].every(
                        key =>
                            typeof apps[key] === "string"
                            && apps[key].trim() !== ""
                    ))
                    || (wallpaperConfig && (
                        typeof wallpaperConfig.directory !== "string"
                        || wallpaperConfig.directory.trim() === ""
                        || (
                            !wallpaperConfig.directory.startsWith("/")
                            && !wallpaperConfig.directory.startsWith("~/")
                        )
                    ))
                    || (keybindingsConfig && (
                        typeof keybindingsConfig.file !== "string"
                        || keybindingsConfig.file.trim() === ""
                        || (
                            !keybindingsConfig.file.startsWith("/")
                            && !keybindingsConfig.file.startsWith("~/")
                        )
                    ))
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
                            && Number.isInteger(limits.start)
                            && limits.start >= 0
                            && limits.start < 100
                            && Number.isInteger(limits.stop)
                            && limits.stop > limits.start
                            && limits.stop <= 100
                    })
                    || !Number.isInteger(performance.statsRefreshSeconds)
                    || performance.statsRefreshSeconds < 1
                    || performance.statsRefreshSeconds > 60
                    || !Number.isInteger(performance.processRefreshSeconds)
                    || performance.processRefreshSeconds < 5
                    || performance.processRefreshSeconds > 300
                    || !Number.isInteger(performance.temperatureRefreshSeconds)
                    || performance.temperatureRefreshSeconds < 5
                    || performance.temperatureRefreshSeconds > 300
                    || !eco
                    || !ecoKeys.every(
                        key =>
                            Number.isFinite(eco[key])
                            && eco[key] >= 0
                            && eco[key] <= 100
                    )
                    || (fonts && !fontKeys.every(
                        key =>
                            fonts[key] === undefined
                            || (
                                typeof fonts[key] === "string"
                                && fonts[key].trim() !== ""
                            )
                    ))
                    || (fonts && fonts.textSize !== undefined && (
                        !Number.isInteger(fonts.textSize)
                        || fonts.textSize < 8
                        || fonts.textSize > 32
                    ))
                    || (fonts && fonts.iconSize !== undefined && (
                        !Number.isInteger(fonts.iconSize)
                        || fonts.iconSize < 8
                        || fonts.iconSize > 48
                    ))
                    || !labels
                    || !labelKeys.every(
                        key =>
                            typeof labels[key] === "string"
                            && labels[key].trim() !== ""
                    )
                ) {
                    console.warn(
                        "config.jsonc: invalid or missing configuration values"
                    )
                    return
                }

                if (!root.themeReady)
                    root.applyThemeColors(c)

                root.cornerRadius = ui.cornerRadius
                root.accentBorders = ui.accentBorders

                root.performanceStatsRefreshSeconds =
                    performance.statsRefreshSeconds
                root.performanceProcessRefreshSeconds =
                    performance.processRefreshSeconds
                root.performanceTemperatureRefreshSeconds =
                    performance.temperatureRefreshSeconds

                root.batteryPerformanceFallbackEnabled =
                    powerProfile.batteryFallbackEnabled
                root.batteryPerformanceFallbackThresholdPercent =
                    powerProfile.batteryFallbackThresholdPercent
                root.batteryFallbackProfile =
                    powerProfile.batteryFallbackProfile
                root.tlpChargeModes = tlpChargeModes
                root.reduceBrightnessInEco =
                    powerProfile.reduceBrightnessInEco

                root.controlPanelDefaultMode = controlPanel.defaultMode

                if (launcher)
                    root.launcherSearchUrl = launcher.searchUrl

                root.weather = weatherConfig || {
                    enabled: true,
                    latitude: 48.8566,
                    longitude: 2.3522,
                    refreshMinutes: 30
                }

                if (watchers) {
                    root.soundDir = watchers.soundDir.startsWith("~/")
                        ? Quickshell.env("HOME") + watchers.soundDir.slice(1)
                        : watchers.soundDir
                    root.soundExt = watchers.soundExt.replace(/^\./, "")
                    root.sounds = watchers.sounds
                }

                root.wifiApplication =
                    apps?.wifi || wifiPanel?.application || "nm-connection-editor"
                root.barWifiRightClick = wifiPanel?.rightClick || "toggle"

                root.bluetoothApplication =
                    apps?.bluetooth || bluetoothPanel?.application || "blueman-manager"
                root.barBluetoothRightClick =
                    bluetoothPanel?.rightClick || "toggle"

                root.fileManagerApplication =
                    apps?.fileManager || "dolphin"
                root.textEditorApplication =
                    apps?.textEditor || "kate"

                const wallpaperDirectory =
                    wallpaperConfig?.directory || "~/Pictures/wallpapers"
                root.wallpaperDir = wallpaperDirectory.startsWith("~/")
                    ? Quickshell.env("HOME") + wallpaperDirectory.slice(1)
                    : wallpaperDirectory

                const keybindingPath =
                    keybindingsConfig?.file || "~/.config/hypr/keybinding.lua"
                root.keybindingFile = keybindingPath.startsWith("~/")
                    ? Quickshell.env("HOME") + keybindingPath.slice(1)
                    : keybindingPath

                root.ecoSettings = eco
                root.wallpaperPaletteLabels = labels

                root.fontFamily = fonts?.text || "sans-serif"
                root.monoFont = fonts?.mono || "monospace"
                root.iconFont = fonts?.icons || "Material Symbols Rounded"
                root.brandFont = fonts?.brand || "JetBrainsMono Nerd Font"
                root.archLogo = fonts?.logo || "\uf303"
                root.fontSize = fonts?.textSize || 13
                root.iconSize = fonts?.iconSize || 16

                root.configRevision++
            } catch (error) {
                console.warn("Failed to load config.jsonc:", error)
            }
        }
    }

    Timer {
        id: settleTimer
        interval: 200

        onTriggered: {
            if (root.minTimeElapsed)
                root.splashDone = true
        }
    }

    Timer {
        running: true
        interval: 1200

        onTriggered: {
            root.minTimeElapsed = true

            if (root.themeReady && !settleTimer.running)
                root.splashDone = true
        }
    }

    Timer {
        running: true
        interval: 8000

        onTriggered: {
            root.themeReady = true
            root.splashDone = true
        }
    }

    FileView {
        id: colorsFile
        path: Quickshell.env("HOME") + "/.cache/quickshell-theme-colors.json"
        watchChanges: true

        onFileChanged: reload()

        onLoaded: {
            try {
                const loaded = root.applyThemeColors(JSON.parse(text()))

                if (loaded && !root.themeReady) {
                    root.themeReady = true
                    settleTimer.start()
                }
            } catch (error) {
                console.warn(
                    "Failed to load generated wallpaper colors:",
                    error
                )
            }
        }
    }

    Timer {
        running: !root.themeReady
        repeat: true
        interval: 250

        onTriggered: colorsFile.reload()
    }

    FileView {
        path: Quickshell.env("HOME") + "/.cache/qs-wallpaper"
        watchChanges: true

        onFileChanged: reload()
        onLoaded: root.wallpaper = text().trim()
    }
}
