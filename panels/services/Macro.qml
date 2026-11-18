import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../../components"
import "../../theme"

Scope {
    id: root
    property bool panelOpen: false
    property var keybindings: []

    function openPanel() {
        panelOpen = true
    }

    property string keybindingContents: ""

    function updateKeybindings(contents) {
        keybindingContents = contents
        if (keybindingParser.status === Loader.Ready)
            keybindings = keybindingParser.item.parseKeybindings(contents)
    }

    Loader {
        id: keybindingParser
        source: Qt.resolvedUrl("../../scripts/KeybindingParser.qml")
        onLoaded: root.updateKeybindings(root.keybindingContents)
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/hypr/keybinding.lua"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.updateKeybindings(text())
    }

    PanelWindow {
        visible: root.panelOpen
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-macros"
        WlrLayershell.keyboardFocus: root.panelOpen
            ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onVisibleChanged: {
            if (visible)
                focusItem.forceActiveFocus()
        }

        Item {
            id: focusItem
            anchors.fill: parent
            focus: root.panelOpen
            Keys.onEscapePressed: root.panelOpen = false

            ModalBackdrop {
                anchors.fill: parent
                tint: "#99000000"
                onDismissed: root.panelOpen = false
            }

            Rectangle {
                anchors.centerIn: parent
                z: 1
                width: Math.min(parent.width - Theme.margin * 2, 620)
                height: Math.min(parent.height - Theme.margin * 2, 560)
                radius: Theme.cornerRadius
                color: Theme.componentBackground
                border.width: 1
                border.color: Theme.componentBorder

                MouseArea {
                    anchors.fill: parent
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: Theme.margin
                    spacing: Theme.spacing

                    Item {
                        width: parent.width
                        height: 28

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Raccourcis clavier"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 2
                            font.weight: Font.DemiBold
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.buttonHover
                    }

                    Flickable {
                        width: parent.width
                        height: parent.height - 28 - Theme.spacing - 1
                        contentHeight: bindingsColumn.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: bindingsColumn
                            width: parent.width
                            spacing: Theme.spacing / 2

                            Repeater {
                                model: root.keybindings

                                delegate: Item {
                                    required property var modelData
                                    width: bindingsColumn.width
                                    height: modelData.type === "title"
                                        ? titleLabel.implicitHeight + Theme.spacing / 2
                                        : bindingCard.height

                                    Text {
                                        id: titleLabel
                                        visible: modelData.type === "title"
                                        width: parent.width
                                        text: modelData.title
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize + 1
                                        font.weight: Font.DemiBold
                                    }

                                    Rectangle {
                                        id: bindingCard
                                        visible: modelData.type === "binding"
                                        width: parent.width
                                        height: Math.max(38, bindingRow.implicitHeight + Theme.spacing)
                                        radius: Theme.cornerRadius
                                        color: Theme.componentSurface

                                        Row {
                                            id: bindingRow
                                            anchors {
                                                fill: parent
                                                margins: Theme.spacing / 2
                                            }
                                            spacing: Theme.spacing

                                            Item {
                                                id: shortcutCell
                                                width: Math.max(72, shortcutLabel.implicitWidth + Theme.spacing * 2)
                                                height: descriptionLabel.implicitHeight

                                                Rectangle {
                                                    id: shortcutKeyCap
                                                    anchors.centerIn: parent
                                                    width: shortcutCell.width
                                                    height: Math.max(28, shortcutLabel.implicitHeight + Theme.spacing)
                                                    radius: Theme.cornerRadius
                                                    color: Qt.rgba(
                                                        Theme.accent.r,
                                                        Theme.accent.g,
                                                        Theme.accent.b,
                                                        0.16
                                                    )

                                                    Text {
                                                        id: shortcutLabel
                                                        anchors.centerIn: parent
                                                        text: modelData.shortcut
                                                        color: Theme.accent
                                                        font.family: "monospace"
                                                        font.pixelSize: Theme.fontSize - 1
                                                        font.weight: Font.DemiBold
                                                        wrapMode: Text.Wrap
                                                    }
                                                }
                                            }

                                            Text {
                                                id: descriptionLabel
                                                width: bindingRow.width - shortcutCell.width - bindingRow.spacing
                                                text: modelData.description
                                                color: Theme.text
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSize
                                                wrapMode: Text.Wrap
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: root.keybindings.length === 0
                                width: parent.width
                                text: "Aucun raccourci clavier trouvé."
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                            }
                        }
                    }
                }
            }
        }
    }
}