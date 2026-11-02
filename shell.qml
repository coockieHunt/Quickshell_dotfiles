// Used by: 0 file(s)
import Quickshell
import Quickshell.Io
import "panels"

Scope {
    id: root
    property bool barVisible: true

    Wallpaper {}
    DriftBackdrop {}
    DesktopWidgets {}
    Launcher { id: launcher }
    WallpaperPicker { id: picker }
    PowerMenu { id: powerMenu }
    Watchers {}
    Notifications {
        id: notifications
        performanceControl: bar.performanceSource
    }
    OSD {}

    Bar {
        id: bar
        barVisible: root.barVisible && !notifications.panelOpen
        launcherControl: launcher
        wallpaperPicker: picker
        powerMenuControl: powerMenu
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
