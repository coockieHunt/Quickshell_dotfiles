// Used by: 1 file(s)
import QtQuick
import Quickshell.Io
import "../theme"

Rectangle {
    id: root

    property int value: 1
    readonly property string scriptPath: "/home/jonathan/.config/quickshell/scripts/power-profile.sh"
    readonly property var profileNames: ["eco", "balanced", "performance"]
    readonly property var labels: ["Éco", "Équilibré", "Performance"]
    readonly property var icons: ["eco", "balance", "bolt"]

    signal profileChanged(int profile)

    implicitHeight: 40
    height: 40
    radius: Theme.cornerRadius
    color: Theme.surface

    function refresh() {
        readProc.running = true
    }

    function apply(idx) {
        if (idx < 0 || idx > 2 || setProc.running)
            return
        value = idx
        setProc.command = ["bash", scriptPath, profileNames[idx]]
        setProc.running = true
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
            if (exitCode !== 0) {
                console.warn("Power profile command failed:", exitCode, exitStatus)
                root.refresh()
            } else {
                root.profileChanged(root.value)
            }
        }
        onRunningChanged: {
            if (!running) {
                refreshTimer.restart()
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 150
        repeat: false
        onTriggered: refresh()
    }

    Component.onCompleted: refresh()

    Item {
        id: track
        anchors.fill: parent
        anchors.margins: 4

        Rectangle {
            id: thumb
            width: track.width / 3
            height: track.height
            radius: Theme.cornerRadius - 2
            color: Theme.accent
            x: track.width / 3 * root.value

            Behavior on x {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
        }

        Repeater {
            model: 3

            Item {
                required property int index

                x: track.width / 3 * index
                width: track.width / 3
                height: track.height

                Row {
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.icons[index]
                        color: root.value === index ? Theme.textOnAccent : Theme.text
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.iconSize - 2
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.labels[index]
                        color: root.value === index ? Theme.textOnAccent : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                        font.weight: root.value === index ? Font.DemiBold : Font.Normal
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: !setProc.running

        function indexFromX(px) {
            return Math.min(2, Math.max(0, Math.floor(px / (width / 3))))
        }

        onPressed: mouse => root.value = indexFromX(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                root.value = indexFromX(mouse.x)
        }
        onReleased: mouse => root.apply(indexFromX(mouse.x))
        onCanceled: root.refresh()
    }
}