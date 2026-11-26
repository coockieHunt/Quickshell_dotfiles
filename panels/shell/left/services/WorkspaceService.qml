import QtQuick
import Quickshell.Hyprland

QtObject {
    id: root

    required property string screenName

    readonly property var workspaces: Hyprland.workspaces.values
        .filter(w => w.id > 0 && w.monitor?.name === root.screenName)
        .sort((x, y) => x.id - y.id)
}
