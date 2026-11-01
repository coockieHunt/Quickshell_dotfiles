// Used by: 1 file(s)
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../components"
import "../theme"

PanelWindow {
    id: root
    property var targetScreen: Quickshell.screens[0]
    property string pendingAction: ""

    screen: targetScreen
    visible: false
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-power-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    IpcHandler {
        target: "power"
        function toggle(): void {
            if (root.visible) root.closeMenu()
            else root.openOn(root.targetScreen)
        }
    }

    function openOn(screen) {
        targetScreen = screen
        pendingAction = ""
        visible = true
        focusItem.forceActiveFocus()
    }

    function closeMenu() {
        pendingAction = ""
        visible = false
    }

    function requestConfirmation(action) {
        pendingAction = action
    }

    function confirmAction() {
        if (pendingAction === "")
            return

        const action = pendingAction
        pendingAction = ""
        runAction(action)
    }

    function actionLabel(action) {
        if (action === "shutdown")
            return "Éteindre l’ordinateur"
        if (action === "logout")
            return "Fermer la session"
        if (action === "lock")
            return "Verrouiller la session"
        if (action === "reboot")
            return "Redémarrer l’ordinateur"
        return ""
    }

    function runAction(action) {
        console.info("Power menu action:", action)

        if (action === "shutdown")
            Quickshell.execDetached(["systemctl", "poweroff"])
        else if (action === "logout")
            Quickshell.execDetached(["bash", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"])
        else if (action === "lock")
            Quickshell.execDetached(["bash", "-c", "exec \"$HOME/.config/quickshell/scripts/lock-safe.sh\""])
        else if (action === "reboot")
            Quickshell.execDetached(["systemctl", "reboot"])
        else
            return

        visible = false
    }

    Item {
        id: focusItem
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: {
            if (root.pendingAction !== "")
                root.pendingAction = ""
            else
                root.closeMenu()
        }

        ModalBackdrop {
            anchors.fill: parent
            tint: "#99000000"
            onDismissed: root.closeMenu()
        }

        Rectangle {
            anchors.centerIn: parent
            z: 1
            width: 380
            height: content.implicitHeight + Theme.margin * 2
            radius: Theme.cornerRadius
            color: Theme.componentBackground
            border.color: Theme.componentBorder
            border.width: 1

            MouseArea {
                anchors.fill: parent
            }

            Column {
                id: content
                anchors.fill: parent
                anchors.margins: Theme.margin
                spacing: Theme.spacing

                Text {
                    text: "Alimentation et session"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 3
                }

                Grid {
                    width: parent.width
                    columns: 2
                    spacing: Theme.spacing

                    Repeater {
                        model: [
                            { label: "Éteindre", icon: "power_settings_new", action: "shutdown", color: "#fb4934" },
                            { label: "Fermer la session", icon: "logout", action: "logout", color: "#fe8019" },
                            { label: "Verrouiller", icon: "lock", action: "lock", color: "#83a598" },
                            { label: "Redémarrer", icon: "restart_alt", action: "reboot", color: "#8ec07c" }
                        ]

                        Rectangle {
                            required property var modelData
                            readonly property color actionColor: Qt.color(modelData.color)
                            width: (parent.width - Theme.spacing) / 2
                            height: 64
                            radius: Theme.cornerRadius
                            color: Qt.rgba(actionColor.r, actionColor.g, actionColor.b, mouse.containsMouse ? 0.24 : 0.12)

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                spacing: 10

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.icon
                                    color: actionColor
                                    font.family: Theme.iconFont
                                    font.pixelSize: Theme.iconSize
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                }
                            }

                            MouseArea {
                                id: mouse
                                anchors.fill: parent
                                z: 2
                                hoverEnabled: true
                                onClicked: root.requestConfirmation(modelData.action)
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 32
                    radius: Theme.cornerRadius
                    color: cancelMouse.containsMouse ? Theme.buttonHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Annuler"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.closeMenu()
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            z: 2
            visible: root.pendingAction !== ""
            color: "#66000000"

            MouseArea {
                anchors.fill: parent
            }
        }

        Rectangle {
            anchors.centerIn: parent
            z: 3
            visible: root.pendingAction !== ""
            width: Math.min(parent.width - 32, 360)
            height: confirmationContent.implicitHeight + Theme.margin * 2
            radius: Theme.cornerRadius
            color: Theme.componentBackground
            border.color: Theme.componentBorder
            border.width: 2

            Column {
                id: confirmationContent
                anchors.fill: parent
                anchors.margins: Theme.margin
                spacing: Theme.spacing

                Text {
                    width: parent.width
                    text: "Confirmer l’action"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 3
                    wrapMode: Text.WordWrap
                }

                Text {
                    width: parent.width
                    text: `${root.actionLabel(root.pendingAction)} ?`
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    wrapMode: Text.WordWrap
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacing

                    Rectangle {
                        width: (parent.width - Theme.spacing) / 2
                        height: 36
                        radius: Theme.cornerRadius
                        color: cancelConfirmationMouse.containsMouse ? Theme.buttonHover : Theme.surface

                        Text {
                            anchors.centerIn: parent
                            text: "Annuler"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        MouseArea {
                            id: cancelConfirmationMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.pendingAction = ""
                        }
                    }

                    Rectangle {
                        width: (parent.width - Theme.spacing) / 2
                        height: 36
                        radius: Theme.cornerRadius
                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, confirmMouse.containsMouse ? 0.8 : 1)

                        Text {
                            anchors.centerIn: parent
                            text: "Confirmer"
                            color: Theme.textOnAccent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        MouseArea {
                            id: confirmMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.confirmAction()
                        }
                    }
                }
            }
        }
    }
}
