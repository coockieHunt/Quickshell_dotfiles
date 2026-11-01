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

                model: FolderListModel {
                    folder: "file://" + Theme.wallpaperDir
                    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
                    showDirs: false
                }

                delegate: Item {
                    id: wallpaperItem
                    required property string filePath
                    property var paletteColors: []
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
                        source: "file://" + filePath
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: grid.cellWidth - 8
                        sourceSize.height: grid.cellHeight - 8
                        asynchronous: true
                        cache: true
                        retainWhileLoading: true
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
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: 8
                        visible: filePath === Theme.wallpaper
                        z: 2
                        width: currentLabel.implicitWidth + 12
                        height: currentLabel.implicitHeight + 6
                        radius: Theme.cornerRadius
                        color: Theme.accent

                        Text {
                            id: currentLabel
                            anchors.centerIn: parent
                            text: "Actuel"
                            color: Theme.textOnAccent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
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
                height: 72

                Text {
                    id: paletteTitle
                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: "Palette"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    font.weight: Font.DemiBold
                }

                Text {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    text: root.previewPalette.length > 0 ? "Aperçu" : "Thème actuel"
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.55)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 3
                }

                Row {
                    anchors.left: parent.left
                    anchors.top: paletteTitle.bottom
                    anchors.topMargin: 4
                    height: 42
                    spacing: Theme.spacing

                    Repeater {
                        model: root.previewPalette.length > 0
                            ? root.previewPalette
                            : root.currentPalette

                        Item {
                            required property var modelData
                            width: 48
                            height: 42

                            Column {
                                anchors.fill: parent
                                spacing: 3

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 24
                                    height: 24
                                    radius: width / 2
                                    color: modelData.color
                                    border.width: 0.5
                                    border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)
                                }

                                Text {
                                    width: parent.width
                                    text: root.paletteLabels[modelData.key] || modelData.key
                                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.72)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 4
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: Theme.buttonSize
                    spacing: Theme.spacing

                    BarButton {
                        label: "shuffle"
                        tooltip: "Choisir un fond d’écran au hasard"
                        onClicked: {
                            Quickshell.execDetached([Theme.wallpaperScript, "random"])
                            root.visible = false
                        }
                    }

                    BarButton {
                        label: "folder_open"
                        tooltip: "Ouvrir le dossier des fonds d’écran"
                        onClicked: {
                            Quickshell.execDetached(["xdg-open", Theme.wallpaperDir])
                            root.visible = false
                        }
                    }
                }
            }
        }
    }
}