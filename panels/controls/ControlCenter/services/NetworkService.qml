import QtQuick
import Quickshell.Io

Item {
    id: root

    property bool wifiEnabled: false
    property bool bluetoothEnabled: false
    property string wifiNetworkName: ""
    property string bluetoothConnectedNames: ""
    property int wifiSignal: 0
    property bool wifiStateKnown: false
    property bool bluetoothStateKnown: false
    readonly property bool airplaneEnabled: wifiStateKnown && bluetoothStateKnown
        && !wifiEnabled && !bluetoothEnabled

    function refresh() {
        if (!wifiStatus.running) wifiStatus.running = true
        if (!wifiConnectionStatus.running) wifiConnectionStatus.running = true
        if (!bluetoothStatus.running) bluetoothStatus.running = true
        if (!bluetoothConnectionStatus.running) bluetoothConnectionStatus.running = true
    }

    function setWifi(enable) {
        wifiEnabled = enable
        wifiCommand.command = ["nmcli", "radio", "wifi", enable ? "on" : "off"]
        wifiCommand.running = true
    }

    function setBluetooth(enable) {
        bluetoothEnabled = enable
        bluetoothCommand.command = ["bluetoothctl", "power", enable ? "on" : "off"]
        bluetoothCommand.running = true
    }

    function toggleWifi() {
        setWifi(!wifiEnabled)
    }

    function toggleBluetooth() {
        setBluetooth(!bluetoothEnabled)
    }

    function toggleAirplane() {
        const enable = !airplaneEnabled
        setWifi(!enable)
        setBluetooth(!enable)
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
        stderr: SplitParser { onRead: line => console.warn("Wi-Fi status:", line) }
    }

    Process {
        id: wifiConnectionStatus
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL", "dev", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const active = text.split("\n").find(line => line.startsWith("*:"))
                if (active) {
                    const parts = active.split(":")
                    root.wifiNetworkName = parts[1].trim()
                    root.wifiSignal = parseInt(parts[parts.length - 1]) || 0
                } else {
                    root.wifiNetworkName = ""
                    root.wifiSignal = 0
                }
            }
        }
        stderr: SplitParser { onRead: line => console.warn("Wi-Fi connection status:", line) }
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
        stderr: SplitParser { onRead: line => console.warn("Bluetooth status:", line) }
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
        stderr: SplitParser { onRead: line => console.warn("Bluetooth connection status:", line) }
    }

    Process {
        id: wifiCommand
        onExited: root.refresh()
        stderr: SplitParser { onRead: line => console.warn("Wi-Fi toggle:", line) }
    }

    Process {
        id: bluetoothCommand
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("Bluetooth toggle failed:", exitCode, exitStatus)
            root.refresh()
        }
        stderr: SplitParser { onRead: line => console.warn("Bluetooth toggle:", line) }
    }
}
