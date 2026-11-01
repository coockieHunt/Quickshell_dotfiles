// Used by: 1 file(s)
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../components"
import "../theme"

PanelWindow {
    id: root
    visible: false

    function toggle() { visible = !visible }

    property var results: {
        const q = search.text.toLowerCase()
        return DesktopEntries.applications.values
            .filter(e => e.name.toLowerCase().includes(q))
            .sort((a, b) => a.name.localeCompare(b.name))
    }

    onVisibleChanged: {
        if (visible) {
            search.text = ""
            search.forceActiveFocus()
        }
    }

    implicitWidth: 500
    implicitHeight: 420
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle() }
    }

    ModalBackdrop {
        anchors.fill: parent
        onDismissed: root.visible = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: root.implicitWidth
        height: root.implicitHeight
        radius: Theme.cornerRadius
        color: Qt.rgba(
            Theme.componentBackground.r * 0.97 + Theme.accent.r * 0.03,
            Theme.componentBackground.g * 0.97 + Theme.accent.g * 0.03,
            Theme.componentBackground.b * 0.97 + Theme.accent.b * 0.03,
            Theme.componentBackground.a
        )
        border.color: Theme.componentBorder
        border.width: 1

        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.margin
            spacing: Theme.spacing

            Rectangle {
                width: parent.width
                height: 36
                radius: Theme.cornerRadius
                color: Theme.componentSurface

                TextInput {
                    id: search
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 52
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize

                    Keys.onEscapePressed: root.visible = false
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onReturnPressed: {
                        if (root.results.length > 0) {
                            root.results[list.currentIndex].execute()
                            root.visible = false
                        }
                    }
                    onTextChanged: list.currentIndex = 0
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: search.text.length > 0 ? 30 : 38
                    height: 22
                    radius: Theme.cornerRadius
                    color: Theme.componentSurface

                    Text {
                        anchors.centerIn: parent
                        text: search.text.length > 0 ? "↵" : "↑ ↓"
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.65)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                    }
                }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 52
                    verticalAlignment: Text.AlignVCenter
                    text: "Rechercher une application..."
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    visible: search.text.length === 0
                    enabled: false
                }
            }

            ListView {
                id: list
                width: parent.width
                height: parent.height - 36 - 18 - Theme.spacing * 2
                clip: true
                model: root.results
                currentIndex: 0

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    property bool selected: ListView.isCurrentItem
                    width: list.width
                    height: 36
                    radius: Theme.cornerRadius
                    color: selected
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
                        : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        spacing: 10

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22
                            height: 22
                            source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: list.currentIndex = index
                        onClicked: {
                            list.currentIndex = index
                            modelData.execute()
                            root.visible = false
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: 18
                spacing: Theme.spacing

                Text {
                    width: parent.width - countLabel.implicitWidth - parent.spacing
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: root.results.length > 0 && list.currentIndex >= 0 && list.currentIndex < root.results.length
                        ? root.results[list.currentIndex].id
                        : ""
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                }

                Text {
                    id: countLabel
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: root.results.length + (root.results.length === 1 ? " application" : " applications")
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                }
            }
        }
    }
}
