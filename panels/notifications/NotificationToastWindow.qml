import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../components/notification"
import "../../theme"

PanelWindow {
    id: win

    required property var notifications
    property bool panelOpen: false

    visible: notifications.values.length > 0

    anchors { top: true; right: !panelOpen; left: panelOpen }
    margins {
        top: Theme.barHeight + Theme.spacing
        right: panelOpen ? 0 : Theme.margin
        left: panelOpen ? Theme.margin : 0
    }

    implicitWidth: 360
    implicitHeight: stack.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notifications"

    Column {
        id: stack
        width: parent.width
        spacing: Theme.spacing

        Repeater {
            model: win.notifications

            delegate: NotificationToast {
                required property var modelData
                width: stack.width
                notification: modelData
            }
        }
    }
}
