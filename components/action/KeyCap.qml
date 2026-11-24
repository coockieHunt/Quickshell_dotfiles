import QtQuick
import "../../theme"

Rectangle {
    id: root

    required property string keyText
    property color accentColor: Theme.accent

    implicitWidth: Math.max(26, label.implicitWidth + 14)
    width: implicitWidth
    height: 26
    radius: 6
    color: Theme.componentSurface
    border.width: 1
    border.color: Theme.componentBorder

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 4
            rightMargin: 4
        }
        height: 2
        radius: 1
        color: root.accentColor
        opacity: 0.35
    }

    Text {
        id: label
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        text: root.keyText
        color: root.accentColor
        font.family: Theme.monoFont
        font.pixelSize: Theme.fontSize - 2
        font.weight: Font.DemiBold
    }
}
