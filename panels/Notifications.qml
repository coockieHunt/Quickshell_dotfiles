// Used by: 1 file(s)
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import "../components"
import "../theme"

Scope {
    id: root
    property bool panelOpen: false
    property string panelMode: "notifications"
    property string powerProfile: ""
    property string tlpChargeMode: ""
    property string pendingTlpChargeMode: ""
    property bool tlpChargeCommandRunning: false
    property var performanceControl: null
    property var history: []
    property bool wifiEnabled: false
    property bool bluetoothEnabled: false
    property string wifiNetworkName: ""
    property string bluetoothConnectedNames: ""
    property bool soundMuted: false
    property bool wifiStateKnown: false
    property bool bluetoothStateKnown: false
    property bool soundStateKnown: false
    property real brightness: 0
    property bool brightnessStateKnown: false
    property bool ecoModeActive: false
    property var ecoSettings: Theme.ecoSettings
    property bool batteryPerformanceFallbackRunning: false
    property bool batteryPerformanceFallbackTriggered: false
    property bool batteryEcoBrightnessPending: false
    property bool batteryEcoBrightnessHandled: false
    property bool batteryEcoBrightnessApplied: false
    property real batteryEcoBrightnessRestoreValue: 0
    property double notificationMuteUntil: 0
    property int muteClockTick: 0
    property string muteMessage: ""
    readonly property bool notificationsMuted: notificationMuteUntil === -1
        || notificationMuteUntil > Date.now()
    readonly property string muteTimeRemaining: {
        muteClockTick
        if (notificationMuteUntil === -1)
            return "∞"
        const seconds = Math.max(0, Math.ceil((notificationMuteUntil - Date.now()) / 1000))
        if (seconds >= 3600)
            return Math.floor(seconds / 3600) + " h " + Math.floor((seconds % 3600) / 60) + " min"
        return Math.max(1, Math.ceil(seconds / 60)) + " min"
    }
    readonly property bool airplaneEnabled: wifiStateKnown && bluetoothStateKnown
        && !wifiEnabled && !bluetoothEnabled
    readonly property var audio: Pipewire.defaultAudioSink
        ? Pipewire.defaultAudioSink.audio : null

    function togglePanel() {
        panelOpen = !panelOpen
        console.info("Control panel", panelOpen ? "opened" : "closed")
        if (panelOpen) {
            panelMode = Theme.controlPanelDefaultMode
            refreshQuickSettings()
        }
    }

    function showPanelMode(mode) {
        panelMode = mode
    }

    function removeHistoryNotification(index) {
        const updatedHistory = history.slice()
        const entry = updatedHistory[index]
        if (!entry)
            return
        if (entry.notification?.tracked)
            entry.notification.dismiss()
        updatedHistory.splice(index, 1)
        history = updatedHistory
    }

    IpcHandler {
        target: "control-panel"
        function toggle(): void { root.togglePanel() }
        function show(): void {
            root.panelOpen = true
            root.panelMode = Theme.controlPanelDefaultMode
            root.refreshQuickSettings()
        }
        function hide(): void { root.panelOpen = false }
    }

    function refreshQuickSettings() {
        refreshNetworkStatus()
        soundStatus.running = true
        brightnessStatus.running = true
    }

    function refreshNetworkStatus() {
        if (!wifiStatus.running)
            wifiStatus.running = true
        if (!wifiConnectionStatus.running)
            wifiConnectionStatus.running = true
        if (!bluetoothStatus.running)
            bluetoothStatus.running = true
        if (!bluetoothConnectionStatus.running)
            bluetoothConnectionStatus.running = true
    }

    function toggleWifi() {
        wifiEnabled = !wifiEnabled
        wifiCommand.running = true
    }

    function toggleBluetooth() {
        bluetoothEnabled = !bluetoothEnabled
        bluetoothCommand.running = true
    }

    function toggleSound() {
        soundMuted = !soundMuted
        soundCommand.running = true
    }

    function toggleAirplane() {
        const enable = !airplaneEnabled
        wifiEnabled = !enable
        bluetoothEnabled = !enable
        wifiCommand.running = true
        bluetoothCommand.running = true
    }

    function applyEcoSettings() {
        checkEcoBrightness()
    }

    function toggleEcoMode() {
        ecoModeActive = !ecoModeActive
        powerProfileScript.command = [
            "/home/jonathan/.config/quickshell/scripts/power-profile.sh",
            ecoModeActive ? "on" : "off"
        ]
        powerProfileScript.running = true
        applyEcoSettings()
    }

    function setNotificationMute(durationMs) {
        muteMenu.close()
        muteTimer.stop()
        notificationMuteUntil = durationMs < 0
            ? -1 : durationMs === 0 ? 0 : Date.now() + durationMs
        if (durationMs > 0) {
            muteTimer.interval = durationMs
            muteTimer.start()
        }
        if (notificationsMuted) {
            for (const notification of server.trackedNotifications.values)
                notification.dismiss()
        }
    }

    function setBrightness(value) {
        brightness = value
        if (batteryEcoBrightnessApplied)
            batteryEcoBrightnessRestoreValue = value
        brightnessDebounce.restart()
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
            brightness = 1
            brightnessDebounce.restart()
        }
    }

    function returnToBalancedProfile() {
        if (!powerProfileCommand.running) {
            powerProfileCommand.command = [
                "bash",
                "/home/jonathan/.config/quickshell/scripts/power-profile.sh",
                "balanced"
            ]
            powerProfileCommand.running = true
        }
    }

    function setTlpChargeMode(mode) {
        const limits = Theme.tlpChargeModes[mode]
        if (!limits || tlpChargeCommandRunning)
            return

        pendingTlpChargeMode = mode
        tlpChargeCommand.command = [
            "bash",
            "/home/jonathan/.config/quickshell/scripts/power-profile.sh",
            "charge",
            String(limits.start),
            String(limits.stop)
        ]
        tlpChargeCommandRunning = true
        panelOpen = false
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

    function batteryPerformanceFallbackNeeded() {
        const battery = UPower.displayDevice
        return Theme.batteryPerformanceFallbackEnabled
            && UPower.onBattery
            && battery
            && Number.isFinite(battery.percentage)
            && battery.percentage * 100 <= Theme.batteryPerformanceFallbackThresholdPercent
    }

    function restoreBatteryEcoBrightness() {
        if (!batteryEcoBrightnessApplied)
            return
        batteryEcoBrightnessApplied = false
        brightness = batteryEcoBrightnessRestoreValue
        brightnessDebounce.restart()
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

    onEcoModeActiveChanged: checkEcoBrightness()
    onPowerProfileChanged: checkEcoBrightness()

    function cancelNotificationMute() {
        setNotificationMute(0)
        muteMessage = "Sourdine annulée"
        muteMessageTimer.restart()
    }

    Timer {
        id: muteTimer
        onTriggered: root.notificationMuteUntil = 0
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.notificationMuteUntil > 0
        onTriggered: {
            root.muteClockTick++
            if (root.notificationMuteUntil > 0 && Date.now() >= root.notificationMuteUntil)
                root.notificationMuteUntil = 0
        }
    }

    Timer {
        id: muteMessageTimer
        interval: 2500
        onTriggered: root.muteMessage = ""
    }

    NotificationServer {
        id: server
        bodySupported: true
        imageSupported: true
        keepOnReload: false

        onNotification: notif => {
            root.history = [{
                appName: notif.appName || "Notification",
                summary: notif.summary || "",
                body: notif.body || "",
                receivedAt: Qt.formatDateTime(new Date(), "HH:mm"),
                notification: notif
            }, ...root.history].slice(0, 20)
            if (!root.notificationsMuted || notif.urgency === NotificationUrgency.Critical)
                notif.tracked = true
        }
    }

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
        function onPercentageChanged() {
            root.checkBatteryPerformanceFallback()
        }
    }

    Connections {
        target: Theme
        function onEcoSettingsChanged() {
            if (root.ecoModeActive)
                root.applyEcoSettings()
            else
                root.checkEcoBrightness()
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
        onTriggered: root.refreshNetworkStatus()
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.checkBatteryPerformanceFallback()
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: {
            if (!activePowerProfileStatus.running)
                activePowerProfileStatus.running = true
        }
    }

    Component.onCompleted: {
        checkBatteryPerformanceFallback()
        activePowerProfileStatus.running = true
        refreshTlpChargeMode()
        refreshNetworkStatus()
    }

    Process {
        id: activePowerProfileStatus
        command: ["bash", "/home/jonathan/.config/quickshell/scripts/power-profile.sh"]
        stdout: StdioCollector {
            id: activePowerProfileOutput
        }
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
        stderr: SplitParser {
            onRead: line => console.warn("Power profile status:", line)
        }
    }

    Process {
        id: powerProfileCommand
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root.handlePowerProfileSelected("balanced")
            else
                console.warn("Returning to balanced power profile failed:", exitCode, exitStatus)
        }
        stderr: SplitParser {
            onRead: line => console.warn("Balanced power profile:", line)
        }
    }

    Process {
        id: tlpChargeCommand
        onExited: (exitCode, exitStatus) => {
            root.tlpChargeCommandRunning = false
            if (exitCode === 0) {
                root.tlpChargeMode = root.pendingTlpChargeMode
                root.refreshTlpChargeMode()
            } else {
                console.warn("TLP charge threshold update failed:", exitCode, exitStatus)
                root.refreshTlpChargeMode()
            }
            root.pendingTlpChargeMode = ""
        }
        stderr: SplitParser {
            onRead: line => console.warn("TLP charge thresholds:", line)
        }
    }

    Timer {
        id: tlpChargeLaunchTimer
        interval: 200
        repeat: false
        onTriggered: tlpChargeCommand.running = true
    }

    Process {
        id: tlpChargeStatus
        command: ["bash", "/home/jonathan/.config/quickshell/scripts/power-profile.sh", "charge-status"]
        stdout: StdioCollector {
            id: tlpChargeStatusOutput
        }
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
        stderr: SplitParser {
            onRead: line => console.warn("TLP charge threshold status:", line)
        }
    }

    Process {
        id: batteryProfileStatus
        command: ["bash", "/home/jonathan/.config/quickshell/scripts/power-profile.sh"]
        stdout: StdioCollector {
            id: batteryProfileOutput
        }
        stderr: SplitParser {
            onRead: line => console.warn("Battery power profile read:", line)
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("Battery power profile read failed:", exitCode, exitStatus)
                root.batteryPerformanceFallbackRunning = false
                root.batteryPerformanceFallbackTriggered = false
            } else if (!root.batteryPerformanceFallbackNeeded()) {
                root.batteryPerformanceFallbackRunning = false
            } else if (batteryProfileOutput.text.toLowerCase().includes("performance")) {
                batteryProfileFallback.command = [
                    "bash",
                    "/home/jonathan/.config/quickshell/scripts/power-profile.sh",
                    Theme.batteryFallbackProfile
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
        stderr: SplitParser {
            onRead: line => console.warn("Battery power profile fallback:", line)
        }
    }

    Process {
        id: batteryEcoBrightnessStatus
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            id: batteryEcoBrightnessOutput
        }
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
            if (currentBrightness <= ecoBrightness) {
                console.info("Eco profile brightness already at or below target:", percentage, "%")
                return
            }

            console.info("Reducing brightness for eco profile:", percentage, "% ->", root.ecoSettings.ecoBrightness, "%")
            root.batteryEcoBrightnessRestoreValue = currentBrightness
            root.batteryEcoBrightnessApplied = true
            root.brightness = ecoBrightness
            brightnessCommand.running = true
        }
        stderr: SplitParser {
            onRead: line => console.warn("Battery eco brightness:", line)
        }
    }

    Process {
        id: wifiStatus
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled"
                root.wifiStateKnown = true
            }
        }
        stderr: SplitParser {
            onRead: line => console.warn("Wi-Fi status:", line)
        }
    }

    Process {
        id: wifiConnectionStatus
        command: ["nmcli", "-t", "-f", "IN-USE,SSID", "dev", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const active = text.split("\n").find(line => line.startsWith("*:"))
                root.wifiNetworkName = active ? active.substring(2).trim() : ""
            }
        }
        stderr: SplitParser {
            onRead: line => console.warn("Wi-Fi connection status:", line)
        }
    }

    Process {
        id: wifiCommand
        command: ["nmcli", "radio", "wifi", root.wifiEnabled ? "on" : "off"]
        onExited: root.refreshQuickSettings()
        stderr: SplitParser {
            onRead: line => console.warn("Wi-Fi toggle:", line)
        }
    }

    Process {
        id: bluetoothStatus
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/^\s*Powered:\s*(yes|no)\s*$/m)
                if (match) {
                    root.bluetoothEnabled = match[1] === "yes"
                    root.bluetoothStateKnown = true
                } else {
                    root.bluetoothStateKnown = false
                }
            }
        }
        stderr: SplitParser {
            onRead: line => console.warn("Bluetooth status:", line)
        }
    }

    Process {
        id: bluetoothConnectionStatus
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                const devices = text.split("\n")
                    .map(line => line.match(/^Device\s+\S+\s+(.+)$/))
                    .filter(match => match)
                    .map(match => match[1].trim())
                root.bluetoothConnectedNames = devices.join(", ")
            }
        }
        stderr: SplitParser {
            onRead: line => console.warn("Bluetooth connection status:", line)
        }
    }

    Process {
        id: bluetoothCommand
        command: ["bluetoothctl", "power", root.bluetoothEnabled ? "on" : "off"]
        onExited: root.refreshQuickSettings()
        stderr: SplitParser {
            onRead: line => console.warn("Bluetooth toggle:", line)
        }
    }

    Process {
        id: soundStatus
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.soundMuted = text.includes("[MUTED]")
                root.soundStateKnown = text.trim().length > 0
            }
        }
        stderr: SplitParser {
            onRead: line => console.warn("Sound status:", line)
        }
    }

    Process {
        id: soundCommand
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        onExited: root.refreshQuickSettings()
        stderr: SplitParser {
            onRead: line => console.warn("Sound toggle:", line)
        }
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    Process {
        id: brightnessStatus
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                if (parts.length >= 4) {
                    const percentage = parseInt(parts[3])
                    if (Number.isFinite(percentage)) {
                        root.brightness = Math.max(0, Math.min(1, percentage / 100))
                        root.brightnessStateKnown = true
                    }
                }
            }
        }
        stderr: SplitParser {
            onRead: line => console.warn("Brightness status:", line)
        }
    }

    Process {
        id: brightnessCommand
        command: ["brightnessctl", "set", Math.round(root.brightness * 100) + "%"]
        stderr: SplitParser {
            onRead: line => console.warn("Brightness change:", line)
        }
        onExited: brightnessStatus.running = true
    }

    Process {
        id: powerProfileScript
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root.handlePowerProfileSelected(root.ecoModeActive ? "power-saver" : "balanced")
            else
                console.warn("Eco mode command failed:", exitCode, exitStatus)
        }
        stderr: SplitParser {
            onRead: line => console.warn("Eco mode:", line)
        }
    }

    Timer {
        id: brightnessDebounce
        interval: 120
        onTriggered: brightnessCommand.running = true
    }

    Timer {
        interval: 10000
        repeat: true
        running: root.panelOpen
        onTriggered: root.refreshQuickSettings()
    }

    PanelWindow {
        visible: server.trackedNotifications.values.length > 0
        anchors { top: true; right: !root.panelOpen; left: root.panelOpen }
        margins {
            top: Theme.barHeight + Theme.spacing
            right: root.panelOpen ? 0 : Theme.margin
            left: root.panelOpen ? Theme.margin : 0
        }
        implicitWidth: 360
        implicitHeight: stack.implicitHeight
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notifications"

        Column {
            id: stack
            width: parent.width
            spacing: Theme.spacing

            Repeater {
                model: server.trackedNotifications

                delegate: NotificationToast {
                    required property var modelData
                    width: stack.width
                    notification: modelData
                }
            }
        }
    }

    PanelWindow {
                    visible: root.panelOpen
                    screen: Quickshell.screens[0]
                    anchors { top: true; right: true; bottom: true; left: true }
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.namespace: "control-center"
                    WlrLayershell.keyboardFocus: root.panelOpen
                        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                    onVisibleChanged: {
                        console.info("Control panel window visible:", visible)
                        if (visible)
                            keyHandler.forceActiveFocus()
                    }

                    Item {
                        id: keyHandler
                        anchors.fill: parent
                        focus: root.panelOpen

                        Keys.onPressed: event => {
                            if (!root.panelOpen)
                                return
                            if (event.key === Qt.Key_Up)
                                root.showPanelMode("both")
                            else if (event.key === Qt.Key_Left)
                                root.showPanelMode("performance")
                            else if (event.key === Qt.Key_Right)
                                root.showPanelMode("notifications")
                            else
                                return
                            event.accepted = true
                        }
                    }

                    ModalBackdrop {
                        anchors.fill: parent
                        onDismissed: root.panelOpen = false
                    }

                    NotificationPanel {
                        anchors.fill: parent
                        controller: root
                    }

                    PerformancePanel {
                        anchors.fill: parent
                        controller: root
                    }

                    Rectangle {
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            top: parent.top
                            topMargin: 4
                        }
                        width: 312
                        height: 36
                        radius: Theme.cornerRadius
                        color: Qt.rgba(
                            Theme.componentBackground.r,
                            Theme.componentBackground.g,
                            Theme.componentBackground.b,
                            0.82
                        )
                        border.width: 1
                        border.color: Theme.buttonHover

                        Row {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 2

                            Repeater {
                                model: [
                                    { mode: "performance", label: "Perf.", icon: "keyboard_arrow_left" },
                                    { mode: "both", label: "Les deux", icon: "keyboard_arrow_up" },
                                    { mode: "notifications", label: "Notifs", icon: "keyboard_arrow_right" }
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    width: (parent.width - parent.spacing * 2) / 3
                                    height: parent.height
                                    radius: Theme.cornerRadius
                                    color: root.panelMode === modelData.mode
                                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                                        : modeMouse.containsMouse
                                            ? Qt.rgba(Theme.buttonHover.r, Theme.buttonHover.g, Theme.buttonHover.b, 0.55)
                                            : "transparent"

                                    Row {
                                        anchors.centerIn: parent
                                        height: parent.height
                                        spacing: 2

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.icon
                                            color: root.panelMode === modelData.mode ? Theme.accent : Theme.text
                                            font.family: Theme.iconFont
                                            font.pixelSize: Theme.iconSize
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.label
                                            color: root.panelMode === modelData.mode ? Theme.accent : Theme.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSize - 2
                                            font.weight: root.panelMode === modelData.mode ? Font.DemiBold : Font.Normal
                                        }
                                    }

                                    MouseArea {
                                        id: modeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.showPanelMode(modelData.mode)
                                    }
                                }
                            }
                        }
                    }
    }
}
