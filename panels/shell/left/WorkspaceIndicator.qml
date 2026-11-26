import QtQuick
import "../../../theme"

Rectangle {
    id: root

    required property var workspace

    width: root.workspace.focused ? Theme.workspaceSize * 1.5 : Theme.workspaceSize
    height: Theme.workspaceSize
    radius: Theme.cornerRadius
    color: root.workspace.focused ? Theme.accent : "transparent"

    Behavior on color {
        ColorAnimation { duration: 140 }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 6
        height: 6
        radius: Theme.cornerRadius
        visible: !root.workspace.focused && !mouse.containsMouse
        color: Theme.text
        opacity: mouse.containsMouse ? 1 : 0.6
    }

    Text {
        anchors.centerIn: parent
        text: root.workspace.id
        visible: root.workspace.focused || mouse.containsMouse
        color: root.workspace.focused
            ? Theme.textOnAccent
            : mouse.containsMouse ? Theme.accent : Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 1
        font.weight: root.workspace.focused ? Font.DemiBold : Font.Normal
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.workspace.activate()
    }
}
