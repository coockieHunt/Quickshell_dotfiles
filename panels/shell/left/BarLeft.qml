import QtQuick
import Quickshell
import "../../../components"
import "../../../components/action"
import "../../../theme"
import "../../../components/info"
import "services"

BarBlock {
    id: root

    required property var hostBar
    required property string screenName

    contentWidth: leftContent.implicitWidth

    WorkspaceService {
        id: workspaceService
        screenName: root.screenName
    }

    Row {
        id: leftContent
        anchors.centerIn: parent
        spacing: Theme.spacing

        Repeater {
            model: workspaceService.workspaces

            WorkspaceIndicator {
                required property var modelData
                workspace: modelData
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
            id: wallpaperButton
            label: "wallpaper"

            onClicked: root.hostBar.wallpaperPicker.toggle()
            onRightClicked: Quickshell.execDetached([
                Theme.wallpaperScript, "--directory", Theme.wallpaperDir, "random"
            ])
            onMiddleClicked: Quickshell.execDetached([
                Theme.wallpaperScript, "--directory", Theme.wallpaperDir, "delete-current"
            ])
        }

        MouseTooltip {
            anchorItem: wallpaperButton
            shown: wallpaperButton.hovered
            rows: [
                { label: "Clic gauche", value: "Ouvrir le sélecteur", button: "left" },
                { label: "Clic droit", value: "Fond aléatoire", button: "right" },
                { label: "Clic molette", value: "Supprimer le fond actuel", button: "middle" }
            ]
        }

        BarButton {
            label: "top_panel_close"
            onClicked: root.hostBar.hideRequested()
        }
    }
}
