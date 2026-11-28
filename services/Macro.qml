import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../components"
import "../components/action"
import "../theme"

Scope {
    id: root
    property bool panelOpen: false
    property var keybindings: []
    property string keybindingContents: ""
    property bool keybindingsLoaded: false

    readonly property int keysColumnWidth: 210

    readonly property int macroCount: {
        let count = 0
        for (let i = 0; i < keybindings.length; i++) {
            if (keybindings[i].type === "binding")
                count++
        }
        return count
    }

    function openPanel() {
        panelOpen = true
    }

    function updateKeybindings(contents) {
        keybindingContents = contents
        if (keybindingParser.status === Loader.Ready && keybindingParser.item) {
            keybindings = keybindingParser.item.parseKeybindings(contents)
            keybindingsLoaded = true
        }
    }

    Loader {
        id: keybindingParser
        source: Qt.resolvedUrl("KeybindingParser.qml")
        onLoaded: root.updateKeybindings(root.keybindingContents)
    }

    FileView {
        path: Theme.keybindingFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.updateKeybindings(text())
        onLoadFailed: console.warn("Keybindings introuvables :", Theme.keybindingFile)
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
                Qt.callLater(() => focusItem.forceActiveFocus())
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
                id: panel
                anchors.centerIn: parent
                z: 1
                width: Math.min(parent.width - Theme.margin * 2, 680)
                height: Math.min(parent.height - Theme.margin * 2, 600)
                radius: Theme.cornerRadius
                color: Theme.componentBackground
                border.width: 1
                border.color: Theme.componentBorder
                clip: true

                MouseArea { anchors.fill: parent }

                Item {
                    id: header
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: 56

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "keyboard"
                            color: Theme.accent
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.iconSize + 4
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Raccourcis clavier"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 3
                            font.weight: Font.DemiBold
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        width: counterText.implicitWidth + 20
                        height: 26
                        radius: 0
                        color: Qt.rgba(
                            Theme.accent.r,
                            Theme.accent.g,
                            Theme.accent.b,
                            0.15
                        )

                        Text {
                            id: counterText
                            anchors.centerIn: parent
                            text: root.macroCount + (root.macroCount > 1 ? " macros" : " macro")
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            font.weight: Font.DemiBold
                        }
                    }

                    Rectangle {
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                        height: 1
                        color: Theme.componentBorder
                    }
                }

                ListView {
                    id: list
                    anchors {
                        top: header.bottom
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                        topMargin: 8
                        bottomMargin: 12
                        leftMargin: 20
                        rightMargin: 12
                    }
                    clip: true
                    spacing: 2
                    model: root.keybindings
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool isTitle: modelData.type === "title"

                        width: ListView.view.width - 8
                        height: isTitle ? 40 : 38

                        Text {
                            visible: row.isTitle
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 6
                            text: (row.modelData.title ?? "").toUpperCase()
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            font.weight: Font.Bold
                            font.letterSpacing: 1.2
                        }

                        Rectangle {
                            visible: !row.isTitle
                            anchors.fill: parent
                            radius: Theme.cornerRadius
                            color: rowMouse.containsMouse ? Theme.buttonHover : "transparent"

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                            }

                            Row {
                                id: keysRow
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Repeater {
                                    id: keysRepeater
                                    model: row.isTitle ? [] :
                                        (row.modelData.shortcut ?? "")
                                            .split("+")
                                            .map(s => s.trim())
                                            .filter(s => s.length > 0)

                                            delegate: Row {
                                                id: keyItem
                                                required property string modelData
                                                required property int index
                                                spacing: 4

                                                KeyCap {
                                                    keyText: keyItem.modelData
                                                }

                                                Text {
                                                    visible: keyItem.index < keysRepeater.count - 1
                                                    text: "+"
                                                    color: Theme.text
                                                    opacity: 0.35
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: Theme.fontSize - 2
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }

                                }
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 8 + root.keysColumnWidth + 12
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.modelData.description ?? ""
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Text {
                    visible: root.keybindingsLoaded && root.keybindings.length === 0
                    anchors.centerIn: parent
                    text: "Aucun raccourci clavier trouvé."
                    color: Theme.text
                    opacity: 0.6
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }
}
