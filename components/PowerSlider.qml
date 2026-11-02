// Used by: 1 file(s)
import QtQuick
import Quickshell.Io
import "."

Item {
    id: root

    property int value: 1
    property bool profileCommandPending: false
    readonly property string scriptPath: "/home/jonathan/.config/quickshell/scripts/power-profile.sh"
    readonly property var profileNames: ["eco", "balanced", "performance"]
    readonly property var options: [
        { label: "Éco", icon: "eco" },
        { label: "Équilibré", icon: "balance" },
        { label: "Performance", icon: "bolt" }
    ]

    signal profileRequested(string profile)
    signal profileChanged(int profile)

    implicitHeight: 40
    height: 40

    function refresh() {
        readProc.running = true
    }

    function apply(idx) {
        if (idx < 0 || idx > 2 || profileCommandPending)
            return
        value = idx
        profileRequested(profileNames[idx])
        setProc.command = ["bash", scriptPath, profileNames[idx]]
        profileCommandPending = true
        launchTimer.start()
    }

    Process {
        id: readProc
        command: ["bash", root.scriptPath]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text
                if (t.includes("power-saver"))
                    root.value = 0
                else if (t.includes("performance"))
                    root.value = 2
                else if (t.includes("balanced"))
                    root.value = 1
            }
        }
        stderr: SplitParser {
            onRead: line => console.warn("Power profile read:", line)
        }
    }

    Process {
        id: setProc
        stderr: SplitParser {
            onRead: line => console.warn("Power profile set:", line)
        }
        onExited: (exitCode, exitStatus) => {
            root.profileCommandPending = false
            if (exitCode !== 0) {
                console.warn("Power profile command failed:", exitCode, exitStatus)
                root.refresh()
            } else {
                root.profileChanged(root.value)
            }
        }
    }

    Timer {
        id: launchTimer
        interval: 200
        repeat: false
        onTriggered: setProc.running = true
    }

    Component.onCompleted: refresh()

    SegmentedControl {
        anchors.fill: parent
        options: root.options
        selectedIndex: root.value
        enabled: !root.profileCommandPending
        dragEnabled: true
        onSelected: index => root.apply(index)
    }
}