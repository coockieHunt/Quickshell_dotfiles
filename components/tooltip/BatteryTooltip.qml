import QtQuick
import Quickshell
import "../../theme"

PopupWindow {
    id: root

    required property Item anchorItem
    property bool shown: false
    property string status: ""
    property string powerFlow: "0 W"
    property real percentage: 0
    property string chargeMode: "Indéterminé"
    property string chargeModeIcon: "battery_unknown"

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
    implicitHeight: 112

    Rectangle {
        anchors.fill: parent
        color: Theme.componentBackground
        radius: Theme.cornerRadius
        border.color: Theme.componentBorder
        border.width: 1
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Row {
            width: parent.width

            Text {
                id: title
                text: "Batterie"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.DemiBold
            }

            Item {
                width: parent.width - title.implicitWidth - statusText.implicitWidth
                height: 1
            }

            Text {
                id: statusText
                text: root.status
                color: Theme.text
                opacity: 0.7
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
            }
        }

        Row {
            width: parent.width
            height: 54

            Column {
                id: powerColumn
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: root.powerFlow
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 5
                    font.weight: Font.DemiBold
                }

                Text {
                    text: `${Math.round(root.percentage * 100)} %`
                    color: Theme.text
                    opacity: 0.7
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                }
            }

            Item {
                width: parent.width - powerColumn.width - modeColumn.width
                height: 1
            }

            Column {
                id: modeColumn
                width: 88
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: root.chargeModeIcon
                    color: Theme.accent
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.iconSize + 4
                    horizontalAlignment: Text.AlignRight
                }

                Text {
                    width: parent.width
                    text: root.chargeMode
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }
            }
        }
    }
}
