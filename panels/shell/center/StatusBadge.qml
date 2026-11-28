import QtQuick
import "../../../components/info"
import "../../../components/tooltip"
import "../../../theme"

Item {
    id: root

    property string icon: ""
    property string label: ""
    property string tooltipTitle: ""
    property string tooltipText: ""
    property color tint: Theme.accent
    signal clicked()

    width: content.implicitWidth + 14
    height: 18
    y: (parent.height - height) / 2

    PopupTooltip {
        anchorItem: root
        icon: root.icon
        title: root.tooltipTitle
        text: root.tooltipText
        shown: mouse.containsMouse
    }

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: parent.height - 4
        color: root.tint
        opacity: mouse.containsMouse ? 0.7 : 0.35

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: parent.height - 4
        color: root.tint
        opacity: mouse.containsMouse ? 0.7 : 0.35

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 3

        Text {
            text: root.icon
            color: root.tint
            font.family: Theme.iconFont
            font.pixelSize: Theme.iconSize - 3
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.label
            color: root.tint
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 4
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
