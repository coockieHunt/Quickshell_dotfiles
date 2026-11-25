import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import "../../components/action"
import "../../theme"

PopupWindow {
    id: popup

    required property Item anchorItem
    property bool open: false
    property bool barVisible: true

    property bool confirming: false
    property string appLabel: ""
    property var appNames: []

    signal closeRequested()

    function askClose(item) {
        appNames = [item.id, item.title, item.tooltipTitle]
            .filter(n => n && n.length > 0)
        appLabel = item.tooltipTitle || item.title || item.id
        confirming = true
    }

    function killApp() {
        console.info("Tray kill: candidats =", appNames.join(" | "))
        killer.command = [
            "bash", "-c",
            'for n in "$@"; do pkill -x -- "$n" && exit 0; pkill -x -- "${n,,}" && exit 0; done; [ ${#1} -ge 4 ] && pkill -f -i -- "$1" && exit 0; exit 1',
            "_"
        ].concat(appNames)
        killer.running = true
    }

    Process {
        id: killer
        stderr: SplitParser {
            onRead: line => console.warn("Tray kill:", line)
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("Tray kill: aucun processus trouvé pour", popup.appNames.join(" | "))
        }
    }

    anchor.window: anchorItem.QsWindow.window
    anchor.adjustment: PopupAdjustment.None
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.onAnchoring: {
        const content = anchorItem.QsWindow.contentItem
        const pos = content.mapFromItem(
            anchorItem,
            anchorItem.width / 2 - popup.width / 2,
            anchorItem.height
        )
        anchor.rect.x = Math.max(4, Math.min(pos.x, content.width - popup.width - 4))
        anchor.rect.y = pos.y + Theme.dropdownGap
    }

    visible: open && barVisible
    grabFocus: true
    implicitWidth: confirming ? 340 : 220
    implicitHeight: confirming ? 220 : Math.max(48, trayContent.implicitHeight + 16)
    color: "transparent"
    onVisibleChanged: {
        if (!visible) {
            confirming = false
            closeRequested()
        }
    }
    onConfirmingChanged: {
        if (visible && anchor.updateAnchor)
            anchor.updateAnchor()
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Theme.componentBackground
        border.width: 1
        border.color: Theme.componentBorder

        Column {
            id: trayContent
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2

            Repeater {
                model: SystemTray.items

                delegate: Rectangle {
                    required property var modelData
                    width: trayContent.width
                    height: 34
                    radius: Theme.cornerRadius
                    color: trayItemMouse.containsMouse ? Theme.buttonHover : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 36
                        spacing: 8

                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            height: 20
                            source: modelData.icon
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 28
                            text: modelData.tooltipTitle || modelData.title || modelData.id
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: trayItemMouse
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (modelData.onlyMenu
                                    || (mouse.button === Qt.RightButton && modelData.hasMenu)) {
                                modelData.display(popup, Math.round(mouse.x), Math.round(mouse.y))
                            } else if (mouse.button === Qt.LeftButton) {
                                modelData.activate()
                                popup.closeRequested()
                            }
                        }
                    }

                    Rectangle {
                        id: closeButton
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        height: 24
                        radius: Theme.cornerRadius
                        z: 10
                        color: closeMouse.containsMouse
                            ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.28)
                            : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "close"
                            color: Theme.danger
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: Theme.iconSize - 2
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popup.askClose(modelData)
                        }
                    }
                }
            }

            Text {
                visible: SystemTray.items.values.length === 0
                width: trayContent.width
                height: 32
                text: "Aucune icône disponible"
                color: Theme.text
                opacity: 0.7
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    ConfirmDialog {
        opened: popup.confirming
        title: "Fermer " + popup.appLabel + " ?"
        message: "L’application sera arrêtée. Les données non enregistrées seront perdues."
        cancelText: "Annuler"
        confirmText: "Fermer"

        onConfirmed: {
            popup.killApp()
            popup.confirming = false
            popup.closeRequested()
        }
        onCancelled: popup.confirming = false
    }
}
