import QtQuick
import "../theme"

Rectangle {
    id: root

    property real contentWidth: 0
    property color borderColor: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)
    readonly property color backgroundColor: Qt.rgba(
        Theme.componentBackground.r,
        Theme.componentBackground.g,
        Theme.componentBackground.b,
        0.95
    )

    width: contentWidth + Theme.margin * 2
    height: Theme.barHeight
    bottomLeftRadius: Theme.cornerRadius
    bottomRightRadius: Theme.cornerRadius
    color: backgroundColor
    border.width: 0.5
    border.color: borderColor

    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: root.backgroundColor
    }
}
