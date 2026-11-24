import Quickshell
import Quickshell.Io
import "panels/apps"
import "panels/controls"
import "panels/desktop"
import "panels/notifications"
import "panels/services"
import "panels/shell"

Scope {
    id: root
    property bool barVisible: true
    LoadingScreen {}
    Wallpaper {}
    DriftBackdrop {}
    Launcher { id: launcher }
    WallpaperPicker { id: picker }
    PowerMenu { id: powerMenu }
    Macro { id: macro }
    Watchers {}
    Notifications {
        id: notifications
        performanceControl: bar.performanceSource
        macroControl: macro
    }
    OSD {}

    Bar {
        id: bar
        barVisible: root.barVisible && !notifications.panelOpen
        launcherControl: launcher
        wallpaperPicker: picker
        notificationControl: notifications
        onHideRequested: root.barVisible = false
    }

    IpcHandler {
        target: "bar"
        function toggle(): void { root.barVisible = !root.barVisible }
        function show(): void { root.barVisible = true }
        function hide(): void { root.barVisible = false }
    }
}
