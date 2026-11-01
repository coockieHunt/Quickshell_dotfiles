// Used by: 1 file(s)
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import "../theme"

Scope {
    id: root
    property bool ready: false
    property string icon: "volume_up"
    property real value: 0
    property bool shown: false

    Timer { interval: 2000; running: true; onTriggered: root.ready = true }

    function show(ic, v) {
        icon = ic
        value = Math.max(0, Math.min(1, v))
        shown = true
        hideTimer.restart()
    }

    Timer { id: hideTimer; interval: 1500; onTriggered: root.shown = false }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

    function showVolume() {
        if (!ready || !audio) return
        const v = audio.volume
        const ic = audio.muted || v === 0 ? "volume_off" : (v < 0.5 ? "volume_down" : "volume_up")
        show(ic, audio.muted ? 0 : v)
    }

    Connections {
        target: root.audio
        function onVolumeChanged() { root.showVolume() }
        function onMutedChanged() { root.showVolume() }
    }

    Process {
        id: brightnessProc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                if (parts.length >= 4)
                    root.show("brightness_6", parseInt(parts[3]) / 100)
            }
        }
    }

    IpcHandler {
        target: "osd"
        function brightness(): void { brightnessProc.running = true }
    }

    PanelWindow {
        visible: root.shown
        anchors { bottom: true }
        margins { bottom: 80 }
        implicitWidth: 300
        implicitHeight: 56
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "osd"
        mask: Region {}

        Rectangle {
            anchors.fill: parent
            radius: Theme.cornerRadius
            color: Theme.componentBackground
            border.width: 2
            border.color: Theme.componentBorder

            Row {
                anchors.centerIn: parent
                spacing: Theme.margin

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.icon
                    color: Theme.accent
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.iconSize + 6
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 170
                    height: 8
                    radius: Theme.cornerRadius
                    color: Theme.componentSurface

                    Rectangle {
                        width: parent.width * root.value
                        height: parent.height
                        radius: Theme.cornerRadius
                        color: Theme.accent
                        Behavior on width { NumberAnimation { duration: 80 } }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    text: Math.round(root.value * 100) + "%"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }
}