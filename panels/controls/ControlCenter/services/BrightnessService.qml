import QtQuick
import Quickshell.Io
import "../../../../theme"

Item {
    id: root

    property real brightness: 0
    property bool brightnessStateKnown: false
    readonly property bool shouldReduceEcoBrightness: Theme.ecoSettings
        && Theme.ecoSettings.reduceBrightness === true

    function setBrightness(value) {
        brightnessDebounce.restart()
        pendingBrightness = Math.max(0, Math.min(1, value))
    }

    function applyBrightness(value) {
        brightness = Math.max(0, Math.min(1, value))
        brightnessCommand.running = true
    }

    property real pendingBrightness: 0

    function refresh() {
        if (!brightnessStatus.running) brightnessStatus.running = true
    }

    Timer {
        id: brightnessDebounce
        interval: 120
        onTriggered: {
            root.brightness = root.pendingBrightness
            brightnessCommand.running = true
        }
    }

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
        stderr: SplitParser { onRead: line => console.warn("Brightness status:", line) }
    }

    Process {
        id: brightnessCommand
        command: ["brightnessctl", "set", Math.round(root.brightness * 100) + "%"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("Brightness command failed:", exitCode, exitStatus)
            root.refresh()
        }
        stderr: SplitParser { onRead: line => console.warn("Brightness:", line) }
    }
}
