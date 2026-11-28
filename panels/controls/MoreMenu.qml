import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../components"
import "../../components/action"
import "../../theme"
import "../../services"
import "../../services"
import "../shell"

Item {
    id: root

    width: moreButton.width
    height: moreButton.height

    property string expandedMenu: ""
    property bool confirmReload: false

    required property var hostBar

    Macro {
        id: macroLocal
    }

    Process {
        id: openConfigWithDefaultApp
        command: ["xdg-open", Theme.configFilePath]
        onExited: (exitCode) => {
            if (exitCode !== 0)
                openConfigWithEditor.running = true
        }
    }

    Process {
        id: openConfigWithEditor
        command: [Theme.textEditorApplication, Theme.configFilePath]
    }

    PanelWindow {
        id: confirmWindow

        visible: root.confirmReload
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.confirmReload
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        ConfirmDialog {
            anchors.fill: parent

            opened: root.confirmReload
            title: "Recharger Quickshell ?"
            message: "L’interface va se recharger. Les panneaux ouverts seront fermés."
            confirmText: "Recharger"

            onConfirmed: {
                root.confirmReload = false
                Quickshell.reload(true)
            }
            onCancelled: root.confirmReload = false
        }
    }

    function runAction(action) {
        switch (action) {
        case "launcher":
            hostBar.launcherControl.toggle()
            break
        case "wallpaper":
            hostBar.wallpaperPicker.toggle()
            break
        case "wifi":
            hostBar.popup(Theme.wifiApplication)
            break
        case "bluetooth":
            hostBar.popup(Theme.bluetoothApplication)
            break
        case "audio":
            hostBar.popup("pavucontrol")
            break
        case "control":
            hostBar.controller.togglePanel()
            break
        case "macro":
            macroLocal.openPanel()
            break
        case "openSetting":
            openConfigWithDefaultApp.running = true
            break
        case "reload_qs":
            confirmReload = true
            break
        case "lock":
            Quickshell.execDetached(["hyprlock"])
            break
        case "shutdown":
            Quickshell.execDetached(["systemctl", "poweroff"])
            break
        case "full_menu":
            Quickshell.execDetached(["qs", "ipc", "call", "power", "toggle"])
            break
        }

        menuWindow.visible = false
    }

    BarButton {
        id: moreButton

        label: "menu"
        highlighted: menuWindow.visible
        onClicked: menuWindow.visible = !menuWindow.visible
    }

    Connections {
        target: menuWindow

        function onVisibleChanged() {
            if (menuWindow.visible)
                enterAnimation.restart()
            else
                root.expandedMenu = ""
        }
    }

    ParallelAnimation {
        id: enterAnimation

        NumberAnimation {
            target: panel
            property: "opacity"
            from: 0
            to: 1
            duration: 140
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: panel
            property: "y"
            from: -6
            to: 0
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    PopupWindow {
        id: menuWindow

        anchor.window: moreButton.QsWindow.window
        anchor.adjustment: PopupAdjustment.None
        anchor.gravity: Edges.Bottom | Edges.Right

        anchor.onAnchoring: {
            const content = moreButton.QsWindow.contentItem

            const buttonPos = content.mapFromItem(moreButton, 0, 0)

            const wantedX = buttonPos.x
                + (moreButton.width - menuWindow.width) / 2

            anchor.rect.x = Math.max(
                4,
                Math.min(wantedX, content.width - menuWindow.width - 4)
            )

            anchor.rect.y = buttonPos.y + moreButton.height + Theme.dropdownGap
        }

        visible: false
        grabFocus: true
        implicitWidth: 250
        implicitHeight: menuContent.implicitHeight + 20
        color: "transparent"

        Rectangle {
            id: panel

            width: parent.width
            height: parent.height
            radius: Theme.cornerRadius
            color: Theme.componentBackground
            border.width: 1
            border.color: Theme.componentBorder

            Column {
                id: menuContent

                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                Repeater {
                    model: [
                        {
                            title: "Applications",
                            icon: "apps",
                            items: [
                                { label: "Lanceur", action: "launcher" },
                                { label: "Fond d’écran", action: "wallpaper" }
                            ]
                        },
                        {
                            title: "Connectivité",
                            icon: "wifi",
                            items: [
                                { label: "Wi-Fi", action: "wifi" },
                                { label: "Bluetooth", action: "bluetooth" }
                            ]
                        },
                        {
                            title: "Système",
                            icon: "settings",
                            items: [
                                { label: "Audio", action: "audio" },
                                { label: "Centre de contrôle", action: "control" },
                                { label: "Macro", action: "macro" },
                                { label: "Configuration", action: "openSetting" },
                                { label: "Recharger Qs", action: "reload_qs" }
                            ]
                        }
                    ]

                    delegate: Column {
                        id: category

                        required property var modelData
                        readonly property bool isOpen:
                            root.expandedMenu === modelData.title

                        Rectangle {
                            width: menuContent.width
                            height: 40
                            radius: Theme.cornerRadius
                            color: category.isOpen
                                ? Qt.rgba(
                                      Theme.accent.r,
                                      Theme.accent.g,
                                      Theme.accent.b,
                                      0.10
                                  )
                                : categoryMouse.containsMouse
                                    ? Theme.buttonHover
                                    : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }

                            Rectangle {
                                id: iconBox

                                anchors.left: parent.left
                                anchors.leftMargin: 7
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28
                                height: 28
                                radius: Math.min(Theme.cornerRadius, 8)
                                color: Qt.rgba(
                                    Theme.accent.r,
                                    Theme.accent.g,
                                    Theme.accent.b,
                                    category.isOpen ? 0.24 : 0.12
                                )

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: category.modelData.icon
                                    color: Theme.accent
                                    font.family: Theme.iconFont
                                    font.pixelSize: Theme.iconSize - 2
                                }
                            }

                            Text {
                                anchors.left: iconBox.right
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: category.modelData.title
                                color: category.isOpen ? Theme.accent : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.weight: category.isOpen
                                    ? Font.DemiBold
                                    : Font.Normal

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: "expand_more"
                                color: category.isOpen ? Theme.accent : Theme.text
                                opacity: category.isOpen
                                    || categoryMouse.containsMouse ? 1 : 0.6
                                rotation: category.isOpen ? 180 : 0
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.iconSize - 2

                                Behavior on rotation {
                                    NumberAnimation {
                                        duration: 160
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on opacity {
                                    NumberAnimation { duration: 120 }
                                }
                            }

                            MouseArea {
                                id: categoryMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    root.expandedMenu = category.isOpen
                                        ? ""
                                        : category.modelData.title
                                }
                            }
                        }

                        Item {
                            width: menuContent.width
                            height: category.isOpen
                                ? subList.implicitHeight + 6
                                : 0
                            visible: height > 0
                            opacity: category.isOpen ? 1 : 0
                            clip: true

                            Behavior on height {
                                NumberAnimation {
                                    duration: 170
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation { duration: 140 }
                            }

                            Rectangle {
                                x: 20
                                y: 5
                                width: 1
                                height: parent.height - 8
                                color: Qt.rgba(
                                    Theme.accent.r,
                                    Theme.accent.g,
                                    Theme.accent.b,
                                    0.3
                                )
                            }

                            Column {
                                id: subList

                                y: 4
                                width: parent.width
                                spacing: 2

                                Repeater {
                                    model: category.modelData.items

                                    delegate: Rectangle {
                                        id: subItem

                                        required property var modelData

                                        width: subList.width
                                        height: 32
                                        radius: Theme.cornerRadius
                                        color: actionMouse.containsMouse
                                            ? Theme.buttonHover
                                            : "transparent"

                                        Behavior on color {
                                            ColorAnimation { duration: 100 }
                                        }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 38
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: subItem.modelData.label
                                            color: actionMouse.containsMouse
                                                ? Theme.accent
                                                : Theme.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSize

                                            Behavior on color {
                                                ColorAnimation { duration: 100 }
                                            }
                                        }

                                        MouseArea {
                                            id: actionMouse

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.runAction(
                                                subItem.modelData.action
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    width: menuContent.width
                    height: 9

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: 1
                        color: Qt.rgba(
                            Theme.accent.r,
                            Theme.accent.g,
                            Theme.accent.b,
                            0.15
                        )
                    }
                }

                Row {
                    width: menuContent.width
                    spacing: 6

                    Repeater {
                        model: [
                            {
                                icon: "power_settings_new",
                                action: "shutdown",
                                color: "#fb4934"
                            },
                            {
                                icon: "lock",
                                action: "lock",
                                color: "#83a598"
                            },
                            {
                                icon: "more_horiz",
                                action: "full_menu",
                                color: Theme.accent
                            }
                        ]

                        delegate: Rectangle {
                            id: quickButton

                            required property var modelData
                            readonly property color actionColor:
                                Qt.color(modelData.color)

                            width: (menuContent.width - 12) / 3
                            height: 40
                            radius: Theme.cornerRadius
                            color: Qt.rgba(
                                actionColor.r,
                                actionColor.g,
                                actionColor.b,
                                bottomButtonMouse.containsMouse ? 0.24 : 0.10
                            )

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: quickButton.modelData.icon
                                color: quickButton.actionColor
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.iconSize
                            }

                            MouseArea {
                                id: bottomButtonMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.runAction(
                                    quickButton.modelData.action
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
