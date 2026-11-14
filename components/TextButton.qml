import QtQuick
import "../theme"

Rectangle {
    id: root

    property string text: ""
    property bool highlighted: false
    signal clicked()

    implicitWidth: label.implicitWidth + Theme.margin * 3
    implicitHeight: Theme.buttonSize + Theme.spacing
    width: implicitWidth
    height: implicitHeight
    radius: Theme.cornerRadius
    border.width: 1
    border.color: Qt.rgba(
        Theme.componentBorder.r,
        Theme.componentBorder.g,
        Theme.componentBorder.b,
        0.35
    )
    color: highlighted
        ? Theme.accent
        : mouse.containsMouse ? Theme.buttonHover : Theme.componentSurface
    opacity: enabled ? 1 : 0.5

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.highlighted ? Theme.textOnAccent : Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 2
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
