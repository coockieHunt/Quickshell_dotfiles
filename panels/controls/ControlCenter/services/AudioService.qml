import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire

Item {
    id: root

    property bool soundMuted: false
    property bool soundStateKnown: false
    property int soundVolume: 0
    readonly property var audio: Pipewire.defaultAudioSink
        ? Pipewire.defaultAudioSink.audio : null

    property bool micMuted: false
    property bool micStateKnown: false
    readonly property var mic: Pipewire.defaultAudioSource
        ? Pipewire.defaultAudioSource.audio : null

    readonly property real micVolume: mic ? mic.volume : 0

    function refresh() {
        if (!soundStatus.running) soundStatus.running = true
        if (!micStatus.running) micStatus.running = true
    }

    function toggleSound() {
        if (!soundCommand.running) soundCommand.running = true
    }

    function changeSoundVolume(deltaPercent) {
        if (soundVolumeCommand.running) return
        const sign = deltaPercent >= 0 ? "+" : "-"
        const amount = Math.abs(deltaPercent)
        soundVolumeCommand.command = ["wpctl", "set-volume", "-l", "1.0",
            "@DEFAULT_AUDIO_SINK@", amount + "%" + sign]
        soundVolumeCommand.running = true
    }

    function toggleMic() {
        if (!micCommand.running) micCommand.running = true
    }

    function setMicVolume(value) {
        if (!mic) return
        mic.volume = Math.max(0, Math.min(1, value))
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    Process {
        id: soundStatus
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.soundMuted = text.includes("[MUTED]")
                const match = text.match(/Volume:\s*([\d.]+)/)
                root.soundVolume = match ? Math.round(parseFloat(match[1]) * 100) : 0
                root.soundStateKnown = text.trim().length > 0
            }
        }
        stderr: SplitParser { onRead: line => console.warn("Sound status:", line) }
    }

    Process {
        id: soundCommand
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        onExited: root.refresh()
        stderr: SplitParser { onRead: line => console.warn("Sound toggle:", line) }
    }

    Process {
        id: soundVolumeCommand
        onExited: root.refresh()
        stderr: SplitParser { onRead: line => console.warn("Sound volume:", line) }
    }

    Process {
        id: micStatus
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.micMuted = text.includes("[MUTED]")
                root.micStateKnown = text.trim().length > 0
            }
        }
        stderr: SplitParser { onRead: line => console.warn("Mic status:", line) }
    }

    Process {
        id: micCommand
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
        onExited: root.refresh()
        stderr: SplitParser { onRead: line => console.warn("Mic toggle:", line) }
    }
}
