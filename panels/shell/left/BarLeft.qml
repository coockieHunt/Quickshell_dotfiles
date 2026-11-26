import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../../components"
import "../../../components/action"
import "../../../theme"

BarBlock {
    id: root

    required property var hostBar
    required property string screenName

    contentWidth: leftContent.implicitWidth

    Row {
        id: leftContent
        anchors.centerIn: parent
        spacing: Theme.spacing

        Repeater {
            model: Hyprland.workspaces.values
                .filter(w => w.id > 0 && w.monitor?.name === root.screenName)
                .sort((x, y) => x.id - y.id)

            Rectangle {
                required property var modelData
                width: modelData.focused ? Theme.workspaceSize * 1.5 : Theme.workspaceSize
                height: Theme.workspaceSize
                radius: Theme.cornerRadius
                color: modelData.focused ? Theme.accent : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 140 }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 6
                    height: 6
                    radius: Theme.cornerRadius
                    visible: !modelData.focused && !workspaceMouse.containsMouse
                    color: Theme.text
                    opacity: workspaceMouse.containsMouse ? 1 : 0.6
                }

                Text {
                    anchors.centerIn: parent
                    text: modelData.id
                    visible: modelData.focused || workspaceMouse.containsMouse
                    color: modelData.focused
                        ? Theme.textOnAccent
                        : workspaceMouse.containsMouse ? Theme.accent : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    font.weight: modelData.focused ? Font.DemiBold : Font.Normal
                }

                MouseArea {
                    id: workspaceMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.activate()
                }
            }
        }

        BarButton {
            label: Theme.archLogo
            iconFont: Theme.brandFont
            iconColor: Theme.accent
            iconSize: Theme.iconSize - 2
            onClicked: root.hostBar.launcherControl.toggle()
        }
        BarButton {
            label: "wallpaper"
            tooltip: "Clic gauche : ouvrir le sélecteur\nClic droit : fond aléatoire\nClic molette : supprimer l’actuel"
            onClicked: root.hostBar.wallpaperPicker.toggle()
            onRightClicked: Quickshell.execDetached([
                Theme.wallpaperScript, "--directory", Theme.wallpaperDir, "random"
            ])
            onMiddleClicked: Quickshell.execDetached([
                Theme.wallpaperScript, "--directory", Theme.wallpaperDir, "delete-current"
            ])
        }
        BarButton {
            label: "top_panel_close"
            onClicked: root.hostBar.hideRequested()
        }
    }
}
