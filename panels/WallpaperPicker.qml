// Used by: 1 file(s)
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Qt.labs.folderlistmodel
import QtQuick
import "../components"
import "../theme"

PanelWindow {
    id: root
    visible: false
    property string hoveredWallpaper: ""
    property string wallpaperToDelete: ""
    property string deletionError: ""
    property bool deletingCurrentWallpaper: false
    property var previewPalette: []
    readonly property var paletteLabels: Theme.wallpaperPaletteLabels
    readonly property var currentPalette: [
        { key: "background", color: Theme.bg },
        { key: "surface",         color: Theme.componentSurface },
        { key: "primary", color: Theme.accent },
        { key: "secondary", color: Theme.buttonHover },
        { key: "tertiary", color: Theme.text }
    ]

    function toggle() { visible = !visible }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { root.toggle() }
    }

    Process {
        id: deleteProcess
        command: [Theme.wallpaperScript, "delete", root.wallpaperToDelete]

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                if (root.hoveredWallpaper === root.wallpaperToDelete) {
                    root.hoveredWallpaper = ""
                    root.previewPalette = []
                }
                root.wallpaperToDelete = ""
                if (root.deletingCurrentWallpaper)
                    Quickshell.execDetached([Theme.wallpaperScript, "random"])
                root.deletingCurrentWallpaper = false
            } else {
                root.deletionError = "La suppression du fond d’écran a échoué."
                console.warn("Impossible de supprimer le fond d’écran:", root.wallpaperToDelete)
            }
        }
    }

    screen: Quickshell.screens[0]
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-wallpaper-picker"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    ModalBackdrop {
        anchors.fill: parent
        onDismissed: root.visible = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(1000, root.screen.width * 0.88)
        height: Math.min(760, root.screen.height * 0.88)
        radius: Theme.cornerRadius
        color: Theme.componentBackground
        border.color: Theme.componentBorder

        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: pickerContent
            anchors.fill: parent
            anchors.margins: Theme.margin

            GridView {
                id: grid
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    bottom: paletteFooter.top
                    bottomMargin: Theme.spacing
                }
                cellWidth: Math.max(160, Math.floor(width / 4))
                cellHeight: Math.round(cellWidth * 0.62)
                clip: true
                cacheBuffer: cellHeight

                model: FolderListModel {
                    folder: "file://" + Theme.wallpaperDir
                    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
                    showDirs: false
                }

                delegate: Item {
                    id: wallpaperItem
                    required property string filePath
                    property var paletteColors: []
                    readonly property bool nearViewport:
                        y + height >= grid.contentY - grid.cacheBuffer
                        && y <= grid.contentY + grid.height + grid.cacheBuffer
                    width: grid.cellWidth
                    height: grid.cellHeight

                    function loadPalette() {
                        if (paletteColors.length === 0 && !paletteProcess.running)
                            paletteProcess.running = true
                    }

                    Process {
                        id: paletteProcess
                        command: [
                            "matugen", "image", "--dry-run", "--json", "hex",
                            "--mode", "dark", "--source-color-index", "0", filePath
                        ]
                        stdout: StdioCollector {
                            onStreamFinished: {
                                try {
                                    const colors = JSON.parse(text).colors
                                    const palette = [
                                        { key: "background", color: colors.background.dark.color },
                                        { key: "surface", color: colors.surface.dark.color },
                                        { key: "primary", color: colors.primary.dark.color },
                                        { key: "secondary", color: colors.secondary.dark.color },
                                        { key: "tertiary", color: colors.tertiary.dark.color }
                                    ]
                                    wallpaperItem.paletteColors = palette
                                    if (root.hoveredWallpaper === filePath)
                                        root.previewPalette = palette
                                } catch (error) {
                                    console.warn("Impossible de générer l'aperçu de palette pour", filePath, ":", error)
                                }
                            }
                        }
                    }

                    Image {
                        id: thumbnail
                        anchors.fill: parent
                        anchors.margins: 4
                        source: root.visible && wallpaperItem.nearViewport
                            ? "file://" + filePath
                            : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: grid.cellWidth - 8
                        sourceSize.height: grid.cellHeight - 8
                        asynchronous: true
                        cache: false
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        visible: thumbnail.status !== Image.Ready
                        color: Theme.componentSurface

                        Text {
                            anchors.centerIn: parent
                            text: thumbnail.status === Image.Error ? "Image indisponible" : "Chargement…"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        color: "transparent"
                        border.width: filePath === Theme.wallpaper ? 3 : 1
                        border.color: filePath === Theme.wallpaper
                                      ? Theme.accent
                                      : wallpaperMouse.containsMouse ? Theme.text : "transparent"
                        z: 1
                    }

                    Rectangle {
                        id: wallpaperBadge
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: 8
                        z: 4
                        width: badgeContents.implicitWidth + Theme.margin
                        height: Theme.buttonSize
                        radius: Theme.cornerRadius
                        color: filePath === Theme.wallpaper
                            ? (badgeMouse.containsMouse ? Theme.buttonHover : Theme.accent)
                            : (badgeMouse.containsMouse ? Theme.buttonHover : Theme.componentSurface)
                        border.width: 1
                        border.color: filePath === Theme.wallpaper
                            ? Theme.accent
                            : Theme.componentBorder

                        Row {
                            id: badgeContents
                            anchors.centerIn: parent
                            spacing: Theme.spacing

                            Text {
                                visible: filePath === Theme.wallpaper
                                text: "Actuel"
                                color: Theme.textOnAccent
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                visible: filePath !== Theme.wallpaper
                                text: "Supprimer"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: badgeMouse
                            anchors.fill: parent
                            enabled: filePath !== Theme.wallpaper
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                root.wallpaperToDelete = filePath
                                root.deletingCurrentWallpaper = filePath === Theme.wallpaper
                                root.deletionError = ""
                            }
                        }
                    }

                    MouseArea {
                        id: wallpaperMouse
                        anchors.fill: parent
                        z: 3
                        hoverEnabled: true
                        onEntered: {
                            root.hoveredWallpaper = filePath
                            root.previewPalette = wallpaperItem.paletteColors
                            wallpaperItem.loadPalette()
                        }
                        onExited: {
                            if (root.hoveredWallpaper === filePath) {
                                root.hoveredWallpaper = ""
                                root.previewPalette = []
                            }
                        }
                        onClicked: {
                            Quickshell.execDetached([Theme.wallpaperScript, "set", filePath])
                            root.visible = false
                        }
                    }
                }
            }

            Item {
                id: paletteFooter
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: 76

                WallpaperPalette {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: footerActions.left
                    anchors.rightMargin: Theme.spacing
                    colors: root.previewPalette.length > 0
                        ? root.previewPalette
                        : root.currentPalette
                    labels: root.paletteLabels
                    preview: root.previewPalette.length > 0
                }

                Row {
                    id: footerActions
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: Theme.buttonSize + Theme.spacing
                    spacing: Theme.spacing

                    BarButton {
                        height: parent.height
                        label: "shuffle"
                        tooltip: "Choisir un fond d’écran au hasard"
                        onClicked: {
                            Quickshell.execDetached([Theme.wallpaperScript, "random"])
                            root.visible = false
                        }
                    }

                    BarButton {
                        height: parent.height
                        label: "folder_open"
                        tooltip: "Ouvrir le dossier des fonds d’écran"
                        onClicked: {
                            Quickshell.execDetached(["xdg-open", Theme.wallpaperDir])
                            root.visible = false
                        }
                    }

                    TextButton {
                        text: "Supprimer le fond actuel"
                        enabled: Theme.wallpaper !== ""
                        onClicked: {
                            root.wallpaperToDelete = Theme.wallpaper
                            root.deletingCurrentWallpaper = true
                            root.deletionError = ""
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.wallpaperToDelete !== ""
        color: Qt.rgba(0, 0, 0, 0.55)
        z: 10

        MouseArea {
            anchors.fill: parent
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(380, root.width - Theme.margin * 2)
            height: confirmationContent.implicitHeight + Theme.margin * 2
            radius: Theme.cornerRadius
            color: Theme.componentBackground
            border.color: Theme.componentBorder

            Column {
                id: confirmationContent
                anchors.fill: parent
                anchors.margins: Theme.margin
                spacing: Theme.spacing

                Text {
                    width: parent.width
                    text: "Supprimer ce fond d’écran ?"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                }

                Text {
                    width: parent.width
                    text: root.deletionError || "Cette action est définitive."
                    color: root.deletionError ? Theme.danger : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    wrapMode: Text.Wrap
                }

                Row {
                    anchors.right: parent.right
                    spacing: Theme.spacing

                    TextButton {
                        text: "Annuler"
                        enabled: !deleteProcess.running
                        onClicked: {
                            root.wallpaperToDelete = ""
                            root.deletingCurrentWallpaper = false
                        }
                    }

                    TextButton {
                        text: "Supprimer"
                        highlighted: true
                        enabled: !deleteProcess.running
                        onClicked: {
                            root.deletionError = ""
                            deleteProcess.running = true
                        }
                    }
                }
            }
        }
    }
}