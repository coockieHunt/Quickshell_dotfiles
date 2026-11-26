import QtQuick
import "../../../theme"

Item {
    id: root

    property string icon: ""
    property string label: ""
    signal clicked()

    width: content.implicitWidth + 10
    height: 20
    y: (parent.height - height) / 2

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 3

        Text {
            text: root.icon
            color: Theme.accent
            font.family: Theme.iconFont
            font.pixelSize: Theme.iconSize - 2
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.label
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 4
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
