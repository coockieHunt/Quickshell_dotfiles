import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire

Item {
    id: root

    property bool soundMuted: false
    property bool soundStateKnown: false
    readonly property var audio: Pipewire.defaultAudioSink
        ? Pipewire.defaultAudioSink.audio : null

    property bool micMuted: false
    property bool micStateKnown: false
    readonly property var mic: Pipewire.defaultAudioSource
        ? Pipewire.defaultAudioSource.audio : null

    function refresh() {
        if (!soundStatus.running) soundStatus.running = true
        if (!micStatus.running) micStatus.running = true
    }

    function toggleSound() {
        if (!soundCommand.running) soundCommand.running = true
    }

    function toggleMic() {
        if (!micCommand.running) micCommand.running = true
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    Process {
        id: soundStatus
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.soundMuted = text.includes("[MUTED]")
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
