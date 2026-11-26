import QtQuick
import "../../../theme"

Item {
    id: root

    required property var workspace

    readonly property bool active: root.workspace.focused
    readonly property bool occupied: root.workspace.occupied !== undefined
        ? root.workspace.occupied : false

    implicitWidth: active ? Theme.workspaceSize * 1.4 : 14
    implicitHeight: Theme.workspaceSize
    width: implicitWidth
    height: implicitHeight

    Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width
        height: Theme.workspaceSize * 0.8
        radius: height / 2
        color: root.active ? Theme.accent : "transparent"

        Behavior on color { ColorAnimation { duration: 140 } }
    }

    Rectangle {
        anchors.centerIn: parent
        width: root.occupied ? 6 : 4
        height: width
        radius: width / 2
        visible: !root.active && !mouse.containsMouse
        color: Theme.text
        opacity: root.occupied ? 0.85 : 0.4
    }

    Text {
        anchors.centerIn: parent
        text: root.workspace.id
        visible: root.active || mouse.containsMouse
        color: root.active ? Theme.textOnAccent : Theme.accent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 1
        font.weight: root.active ? Font.DemiBold : Font.Normal
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.workspace.activate()
    }
}
