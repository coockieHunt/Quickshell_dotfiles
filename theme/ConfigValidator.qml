import QtQuick

QtObject {
    id: validator

    function isNonEmptyString(value) {
        return typeof value === "string" && value.trim() !== ""
    }

    function isHexColor(value) {
        return typeof value === "string"
            && /^#?[0-9a-fA-F]{6}$/.test(value)
    }

    function intInRange(value, min, max) {
        return Number.isInteger(value) && value >= min && value <= max
    }

    function pathOk(value) {
        return isNonEmptyString(value)
            && (value.startsWith("/") || value.startsWith("~/"))
    }

    function validateUi(ui) {
        return ui
            && intInRange(ui.cornerRadius, 0, 8)
            && typeof ui.accentBorders === "boolean"
    }

    function validateLauncher(launcher) {
        return !launcher
            || (isNonEmptyString(launcher.searchUrl)
                && /^https?:\/\/\S*\{query\}\S*$/i.test(launcher.searchUrl))
    }

    function validateWeather(weather) {
        return !weather
            || (typeof weather.enabled === "boolean"
                && Number.isFinite(weather.latitude)
                && weather.latitude >= -90
                && weather.latitude <= 90
                && Number.isFinite(weather.longitude)
                && weather.longitude >= -180
                && weather.longitude <= 180
                && intInRange(weather.refreshMinutes, 1, 1440))
    }

    function validateWatchers(watchers) {
        return !watchers
            || (isNonEmptyString(watchers.soundDir)
                && isNonEmptyString(watchers.soundExt)
                && watchers.sounds
                && typeof watchers.sounds === "object"
                && Object.keys(watchers.sounds).every(
                    key => typeof watchers.sounds[key] === "string"
                ))
    }

    function validatePanel(panel) {
        return !panel
            || (panel.wifi
                && panel.bluetooth
                && (panel.wifi.rightClick === undefined
                    || ["toggle", "none"].includes(panel.wifi.rightClick))
                && (panel.bluetooth.rightClick === undefined
                    || ["toggle", "none"].includes(panel.bluetooth.rightClick)))
    }

    function validateApps(apps) {
        return !apps
            || ["wifi", "bluetooth", "fileManager"].every(
                key => isNonEmptyString(apps[key])
            )
    }

    function validateWallpaper(wallpaper) {
        return !wallpaper || pathOk(wallpaper.directory)
    }

    function validateKeybindings(keybindings) {
        return !keybindings || pathOk(keybindings.file)
    }

    function validateChargeModes(modes) {
        if (!modes)
            return false

        return ["deplacement", "safe"].every(mode => {
            const limits = modes[mode]
            return limits
                && intInRange(limits.start, 0, 100)
                && intInRange(limits.stop, 0, 100)
                && limits.start < limits.stop
        })
    }

    function validatePowerProfile(pp, defaultModes) {
        const modes = pp?.tlpChargeModes || defaultModes

        return pp
            && typeof pp.batteryFallbackEnabled === "boolean"
            && intInRange(pp.batteryFallbackThresholdPercent, 1, 100)
            && ["eco", "balanced"].includes(pp.batteryFallbackProfile)
            && typeof pp.reduceBrightnessInEco === "boolean"
            && validateChargeModes(modes)
    }

    function validatePerformance(performance) {
        return performance
            && intInRange(performance.statsRefreshSeconds, 1, 60)
            && intInRange(performance.processRefreshSeconds, 5, 300)
            && intInRange(performance.temperatureRefreshSeconds, 5, 300)
    }

    function validateEco(eco) {
        const keys = [
            "ecoVolume", "ecoBrightness",
            "normalVolume", "normalBrightness"
        ]

        return eco
            && keys.every(key =>
                Number.isFinite(eco[key])
                && eco[key] >= 0
                && eco[key] <= 100
            )
    }

    function validateFonts(fonts) {
        const keys = ["text", "mono", "icons", "brand", "logo"]

        return !fonts
            || (keys.every(key =>
                    fonts[key] === undefined || isNonEmptyString(fonts[key])
                )
                && (fonts.textSize === undefined
                    || intInRange(fonts.textSize, 8, 32))
                && (fonts.iconSize === undefined
                    || intInRange(fonts.iconSize, 8, 48)))
    }

    function validateLabels(labels) {
        const keys = [
            "background", "surface",
            "primary", "secondary", "tertiary"
        ]

        return labels
            && keys.every(key => isNonEmptyString(labels[key]))
    }

    function validate(config, defaults) {
        return validateUi(config.ui)
            && validateLauncher(config.launcher)
            && validateWeather(config.weather)
            && validateWatchers(config.watchers)
            && validatePanel(config.panel || config.bar)
            && validateApps(config.apps)
            && validateWallpaper(config.wallpaper)
            && validateKeybindings(config.keybindings)
            && validatePowerProfile(config.powerProfile, defaults.tlpChargeModes)
            && validatePerformance(config.performance)
            && validateEco(config.eco)
            && validateFonts(config.fonts)
            && validateLabels(config.wallpaperPaletteLabels)
    }
}
