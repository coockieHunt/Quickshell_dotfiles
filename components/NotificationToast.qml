// Used by: 1 file(s)
import Quickshell.Services.Notifications
import QtQuick
import "../theme"

Rectangle {
    id: root

    required property var notification
    readonly property bool critical: notification.urgency === NotificationUrgency.Critical

    height: content.implicitHeight + Theme.margin * 2
    radius: Theme.cornerRadius
    color: Theme.componentBackground
    border.width: 2
    border.color: critical ? Theme.danger : Theme.componentBorder

    Timer {
        interval: 5000
        running: !root.critical
        onTriggered: root.notification.dismiss()
    }

    Column {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Theme.margin
        }
        spacing: 4

        Text {
            width: parent.width
            text: root.notification.appName
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 3
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.notification.summary
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: root.notification.body
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            wrapMode: Text.Wrap
            maximumLineCount: 4
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.notification.dismiss()
    }
}
