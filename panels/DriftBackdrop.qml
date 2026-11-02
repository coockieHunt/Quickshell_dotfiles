import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../theme"

Scope {
    id: root
    property bool shown: false

    IpcHandler {
        target: "drift-backdrop"
        function show(): void {
            root.shown = true
        }
        function hide(): void {
            root.shown = false
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "drift-backdrop"
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                opacity: root.shown ? 1 : 0
                color: Qt.rgba(0, 0, 0, 0.65)
            }
        }
    }
}
