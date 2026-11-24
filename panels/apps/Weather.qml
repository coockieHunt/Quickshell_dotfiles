import Quickshell
import QtQuick
import "../../theme"

PopupWindow {
    id: root

    required property Item anchorItem
    required property var service

    readonly property var locale: Qt.locale("fr_FR")
    readonly property var today: service.daily.length > 0 ? service.daily[0] : null
    readonly property var forecast: service.daily.slice(1, 6)

    readonly property var details: [
        { icon: "thermostat", label: "Ressenti", value: service.feelsLikeText },
        { icon: "water_drop", label: "Humidité", value: service.humidityText },
        { icon: "air", label: "Vent", value: service.windText }
    ]

    function capitalize(s) {
        return s.length > 0 ? s.charAt(0).toUpperCase() + s.slice(1) : s
    }

    function dayLabel(dateString, index) {
        if (index === 0)
            return "Demain"
        const p = dateString.split("-")
        const d = new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2]))
        return capitalize(d.toLocaleString(root.locale, "dddd"))
    }

    anchor.window: anchorItem.QsWindow.window
    anchor.adjustment: PopupAdjustment.None
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.onAnchoring: {
        const content = anchorItem.QsWindow.contentItem
        const pos = content.mapFromItem(
            anchorItem,
            anchorItem.width / 2 - root.width / 2,
            anchorItem.height
        )
        anchor.rect.x = Math.max(4, Math.min(pos.x, content.width - root.width - 4))
        anchor.rect.y = pos.y + Theme.dropdownGap
    }

    visible: true
    grabFocus: true
    color: "transparent"
    implicitWidth: 300
    implicitHeight: content.implicitHeight + 28

    onVisibleChanged: {
        if (!visible)
            root.closed()
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Theme.componentBackground
        border.width: 1
        border.color: Theme.componentBorder

        Column {
            id: content
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Row {
                spacing: 14

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.service.icon
                    color: Theme.accent
                    font.family: Theme.iconFont
                    font.pixelSize: 48
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: root.service.temperatureText
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 15
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: root.service.description
                        color: Theme.text
                        opacity: 0.85
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    Text {
                        visible: root.today !== null
                        text: root.today
                            ? "Min " + Math.round(root.today.min) + "° · Max " + Math.round(root.today.max) + "°"
                            : ""
                        color: Theme.text
                        opacity: 0.6
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
            }

            Row {
                spacing: 8

                Repeater {
                    model: root.details

                    Rectangle {
                        required property var modelData
                        width: (content.width - 16) / 3
                        height: 62
                        radius: Theme.cornerRadius
                        color: Theme.componentSurface

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon
                                color: Theme.accent
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.iconSize
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.value
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.weight: Font.DemiBold
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: Theme.text
                                opacity: 0.6
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 3
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.buttonHover
            }

            Column {
                width: parent.width
                spacing: 2

                Repeater {
                    model: root.forecast

                    Item {
                        required property var modelData
                        required property int index
                        width: content.width
                        height: 30

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.dayLabel(modelData.date, index)
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        Text {
                            x: 112
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.service.iconFor(modelData.code, true)
                            color: Theme.accent
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.iconSize + 2
                        }

                        Text {
                            x: 146
                            anchors.verticalCenter: parent.verticalCenter
                            visible: modelData.rain > 0
                            text: Math.round(modelData.rain) + " %"
                            color: Theme.text
                            opacity: 0.6
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Text {
                                text: Math.round(modelData.min) + "°"
                                color: Theme.text
                                opacity: 0.6
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                            }

                            Text {
                                text: Math.round(modelData.max) + "°"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "Données : Open-Meteo.com"
                color: Theme.text
                opacity: 0.4
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 3
            }
        }
    }
}
