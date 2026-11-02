import QtQuick
import Quickshell
import "../../theme"

PopupWindow {
    id: root

    required property Item anchorItem
    property bool shown: false
    property string title: ""
    property string icon: ""
    property string status: ""
    property string detail: ""

    anchor.window: anchorItem.QsWindow.window
    anchor.adjustment: PopupAdjustment.None
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.onAnchoring: {
        const content = anchorItem.QsWindow.contentItem
        const pos = content.mapFromItem(
            anchorItem,
            anchorItem.width / 2 - root.width / 2,
            anchorItem.height + 4
        )
        const maxX = Math.max(4, content.width - root.width - 4)
        anchor.rect.x = Math.max(4, Math.min(pos.x, maxX))
        anchor.rect.y = pos.y
    }

    visible: shown
    color: "transparent"
    implicitWidth: 220
    implicitHeight: 88

    Rectangle {
        anchors.fill: parent
        color: Theme.componentBackground
        radius: Theme.cornerRadius
        border.color: Theme.componentBorder
        border.width: 1
    }

    Row {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Column {
            width: parent.width - statusIcon.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                text: root.title
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.DemiBold
            }

            Text {
                width: parent.width
                text: root.detail
                visible: root.detail.length > 0
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                text: root.status
                color: Theme.text
                opacity: 0.7
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 3
            }
        }

        Text {
            id: statusIcon
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: Theme.accent
            font.family: Theme.iconFont
            font.pixelSize: Theme.iconSize + 6
        }
    }
}
