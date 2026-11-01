// Used by: 2 file(s)
import QtQuick
import Quickshell
import "../theme"

PopupWindow {
    id: root

    required property Item anchorItem
    property string text: ""
    property string title: ""
    property string icon: ""
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
        anchor.rect.y = pos.y
    }

    visible: shown && (text.length > 0 || rows.length > 0)
    color: "transparent"
    implicitWidth: 264
    implicitHeight: (title.length > 0
        ? tooltipHeader.implicitHeight
            + (rows.length > 0 ? tooltipRows.implicitHeight + 8
                : text.length > 0 ? tooltipText.implicitHeight + 8 : 0)
        : rows.length > 0 ? tooltipRows.implicitHeight : tooltipText.implicitHeight) + 20

    Rectangle {
        anchors.fill: parent
        color: Theme.componentBackground
        radius: Theme.cornerRadius
        border.color: Theme.componentBorder
        border.width: 1
    }

    Column {
        anchors.centerIn: parent
        spacing: 8

        Row {
            id: tooltipHeader
            spacing: 7
            visible: root.title.length > 0

            Text {
                text: root.icon
                visible: text.length > 0
                color: Theme.accent
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconSize + 2
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.title
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text {
            id: tooltipText
            text: root.text
            width: 240
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            visible: root.rows.length === 0
        }

        Column {
            id: tooltipRows
            width: 240
            spacing: 10
            visible: root.rows.length > 0

            Repeater {
                model: root.rows

                Column {
                    required property var modelData
                    width: tooltipRows.width
                    spacing: 2

                    Row {
                        width: parent.width
                        spacing: 6

                        Text {
                            text: modelData.icon || ""
                            visible: text.length > 0
                            width: visible ? 18 : 0
                            color: Theme.accent
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.iconSize
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            width: parent.width - (modelData.icon ? 24 : 0)
                            text: `${modelData.label}:`
                            color: Theme.text
                            opacity: 0.75
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }
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
