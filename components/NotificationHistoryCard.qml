// Used by: 1 file(s)
import QtQuick
import "../theme"

Rectangle {
    id: root

    required property var notification
    required property int notificationIndex
    signal dismissed(int index)

    height: historyContent.implicitHeight + Theme.spacing * 2
    radius: Theme.cornerRadius
    color: Theme.componentSurface

    Column {
        id: historyContent

        spacing: 3

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Theme.spacing
        }

        Item {
            width: parent.width
            height: 22

            Text {
                anchors.left: parent.left
                anchors.right: timeText.left
                anchors.rightMargin: Theme.spacing / 2
                anchors.verticalCenter: parent.verticalCenter
                text: root.notification.appName
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 3
                elide: Text.ElideRight
            }

            Text {
                id: timeText

                anchors.right: deleteNotificationButton.left
                anchors.rightMargin: Theme.spacing / 2
                anchors.verticalCenter: parent.verticalCenter
                text: root.notification.receivedAt
                color: Theme.text
                opacity: 0.65
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 3
            }

            BarButton {
                id: deleteNotificationButton

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                label: "close"
                tooltip: "Supprimer cette notification"
                iconSize: Theme.iconSize - 2
                onClicked: root.dismissed(root.notificationIndex)
            }
        }

        Text {
            width: parent.width
            text: root.notification.summary
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
        }

        Text {
            width: parent.width
            visible: text.length > 0
            text: root.notification.body
            color: Theme.text
            opacity: 0.8
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
    }
}
