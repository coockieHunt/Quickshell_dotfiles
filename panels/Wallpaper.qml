// Used by: 1 file(s)
import Quickshell
import Quickshell.Wayland
import QtQuick
import "../theme"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: wallpaperWindow
        required property var modelData
        property bool firstActive: true

        screen: modelData

        function loadWallpaper(path) {
            if (path === "") {
                const activeImage = firstActive ? firstImage : secondImage
                fadeOut.target = activeImage
                fadeOut.restart()
                return
            }

            const nextImage = firstActive ? secondImage : firstImage
            nextImage.pendingFade = true
            nextImage.opacity = 0
            nextImage.source = "file://" + path
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "wallpaper"
        color: Theme.componentBackground

        Image {
            id: firstImage
            anchors.fill: parent
            opacity: 0
            property bool pendingFade: false
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: modelData.width
            sourceSize.height: modelData.height
            asynchronous: true
            onStatusChanged: {
                if (status === Image.Ready && pendingFade) {
                    pendingFade = false
                    fadeIn.target = firstImage
                    fadeIn.restart()
                    fadeOut.target = wallpaperWindow.firstActive ? firstImage : secondImage
                    fadeOut.restart()
                    wallpaperWindow.firstActive = !wallpaperWindow.firstActive
                } else if (status === Image.Error) {
                    pendingFade = false
                    console.warn("Impossible de charger le fond d’écran:", source)
                }
            }
        }

        Image {
            id: secondImage
            anchors.fill: parent
            opacity: 0
            property bool pendingFade: false
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: modelData.width
            sourceSize.height: modelData.height
            asynchronous: true
            onStatusChanged: {
                if (status === Image.Ready && pendingFade) {
                    pendingFade = false
                    fadeIn.target = secondImage
                    fadeIn.restart()
                    fadeOut.target = wallpaperWindow.firstActive ? firstImage : secondImage
                    fadeOut.restart()
                    wallpaperWindow.firstActive = !wallpaperWindow.firstActive
                } else if (status === Image.Error) {
                    pendingFade = false
                    console.warn("Impossible de charger le fond d’écran:", source)
                }
            }
        }

        NumberAnimation {
            id: fadeIn
            property: "opacity"
            to: 1
            duration: 450
            easing.type: Easing.InOutCubic
        }

        NumberAnimation {
            id: fadeOut
            property: "opacity"
            to: 0
            duration: 450
            easing.type: Easing.InOutCubic
        }

        Connections {
            target: Theme
            function onWallpaperChanged() {
                wallpaperWindow.loadWallpaper(Theme.wallpaper)
            }
        }

        Component.onCompleted: {
            if (Theme.wallpaper !== "")
                loadWallpaper(Theme.wallpaper)
        }

    }
}
