// Used by: 1 file(s)
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

Scope {
    id: root
    property bool ready: false
    property bool lowWarned: false

    Timer {
        interval: 2000
        running: true
        onTriggered: root.ready = true
    }

    function notify(title, body, urgency) {
        Quickshell.execDetached(["notify-send", "-u", urgency || "normal", title, body || ""])
    }

    Connections {
        target: UPower
        function onOnBatteryChanged() {
            if (!root.ready) return
            if (UPower.onBattery) root.notify("Chargeur débranché", "Sur batterie")
            else root.notify("Chargeur branché", "Système d'alimentation")
        }
    }

    Connections {
        target: UPower.displayDevice
        function onPercentageChanged() {
            const pct = Math.round(UPower.displayDevice.percentage * 100)
            if (pct <= 15 && UPower.onBattery && !root.lowWarned) {
                root.lowWarned = true
                root.notify("Batterie faible", pct + " % restant", "critical")
            } else if (pct > 20) {
                root.lowWarned = false
            }
        }
    }

    Process {
        id: usbMonitor
        running: true
        command: ["udevadm", "monitor", "--udev", "--property",
                  "--subsystem-match=usb/usb_device"]

        property string action: ""
        property string devpath: ""
        property string model: ""
        property string dbModel: ""
        property string vendor: ""
        property bool external: false
        property var known: ({})

        function flush() {
            if (devpath === "") return
            if ((action === "add" || action === "bind") && external && known[devpath] === undefined) {
                const m = dbModel !== "" ? dbModel : model
                const n = ((vendor !== "" ? vendor + " " : "") + m).trim() || "Périphérique USB"
                known[devpath] = n
                if (root.ready) root.notify("USB branché", n)
            } else if (action === "remove" && known[devpath] !== undefined) {
                if (root.ready) root.notify("USB débranché", known[devpath])
                delete known[devpath]
            }
            action = ""; devpath = ""; model = ""; dbModel = ""
            vendor = ""; external = false
        }

        stdout: SplitParser {
            
            onRead: line => {
                if (line.startsWith("UDEV")) usbMonitor.flush()
                else if (line.startsWith("ACTION=")) usbMonitor.action = line.substring(7)
                else if (line.startsWith("DEVPATH=")) usbMonitor.devpath = line.substring(8)
                else if (line.startsWith("ID_MODEL=")) usbMonitor.model = line.substring(9).replace(/_/g, " ")
                else if (line.startsWith("ID_MODEL_FROM_DATABASE=")) usbMonitor.dbModel = line.substring(23)
                else if (line.startsWith("ID_VENDOR_FROM_DATABASE=")) usbMonitor.vendor = line.substring(24)
                else if (line === "ID_INTEGRATION=external") usbMonitor.external = true
                flushTimer.restart()
            }
        }
    }

    Timer {
        id: flushTimer
        interval: 300
        onTriggered: usbMonitor.flush()
    }
}