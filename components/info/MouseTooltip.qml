import QtQuick
import Quickshell
import "../../theme"

PopupWindow {
    id: root

    required property Item anchorItem
    property bool shown: false
    property var rows: []

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
        anchor.rect.y = pos.y + Theme.dropdownGap
    }

    visible: shown && rows.length > 0
    color: "transparent"
    implicitWidth: 264
    implicitHeight: tooltipRows.implicitHeight + 20

    Rectangle {
        anchors.fill: parent
        color: Theme.componentBackground
        radius: Theme.cornerRadius
        border.color: Theme.componentBorder
        border.width: 1
    }

    Column {
        id: tooltipRows
        anchors.centerIn: parent
        width: 240
        spacing: 8

        Repeater {
            model: root.rows

            Row {
                required property var modelData
                width: tooltipRows.width
                spacing: 8

                MouseIcon {
                    highlight: modelData.button
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    width: parent.width - 24 - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        width: parent.width
                        text: modelData.label
                        color: Theme.text
                        opacity: 0.75
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    Text {
                        width: parent.width
                        text: modelData.value
                        color: Theme.text
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }
}