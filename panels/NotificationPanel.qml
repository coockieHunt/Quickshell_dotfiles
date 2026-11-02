// Used by: 1 file(s)
import QtQuick
import QtQuick.Controls
import "../components"
import "../theme"

Item {
    id: root

    required property var controller

    Rectangle {
        visible: controller.panelMode !== "performance"
        width: 360
        radius: Theme.cornerRadius
        color: Theme.componentBackground
        border.width: 1
        border.color: Theme.componentBorder

        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
            margins: 4
        }

        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.margin
            spacing: Theme.spacing

            Row {
                width: parent.width
                height: 28
                spacing: Theme.spacing

                Text {
                    width: parent.width
                    text: "Réglages rapides"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 2
                    font.weight: Font.DemiBold
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Row {
                width: parent.width
                height: 72
                spacing: Theme.spacing

                QuickSetting {
                    width: (parent.width - parent.spacing) / 2
                    label: "Wi-Fi"
                    icon: "wifi"
                    active: controller.wifiEnabled
                    known: controller.wifiStateKnown
                    detail: controller.wifiNetworkName
                    onClicked: controller.toggleWifi()
                }

                QuickSetting {
                    width: (parent.width - parent.spacing) / 2
                    label: "Bluetooth"
                    icon: "bluetooth"
                    active: controller.bluetoothEnabled
                    known: controller.bluetoothStateKnown
                    detail: controller.bluetoothConnectedNames
                    onClicked: controller.toggleBluetooth()
                }
            }

            Row {
                width: parent.width
                height: 72
                spacing: Theme.spacing

                QuickSetting {
                    width: (parent.width - parent.spacing) / 2
                    label: "Son"
                    icon: controller.soundMuted ? "volume_off" : "volume_up"
                    active: controller.soundStateKnown && !controller.soundMuted
                    known: controller.soundStateKnown
                    onClicked: controller.toggleSound()
                }

                QuickSetting {
                    width: (parent.width - parent.spacing) / 2
                    label: "Avion"
                    icon: "airplanemode_active"
                    active: controller.airplaneEnabled
                    known: controller.wifiStateKnown && controller.bluetoothStateKnown
                    onClicked: controller.toggleAirplane()
                }
            }

            PowerSlider {
                id: powerSlider
                width: parent.width

                Connections {
                    target: controller
                    function onPanelOpenChanged() {
                        if (controller.panelOpen) {
                            powerSlider.refresh()
                        }
                    }
                }

                Connections {
                    target: powerSlider
                    function onProfileRequested(profile) {
                        controller.panelOpen = false
                    }
                    function onProfileChanged(profile) {
                        controller.handlePowerProfileSelected(
                            ["power-saver", "balanced", "performance"][profile])
                    }
                }
            }

            SegmentedControl {
                width: parent.width
                options: [
                    { label: "Déplacement" },
                    { label: "Safe" }
                ]
                selectedIndex: root.controller.tlpChargeMode === "deplacement" ? 0
                    : root.controller.tlpChargeMode === "safe" ? 1 : -1
                enabled: !root.controller.tlpChargeCommandRunning
                onSelected: index => root.controller.setTlpChargeMode(
                    ["deplacement", "safe"][index])
            }

            LevelSlider {
                width: parent.width
                icon: "volume_up"
                value: controller.audio ? controller.audio.volume : 0
                maximumValue: 1.5
                enabled: controller.audio !== null
                unavailableText: "0%"
                onDragged: (value) => {
                    if (controller.audio)
                        controller.audio.volume = value
                }
            }

            LevelSlider {
                width: parent.width
                icon: "brightness_6"
                value: controller.brightness
                enabled: controller.brightnessStateKnown
                onDragged: (value) => controller.setBrightness(value)
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.buttonHover
            }

            Item {
                width: parent.width
                height: 28

                Text {
                    anchors.left: parent.left
                    anchors.right: notificationActions.left
                    anchors.rightMargin: Theme.spacing
                    text: "Notifications récentes"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 1
                    font.weight: Font.DemiBold
                    verticalAlignment: Text.AlignVCenter
                }

                Row {
                    id: notificationActions

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacing / 2

                    BarButton {
                        width: 28
                        height: 28
                        label: "delete_sweep"
                        tooltip: "Effacer l’historique"
                        onClicked: controller.history = []
                    }

                    Rectangle {
                        id: muteButton

                        width: controller.notificationsMuted ? 86 : 28
                        height: 28
                        radius: Theme.cornerRadius
                        color: muteMouse.containsMouse ? Theme.buttonHover : controller.notificationsMuted ? Theme.surface : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            text: controller.notificationsMuted ? "notifications_paused" : "notifications_active"
                            color: controller.notificationsMuted ? "#fb4934" : Theme.text
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.iconSize
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            visible: controller.notificationsMuted
                            text: controller.muteTimeRemaining
                            color: "#fb4934"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 4
                        }

                        MouseArea {
                            id: muteMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (controller.notificationsMuted)
                                    controller.cancelNotificationMute()
                                else
                                    muteMenu.open()
                            }
                        }

                        Popup {
                            id: muteMenu

                            parent: muteButton
                            y: muteButton.height + 4
                            x: muteButton.width - width
                            width: 248
                            padding: 8
                            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                            background: Rectangle {
                                radius: Theme.cornerRadius
                                color: Theme.componentBackground
                                border.width: 1
                                border.color: Theme.componentBorder
                            }

                            contentItem: Column {
                                spacing: 4

                                Item {
                                    width: 232
                                    height: 28

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Mettre en sourdine"
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Repeater {
                                    model: [{
                                        "title": "15 minutes",
                                        "detail": "Petite pause",
                                        "duration": 900000
                                    }, {
                                        "title": "1 heure",
                                        "detail": "Pour rester concentré",
                                        "duration": 3.6e+06
                                    }, {
                                        "title": "8 heures",
                                        "detail": "Jusqu’à la fin de la journée",
                                        "duration": 2.88e+07
                                    }, {
                                        "title": "Sans limite",
                                        "detail": "Jusqu’à réactivation",
                                        "duration": -1
                                    }]

                                    delegate: Rectangle {
                                        required property var modelData

                                        width: 232
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
                                            onClicked: controller.setNotificationMute(modelData.duration)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: controller.muteMessage !== ""
                width: parent.width
                height: visible ? 28 : 0
                radius: Theme.cornerRadius
                color: Qt.rgba(0.98, 0.28, 0.2, 0.14)

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    text: controller.muteMessage
                    color: "#fb4934"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    verticalAlignment: Text.AlignVCenter
                }
            }

            ListView {
                width: parent.width
                height: Math.max(0, parent.height - 28 - 144 - 56 - 28 - 28 - 1 - 28 - Theme.spacing * 8 - (controller.muteMessage !== "" ? 28 + Theme.spacing : 0))
                clip: true
                spacing: Theme.spacing
                model: controller.history.slice(0, 6)

                Text {
                    anchors.centerIn: parent
                    visible: controller.history.length === 0
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
                    onDismissed: controller.removeHistoryNotification(notificationIndex)
                }
            }
        }
    }
}
