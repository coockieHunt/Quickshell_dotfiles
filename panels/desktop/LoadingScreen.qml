import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../theme"

PanelWindow {
    id: splash

    readonly property int minDurationMs: 1500

    property real fade: (Theme.splashDone && elapsedMs >= minDurationMs) ? 0 : 1
    Behavior on fade { NumberAnimation { duration: 350; easing.type: Easing.OutQuad } }
    visible: fade > 0

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-splash"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: "#0d0b0a"
    }

    readonly property color fg: Theme.themeReady ? Theme.text : "#d9d2cf"
    readonly property color dim: Theme.themeReady ? Qt.tint(Theme.text, Qt.rgba(0, 0, 0, 0.55)) : "#8a807b"
    readonly property color fill: Theme.themeReady ? Theme.accent : "#d9d2cf"

    readonly property real target: Theme.themeReady ? 1.0 : 0.92

    property real p: 0
    readonly property int cells: 24
    readonly property int filled: Math.round(p * cells)

    property int elapsedMs: 0

    Timer {
        running: splash.visible
        repeat: true
        interval: 30
        onTriggered: {
            splash.p += (splash.target - splash.p) * 0.15
            splash.elapsedMs += 30
        }
    }

    Item {
        anchors.fill: parent
        opacity: splash.fade

        Column {
            anchors { top: parent.top; left: parent.left; margins: 24 }
            spacing: 6

            Text {
                text: Theme.archLogo
                textFormat: Text.RichText
                font.family: Theme.monoFont
                font.pixelSize: 22
                color: splash.fill
            }

            Text {
                textFormat: Text.RichText
                font.family: Theme.monoFont
                font.pixelSize: 14
                text: "<font color='" + splash.fg + "'>booting</font> <font color='" + splash.dim + "'>quickshell…</font>"
            }

            Text {
                textFormat: Text.RichText
                font.family: Theme.monoFont
                font.pixelSize: 14
                text: "<font color='" + splash.dim + "'>palette</font>  <font color='" + splash.fill + "'>"
                      + (Theme.themeReady ? "ok" : "..") + "</font>"
            }

            Text {
                textFormat: Text.RichText
                font.family: Theme.monoFont
                font.pixelSize: 14
                text: "<font color='" + splash.dim + "'>[</font>"
                      + "<font color='" + splash.fill + "'>" + "█".repeat(splash.filled) + "</font>"
                      + "<font color='" + "#4a4441" + "'>" + "░".repeat(splash.cells - splash.filled) + "]</font>"
                      + "  <font color='" + splash.fg + "'>"
                      + (splash.filled === splash.cells ? 100 : Math.round(splash.p * 100)) + "%</font>"
            }
        }

        Text {
            anchors { bottom: parent.bottom; left: parent.left; margins: 24 }
            textFormat: Text.RichText
            font.family: Theme.monoFont
            font.pixelSize: 11
            text: "<font color='" + splash.dim + "'>if it doesn't exist, build it.</font>"
        }
    }
}
