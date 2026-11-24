import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

import "../../components"
import "../../components/action"
import "../../theme"

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
            if (root.visible)
                root.closeMenu()
            else
                root.openOn(root.targetScreen)
        }
    }

    Timer {
        id: focusTimer
        interval: 50
        onTriggered: focusItem.forceActiveFocus()
    }

    onVisibleChanged: {
        if (visible)
            focusTimer.restart()
    }

    function openOn(screen) {
        targetScreen = screen
        pendingAction = ""
        visible = true
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
        if (action === "shutdown") {
            Quickshell.execDetached(["systemctl", "poweroff"])
        } else if (action === "logout") {
            Quickshell.execDetached([
                "bash",
                "-c",
                "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"
            ])
        } else if (action === "lock") {
            Quickshell.execDetached(["hyprlock"])
        } else if (action === "reboot") {
            Quickshell.execDetached(["systemctl", "reboot"])
        } else {
            return
        }

        visible = false
    }

    Shortcut {
        sequence: "S"
        enabled: root.pendingAction === ""
        onActivated: root.requestConfirmation("shutdown")
    }

    Shortcut {
        sequence: "L"
        enabled: root.pendingAction === ""
        onActivated: root.requestConfirmation("logout")
    }

    Shortcut {
        sequence: "V"
        enabled: root.pendingAction === ""
        onActivated: root.requestConfirmation("lock")
    }

    Shortcut {
        sequence: "R"
        enabled: root.pendingAction === ""
        onActivated: root.requestConfirmation("reboot")
    }

    Item {
        id: focusItem
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: event => {
            if (root.pendingAction !== "")
                root.pendingAction = ""
            else
                root.closeMenu()

            event.accepted = true
        }

        Keys.onPressed: event => {
            if (root.pendingAction !== "")
                return

            if (event.key === Qt.Key_S) {
                root.requestConfirmation("shutdown")
            } else if (event.key === Qt.Key_L) {
                root.requestConfirmation("logout")
            } else if (event.key === Qt.Key_V) {
                root.requestConfirmation("lock")
            } else if (event.key === Qt.Key_R) {
                root.requestConfirmation("reboot")
            } else {
                return
            }

            event.accepted = true
        }

        ModalBackdrop {
            anchors.fill: parent
            tint: "#99000000"
            visible: root.pendingAction === ""
            onDismissed: root.closeMenu()
        }

        Rectangle {
            id: powerMenu
            anchors.centerIn: parent
            z: 1
            visible: root.pendingAction === ""

            width: 440
            height: content.implicitHeight + Theme.margin * 2
            radius: Theme.cornerRadius
            color: Theme.componentBackground
            border.color: Theme.componentBorder
            border.width: 1

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
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
                            {
                                label: "Éteindre",
                                icon: "power_settings_new",
                                key: "S",
                                action: "shutdown",
                                color: "#fb4934"
                            },
                            {
                                label: "Fermer la session",
                                icon: "logout",
                                key: "L",
                                action: "logout",
                                color: "#fe8019"
                            },
                            {
                                label: "Verrouiller",
                                icon: "lock",
                                key: "V",
                                action: "lock",
                                color: "#83a598"
                            },
                            {
                                label: "Redémarrer",
                                icon: "restart_alt",
                                key: "R",
                                action: "reboot",
                                color: "#8ec07c"
                            }
                        ]

                        TextButton {
                            required property var modelData

                            width: (parent.width - Theme.spacing) / 2
                            height: 64
                            stretched: true
                            paddingH: Theme.margin * 0.75
                            icon: modelData.icon
                            text: modelData.label
                            keycap: modelData.key
                            highlighted: true
                            tint: 0.12
                            buttonColor: Qt.color(modelData.color)
                            textColor: Theme.text
                            onClicked: root.requestConfirmation(modelData.action)
                        }
                    }
                }

                TextButton {
                    width: parent.width
                    height: 40
                    text: "Annuler"
                    onClicked: root.closeMenu()
                }
            }
        }

        ConfirmDialog {
            anchors.fill: parent
            z: 2

            opened: root.pendingAction !== ""
            title: "Confirmer l’action"
            message: root.actionLabel(root.pendingAction) + " ?"
            cancelText: "Annuler"
            confirmText: "Confirmer"

            onCancelled: root.pendingAction = ""
            onConfirmed: root.confirmAction()
        }
    }
}
