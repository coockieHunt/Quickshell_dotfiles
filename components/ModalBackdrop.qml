// Used by: 4 file(s)
import QtQuick

Item {
    id: root

    signal dismissed()
    property color tint: "transparent"

    Rectangle {
        anchors.fill: parent
        color: root.tint
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }
}
