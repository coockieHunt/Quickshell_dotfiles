// Used by: 1 file(s)
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import "../components"
import "../theme"

Item {
    id: root

    property bool popupOpen: false
    property bool popupControlsHovered: false

    readonly property var player: {
        const list = Mpris.players.values
        return list.find(p => p.isPlaying) ?? list[0] ?? null
    }
    readonly property string fullLabel: player
        ? (player.trackArtist ? player.trackArtist + " – " : "") + player.trackTitle
        : ""

    function formatTime(seconds) {
        const total = Math.max(0, Math.floor(Number(seconds) || 0))
        const minutes = Math.floor(total / 60)
        const remainder = total % 60
        return `${minutes}:${remainder.toString().padStart(2, "0")}`
    }

    onPlayerChanged: {
        if (!player) {
            popupOpen = false
            popupControlsHovered = false
        }
    }

    function updatePopupHover(hovered) {
        if (hovered && player) {
            closeTimer.stop()
            popupOpen = true
        } else {
            closeTimer.restart()
        }
    }

    function launchLimusic() {
        const ids = Hyprland.workspaces.values
            .map(workspace => Number(workspace.id))
            .filter(id => Number.isInteger(id) && id > 0)
        const targetWorkspace = Math.max(0, ...ids) + 1
        Quickshell.execDetached([
            "hyprctl", "dispatch",
            `hl.dsp.exec_cmd("limusic-app", { workspace = "${targetWorkspace}" })`
        ])
    }

    visible: true
    width: Theme.buttonSize
    height: Theme.barHeight

    Rectangle {
        anchors.centerIn: parent
        width: Theme.buttonSize
        height: Theme.buttonSize
        radius: Theme.cornerRadius
        color: iconMouse.containsMouse || !root.player?.isPlaying
            ? Theme.buttonHover : "transparent"

        Text {
            anchors.centerIn: parent
            text: "music_note"
            color: iconMouse.containsMouse || !root.player?.isPlaying
                ? Theme.accent : Theme.text
            font.family: Theme.iconFont
            font.pixelSize: Theme.iconSize
        }

        MouseArea {
            id: iconMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.player?.canTogglePlaying)
                    root.player.togglePlaying()
                else if (!root.player)
                    root.launchLimusic()
            }
            onEntered: {
                closeTimer.stop()
                if (root.player)
                    root.popupOpen = true
            }
            onExited: {
                if (root.player)
                    closeTimer.restart()
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 250
        onTriggered: {
            if (!root.player || (!iconMouse.containsMouse && !popupMouse.containsMouse && !root.popupControlsHovered))
                root.popupOpen = false
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.popupOpen && (root.player?.isPlaying ?? false)
        onTriggered: {
            if (root.player?.positionSupported)
                root.player.positionChanged()
        }
    }

    PopupWindow {
        id: mediaPopup

        anchor.window: root.QsWindow.window
        anchor.adjustment: PopupAdjustment.None
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.onAnchoring: {
            const content = root.QsWindow.contentItem
            const pos = content.mapFromItem(
                root,
                root.width / 2 - mediaPopup.width / 2,
                root.height
            )
            anchor.rect.x = Math.max(4, Math.min(pos.x, content.width - mediaPopup.width - 4))
            anchor.rect.y = pos.y
        }

        visible: root.popupOpen && root.player !== null
        color: "transparent"
        implicitWidth: 340
        implicitHeight: 136

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            clip: true

            Image {
                id: popupAlbumArt
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: mediaPopup.implicitWidth
                sourceSize.height: mediaPopup.implicitHeight
                asynchronous: true
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: popupAlbumArt
                blurEnabled: true
                blur: 0.8
                blurMax: 24
                autoPaddingEnabled: false
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(Theme.componentBackground.r, Theme.componentBackground.g, Theme.componentBackground.b, 0.72)
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: Theme.componentBorder
                border.width: 1
            }
        }

        MouseArea {
            id: popupMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: closeTimer.stop()
            onExited: closeTimer.restart()
        }

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 4

            Row {
                spacing: 12

                Rectangle {
                    width: 76
                    height: 76
                    radius: Theme.cornerRadius
                    color: Theme.componentSurface
                    clip: true

                    Image {
                        id: albumArt
                        anchors.fill: parent
                        source: root.player?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "music_note"
                        color: Theme.text
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.iconSize + 12
                        visible: albumArt.status !== Image.Ready
                    }
                }

                Column {
                    width: 222
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        width: parent.width
                        text: root.fullLabel
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        elide: Text.ElideRight
                    }

                    Row {
                        height: 36
                        spacing: Theme.spacing

                        BarButton {
                            anchors.verticalCenter: parent.verticalCenter
                            iconSize: Theme.iconSize + 3
                            label: "skip_previous"
                            tooltip: "Précédent"
                            enabled: root.player?.canGoPrevious ?? false
                            opacity: enabled ? 1 : 0.4
                            onHoveredChanged: {
                                root.popupControlsHovered = hovered
                                root.updatePopupHover(hovered)
                            }
                            onClicked: root.player.previous()
                        }

                        BarButton {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 36
                            height: parent.height
                            label: root.player?.isPlaying ? "pause" : "play_arrow"
                            tooltip: root.player?.isPlaying ? "Pause" : "Lecture"
                            idleColor: "transparent"
                            hoverColor: "transparent"
                            iconColor: Theme.accent
                            hoverIconColor: Theme.accent
                            iconSize: Theme.iconSize + 8
                            enabled: root.player?.canTogglePlaying ?? false
                            onHoveredChanged: {
                                root.popupControlsHovered = hovered
                                root.updatePopupHover(hovered)
                            }
                            onClicked: root.player.togglePlaying()
                        }

                        BarButton {
                            anchors.verticalCenter: parent.verticalCenter
                            iconSize: Theme.iconSize + 3
                            label: "skip_next"
                            tooltip: "Suivant"
                            enabled: root.player?.canGoNext ?? false
                            opacity: enabled ? 1 : 0.4
                            onHoveredChanged: {
                                root.popupControlsHovered = hovered
                                root.updatePopupHover(hovered)
                            }
                            onClicked: root.player.next()
                        }
                    }
                }
            }

            Row {
                width: parent.width

                Slider {
                    id: progressSlider
                    width: parent.width
                    height: 18
                    from: 0
                    to: root.player?.length ?? 0
                    value: root.player?.position ?? 0
                    enabled: (root.player?.canSeek ?? false) && (root.player?.lengthSupported ?? false)
                    padding: 0
                    onHoveredChanged: {
                        root.popupControlsHovered = hovered
                        root.updatePopupHover(hovered)
                    }
                    onMoved: {
                        if (root.player?.canSeek)
                            root.player.seek(value - root.player.position)
                    }

                    background: Rectangle {
                        x: progressSlider.leftPadding
                        y: progressSlider.topPadding
                            + (progressSlider.availableHeight - height) / 2
                        width: progressSlider.availableWidth
                        height: 4
                        radius: Theme.cornerRadius
                        color: Theme.componentSurface

                        Rectangle {
                            width: progressSlider.visualPosition * parent.width
                            height: parent.height
                            radius: Theme.cornerRadius
                            color: Theme.accent
                        }
                    }

                    handle: Rectangle {
                        x: progressSlider.leftPadding
                            + progressSlider.visualPosition
                                * (progressSlider.availableWidth - width)
                        y: progressSlider.topPadding
                            + (progressSlider.availableHeight - height) / 2
                        width: 10
                        height: 10
                        radius: Theme.cornerRadius
                        color: Theme.accent
                        border.width: 2
                        border.color: Theme.componentBackground
                        opacity: progressSlider.enabled ? 1 : 0
                    }

                    Binding {
                        target: progressSlider
                        property: "value"
                        value: root.player?.position ?? 0
                        when: !progressSlider.pressed
                    }
                }
            }

            Row {
                width: parent.width
                height: 14

                Text {
                    width: 40
                    text: root.formatTime(root.player?.position ?? 0)
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 3
                    verticalAlignment: Text.AlignVCenter
                }

                Item { width: parent.width - 80; height: 1 }

                Text {
                    width: 40
                    text: root.formatTime(root.player?.length ?? 0)
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 3
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
