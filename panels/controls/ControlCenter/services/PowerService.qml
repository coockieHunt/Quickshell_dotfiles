import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../../../../theme"

Item {
    id: root

    required property var brightnessService

    property string powerProfile: ""
    property bool ecoModeActive: false
    property string tlpChargeMode: ""
    property string pendingTlpChargeMode: ""
    property bool tlpChargeCommandRunning: false
    property var ecoSettings: Theme.ecoSettings

    property bool batteryPerformanceFallbackRunning: false
    property bool batteryPerformanceFallbackTriggered: false
    property bool batteryEcoBrightnessPending: false
    property bool batteryEcoBrightnessHandled: false
    property bool batteryEcoBrightnessApplied: false
    property real batteryEcoBrightnessRestoreValue: 0

    function toggleEcoMode() {
        ecoModeActive = !ecoModeActive
        powerProfileScript.command = [
            "bash", Theme.powerProfileScript, ecoModeActive ? "on" : "off"
        ]
        powerProfileScript.running = true
        applyEcoSettings()
    }

    function applyEcoSettings() {
        checkEcoBrightness()
    }

    function handlePowerProfileSelected(profile) {
        const wasEco = powerProfile === "power-saver" || ecoModeActive
        powerProfile = profile
        if (profile === "power-saver") {
            checkEcoBrightness()
            return
        }
        ecoModeActive = false
        if (wasEco) {
            batteryEcoBrightnessApplied = false
            batteryEcoBrightnessHandled = false
            brightnessService.applyBrightness(1)
        }
    }

    function returnToBalancedProfile() {
        if (!powerProfileCommand.running) {
            powerProfileCommand.command = ["bash", Theme.powerProfileScript, "balanced"]
            powerProfileCommand.running = true
        }
    }

    function setTlpChargeMode(mode) {
        const limits = Theme.tlpChargeModes[mode]
        if (!limits || tlpChargeCommandRunning)
            return
        pendingTlpChargeMode = mode
        tlpChargeCommand.command = [
            "bash", Theme.powerProfileScript, "charge",
            String(limits.start), String(limits.stop)
        ]
        tlpChargeCommandRunning = true
        tlpChargeLaunchTimer.start()
    }

    function refreshTlpChargeMode() {
        if (!tlpChargeStatus.running)
            tlpChargeStatus.running = true
    }

    function shouldReduceEcoBrightness() {
        return Theme.reduceBrightnessInEco
            && (ecoModeActive || powerProfile === "power-saver")
    }

    function checkEcoBrightness() {
        if (!shouldReduceEcoBrightness()) {
            batteryEcoBrightnessHandled = false
            restoreBatteryEcoBrightness()
            return
        }
        if (batteryEcoBrightnessApplied || batteryEcoBrightnessHandled || batteryEcoBrightnessPending)
            return
        batteryEcoBrightnessPending = true
        batteryEcoBrightnessStatus.running = true
    }

    function restoreBatteryEcoBrightness() {
        if (!batteryEcoBrightnessApplied)
            return
        batteryEcoBrightnessApplied = false
        brightnessService.setBrightness(batteryEcoBrightnessRestoreValue)
    }

    function batteryPerformanceFallbackNeeded() {
        const battery = UPower.displayDevice
        return Theme.batteryPerformanceFallbackEnabled
            && UPower.onBattery
            && battery
            && Number.isFinite(battery.percentage)
            && battery.percentage * 100 <= Theme.batteryPerformanceFallbackThresholdPercent
    }

    function checkBatteryPerformanceFallback() {
        checkEcoBrightness()
        if (!batteryPerformanceFallbackNeeded()) {
            batteryPerformanceFallbackTriggered = false
            return
        }
        if (batteryPerformanceFallbackTriggered || batteryPerformanceFallbackRunning)
            return
        batteryPerformanceFallbackRunning = true
        batteryPerformanceFallbackTriggered = true
        batteryProfileStatus.running = true
    }

    function refresh() {
        if (!activePowerProfileStatus.running)
            activePowerProfileStatus.running = true
        refreshTlpChargeMode()
    }

    onEcoModeActiveChanged: checkEcoBrightness()
    onPowerProfileChanged: checkEcoBrightness()

    Connections {
        target: UPower
        function onOnBatteryChanged() {
            root.checkBatteryPerformanceFallback()
            if (!UPower.onBattery && root.ecoModeActive)
                root.toggleEcoMode()
        }
    }

    Connections {
        target: UPower.displayDevice
        function onPercentageChanged() { root.checkBatteryPerformanceFallback() }
    }

    Connections {
        target: Theme
        function onEcoSettingsChanged() {
            if (root.ecoModeActive) root.applyEcoSettings()
            else root.checkEcoBrightness()
        }
        function onConfigRevisionChanged() {
            root.batteryPerformanceFallbackTriggered = false
            root.batteryEcoBrightnessHandled = false
            root.checkEcoBrightness()
            root.checkBatteryPerformanceFallback()
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.checkBatteryPerformanceFallback()
    }

    Timer {
        id: tlpChargeLaunchTimer
        interval: 200
        repeat: false
        onTriggered: tlpChargeCommand.running = true
    }

    Component.onCompleted: {
        checkBatteryPerformanceFallback()
        refresh()
    }

    Process {
        id: activePowerProfileStatus
        command: ["bash", Theme.powerProfileScript]
        stdout: StdioCollector { id: activePowerProfileOutput }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("Power profile status failed:", exitCode, exitStatus)
                return
            }
            const match = activePowerProfileOutput.text.match(/TLP profile\s*=\s*([^/\s]+)/i)
            if (match)
                root.handlePowerProfileSelected(match[1].toLowerCase())
            else
                console.warn("Power profile status returned no TLP profile")
        }
        stderr: SplitParser { onRead: line => console.warn("Power profile status:", line) }
    }

    Process {
        id: powerProfileCommand
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root.handlePowerProfileSelected("balanced")
            else
                console.warn("Returning to balanced power profile failed:", exitCode, exitStatus)
        }
        stderr: SplitParser { onRead: line => console.warn("Balanced power profile:", line) }
    }

    Process {
        id: tlpChargeCommand
        onExited: (exitCode, exitStatus) => {
            root.tlpChargeCommandRunning = false
            if (exitCode === 0)
                root.tlpChargeMode = root.pendingTlpChargeMode
            else
                console.warn("TLP charge threshold update failed:", exitCode, exitStatus)
            root.refreshTlpChargeMode()
            root.pendingTlpChargeMode = ""
        }
        stderr: SplitParser { onRead: line => console.warn("TLP charge thresholds:", line) }
    }

    Process {
        id: tlpChargeStatus
        command: ["bash", Theme.powerProfileScript, "charge-status"]
        stdout: StdioCollector { id: tlpChargeStatusOutput }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("Reading TLP charge thresholds failed:", exitCode, exitStatus)
                return
            }
            const match = tlpChargeStatusOutput.text.trim().match(/^(\d+)\s+(\d+)$/)
            if (!match) {
                console.warn("TLP charge threshold status returned invalid output:", tlpChargeStatusOutput.text)
                return
            }
            const start = Number(match[1])
            const stop = Number(match[2])
            const modes = Object.keys(Theme.tlpChargeModes)
            const exactMode = modes.find(mode => {
                const limits = Theme.tlpChargeModes[mode]
                return limits.start === start && limits.stop === stop
            })
            if (exactMode) {
                root.tlpChargeMode = exactMode
                return
            }
            const stopMatches = modes.filter(mode => Theme.tlpChargeModes[mode].stop === stop)
            if (stopMatches.length === 1)
                root.tlpChargeMode = stopMatches[0]
        }
        stderr: SplitParser { onRead: line => console.warn("TLP charge threshold status:", line) }
    }

    Process {
        id: batteryProfileStatus
        command: ["bash", Theme.powerProfileScript]
        stdout: StdioCollector { id: batteryProfileOutput }
        stderr: SplitParser { onRead: line => console.warn("Battery power profile read:", line) }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("Battery power profile read failed:", exitCode, exitStatus)
                root.batteryPerformanceFallbackRunning = false
                root.batteryPerformanceFallbackTriggered = false
            } else if (!root.batteryPerformanceFallbackNeeded()) {
                root.batteryPerformanceFallbackRunning = false
            } else if (batteryProfileOutput.text.toLowerCase().includes("performance")) {
                batteryProfileFallback.command = [
                    "bash", Theme.powerProfileScript, Theme.batteryFallbackProfile
                ]
                batteryProfileFallback.running = true
            } else {
                root.batteryPerformanceFallbackRunning = false
            }
        }
    }

    Process {
        id: batteryProfileFallback
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.handlePowerProfileSelected(Theme.batteryFallbackProfile === "eco"
                    ? "power-saver" : Theme.batteryFallbackProfile)
                const percentage = Math.round(UPower.displayDevice.percentage * 100)
                const profileLabel = Theme.batteryFallbackProfile === "eco" ? "Éco" : "Équilibré"
                Quickshell.execDetached([
                    "notify-send",
                    "Profil de batterie modifié",
                    `Batterie à ${percentage} % : profil ${profileLabel} activé.`
                ])
            } else {
                console.warn("Battery power profile fallback failed:", exitCode, exitStatus)
                root.batteryPerformanceFallbackTriggered = false
            }
            root.batteryPerformanceFallbackRunning = false
        }
        stderr: SplitParser { onRead: line => console.warn("Battery power profile fallback:", line) }
    }

    Process {
        id: batteryEcoBrightnessStatus
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector { id: batteryEcoBrightnessOutput }
        onExited: (exitCode, exitStatus) => {
            root.batteryEcoBrightnessPending = false
            if (exitCode !== 0) {
                console.warn("Battery eco brightness read failed:", exitCode, exitStatus)
                return
            }
            if (!root.shouldReduceEcoBrightness())
                return
            const output = batteryEcoBrightnessOutput.text.trim()
            const parts = output.split(",")
            const percentage = parts.length >= 4 ? parseInt(parts[3]) : NaN
            if (!Number.isFinite(percentage)) {
                console.warn("Battery eco brightness read returned invalid output:", output)
                return
            }
            const currentBrightness = Math.max(0, Math.min(1, percentage / 100))
            const ecoBrightness = root.ecoSettings.ecoBrightness / 100
            root.batteryEcoBrightnessHandled = true
            if (currentBrightness <= ecoBrightness)
                return
            root.batteryEcoBrightnessRestoreValue = currentBrightness
            root.batteryEcoBrightnessApplied = true
            root.brightnessService.applyBrightness(ecoBrightness)
        }
        stderr: SplitParser { onRead: line => console.warn("Battery eco brightness:", line) }
    }

    Process {
        id: powerProfileScript
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root.handlePowerProfileSelected(root.ecoModeActive ? "power-saver" : "balanced")
            else
                console.warn("Eco mode command failed:", exitCode, exitStatus)
        }
        stderr: SplitParser { onRead: line => console.warn("Eco mode:", line) }
    }
}
