import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../theme"

PanelWindow {
    id: splash

    property real fade: Theme.splashDone ? 0 : 1
    Behavior on fade { NumberAnimation { duration: 350; easing.type: Easing.OutQuad } }
    visible: fade > 0

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-splash"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property string fg: "#d9d2cf"
    readonly property string dim: "#6e6663"
    readonly property string mono: Theme.monoFont

    property real p: 0
    readonly property int cells: 24
    readonly property int filled: Math.round(p * cells)

    Timer {
        running: splash.visible
        repeat: true
        interval: 30
        onTriggered: splash.p += ((Theme.themeReady ? 1 : 0.85) - splash.p) * 0.15
    }

    Item {
        anchors.fill: parent
        opacity: splash.fade

        Rectangle {
            anchors.fill: parent
            color: "#0d0b0a"
        }

        Column {
            anchors.centerIn: parent
            spacing: 10

            Row {
                spacing: 0
                Text {
                    textFormat: Text.RichText
                    font.family: splash.mono
                    font.pixelSize: 12
                    text: "<font color='" + splash.dim + "'>$</font> <font color='" + splash.fg + "'>init</font>"
                }
                Text {
                    id: cursor
                    font.family: splash.mono
                    font.pixelSize: 12
                    color: splash.fg
                    text: "_"
                    Timer {
                        running: splash.visible
                        repeat: true
                        interval: 450
                        onTriggered: cursor.opacity = cursor.opacity > 0 ? 0 : 1
                    }
                }
            }

            Text {
                textFormat: Text.RichText
                font.family: splash.mono
                font.pixelSize: 12
                text: "<font color='" + splash.dim + "'>palette</font>  <font color='" + splash.fg + "'>"
                      + (Theme.themeReady ? "ok" : "..") + "</font>"
            }

            Text {
                textFormat: Text.RichText
                font.family: splash.mono
                font.pixelSize: 12
                text: "<font color='" + splash.dim + "'>[</font>"
                      + "<font color='" + splash.fg + "'>" + "#".repeat(splash.filled) + "</font>"
                      + "<font color='" + splash.dim + "'>" + "-".repeat(splash.cells - splash.filled) + "]</font>"
                      + "  <font color='" + splash.fg + "'>"
                      + (splash.filled === splash.cells ? 100 : Math.round(splash.p * 100)) + "%</font>"
            }
        }
    }
}
