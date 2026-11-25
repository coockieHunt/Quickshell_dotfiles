import Quickshell
import QtQuick
import "../../components/action"
import "../../components/notification"
import "../../theme"

PopupWindow {
    id: popup

    required property Item anchorItem
    required property var notificationController
    property bool open: false
    property bool barVisible: true

    property bool muteOpen: false

    signal closeRequested()

    anchor.window: anchorItem.QsWindow.window
    anchor.adjustment: PopupAdjustment.None
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.onAnchoring: {
        const content = anchorItem.QsWindow.contentItem
        const pos = content.mapFromItem(
            anchorItem,
            anchorItem.width / 2 - popup.width / 2,
            anchorItem.height
        )
        anchor.rect.x = Math.max(4, Math.min(pos.x, content.width - popup.width - 4))
        anchor.rect.y = content.height + Theme.dropdownGap
    }

    visible: open && barVisible
    grabFocus: true
    implicitWidth: 360
    implicitHeight: content.implicitHeight + 16
    color: "transparent"
    onVisibleChanged: {
        if (!visible) {
            muteOpen = false
            closeRequested()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Theme.componentBackground
        border.width: 1
        border.color: Theme.componentBorder

        Column {
            id: content
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 8
            }
            spacing: Theme.spacing

            Item {
                width: parent.width
                height: 28

                Text {
                    anchors.left: parent.left
                    anchors.right: actions.left
                    anchors.rightMargin: Theme.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Notifications récentes"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 1
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Row {
                    id: actions
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacing / 2

                    BarButton {
                        width: 28
                        height: 28
                        label: "delete_sweep"
                        tooltip: "Effacer l’historique"
                        onClicked: popup.notificationController.history = []
                    }

                    Rectangle {
                        id: muteButton
                        width: popup.notificationController.notificationsMuted ? 86 : 28
                        height: 28
                        radius: Theme.cornerRadius
                        color: muteMouse.containsMouse
                            ? Theme.buttonHover
                            : (popup.notificationController.notificationsMuted || popup.muteOpen)
                                ? Theme.surface : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            text: popup.notificationController.notificationsMuted
                                ? "notifications_paused" : "notifications_active"
                            color: popup.notificationController.notificationsMuted ? Theme.danger : Theme.text
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.iconSize
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            visible: popup.notificationController.notificationsMuted
                            text: popup.notificationController.muteTimeRemaining
                            color: Theme.danger
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 4
                        }

                        MouseArea {
                            id: muteMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (popup.notificationController.notificationsMuted)
                                    popup.notificationController.cancelNotificationMute()
                                else
                                    popup.muteOpen = !popup.muteOpen
                            }
                        }
                    }
                }
            }

            Column {
                visible: popup.muteOpen
                width: parent.width
                spacing: 2

                Repeater {
                    model: [
                        { title: "15 minutes", detail: "Petite pause", duration: 900000 },
                        { title: "1 heure", detail: "Pour rester concentré", duration: 3600000 },
                        { title: "8 heures", detail: "Jusqu’à la fin de la journée", duration: 28800000 },
                        { title: "Sans limite", detail: "Jusqu’à réactivation", duration: -1 }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 46
                        radius: Theme.cornerRadius
                        color: durationMouse.containsMouse ? Theme.buttonHover : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 9
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "notifications_paused"
                                color: Theme.accent
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.iconSize
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: modelData.title
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 1
                                }

                                Text {
                                    text: modelData.detail
                                    color: Theme.text
                                    opacity: 0.65
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 3
                                }
                            }
                        }

                        MouseArea {
                            id: durationMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popup.muteOpen = false
                                popup.notificationController.setNotificationMute(modelData.duration)
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: popup.notificationController.muteMessage !== ""
                width: parent.width
                height: visible ? 28 : 0
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.14)

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    text: popup.notificationController.muteMessage
                    color: Theme.danger
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    verticalAlignment: Text.AlignVCenter
                }
            }

            ListView {
                id: historyList
                width: parent.width
                height: Math.max(60, Math.min(contentHeight, 380))
                clip: true
                spacing: Theme.spacing
                model: popup.notificationController.history

                Text {
                    anchors.centerIn: parent
                    visible: popup.notificationController.history.length === 0
                    text: "Aucune notification récente"
                    color: Theme.text
                    opacity: 0.65
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                delegate: NotificationHistoryCard {
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    notification: modelData
                    notificationIndex: index
                    onDismissed: popup.notificationController.removeHistoryNotification(notificationIndex)
                }
            }
        }
    }
}
