// Used by: 1 file(s)
import QtQuick
import "../theme"

Rectangle {
    id: root
    required property string label
    required property string icon
    required property bool active
    required property bool known
    property string detail: ""
    signal clicked()

    implicitWidth: 72
    implicitHeight: 72
    radius: Theme.cornerRadius
    color: !known ? Theme.componentSurface : active ? Theme.accent : Theme.componentSurface
    opacity: known ? 1 : 0.6

    Column {
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            color: root.active ? Theme.textOnAccent : Theme.text
            font.family: Theme.iconFont
            font.pixelSize: Theme.iconSize
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.width - 8
            text: root.known
                ? root.detail !== "" ? root.detail : root.label
                : "Chargement…"
            color: root.active ? Theme.textOnAccent : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: root.detail !== "" ? Theme.fontSize - 3 : Theme.fontSize - 2
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.width - 8
            visible: root.detail !== ""
            text: root.label
            color: root.active ? Theme.textOnAccent : Theme.text
            opacity: 0.75
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 4
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.known
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
