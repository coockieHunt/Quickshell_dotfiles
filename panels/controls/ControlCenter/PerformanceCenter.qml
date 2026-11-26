import QtQuick
import "../../../components"
import "../../../components/info"
import "../../../theme"

Item {
    id: root

    required property var controller
    readonly property var perf: controller.performanceControl

    property string processSort: "cpu"

    readonly property var sortedProcesses: {
        if (!perf || !perf.topProcesses)
            return []
        const list = Array.prototype.slice.call(perf.topProcesses)
        const key = processSort
        list.sort((a, b) => b[key] - a[key])
        return list
    }

    Rectangle {
        visible: controller.panelMode !== "notifications"
        width: 320
        radius: Theme.cornerRadius
        color: Theme.componentBackground
        border.width: 1
        border.color: Theme.componentBorder

        anchors {
            top: parent.top
            left: parent.left
            bottom: parent.bottom
            margins: 4
        }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacing
            spacing: Theme.spacing

            Rectangle {
                width: parent.width
                height: 32
                color: "transparent"

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacing
                    anchors.rightMargin: Theme.spacing
                    text: "Performances"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 2
                    font.weight: Font.DemiBold
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Row {
                width: parent.width
                height: 170
                spacing: 4

                VerticalMeter {
                    width: (parent.width - parent.spacing * 2) / 3
                    height: parent.height
                    label: "GPU"
                    value: perf ? perf.gpuUsage : 0
                    available: perf ? perf.hasGpuSample : false
                }

                VerticalMeter {
                    width: (parent.width - parent.spacing * 2) / 3
                    height: parent.height
                    label: "CPU"
                    value: perf ? perf.cpuUsage : 0
                    available: perf ? perf.hasCpuSample : false
                }

                VerticalMeter {
                    width: (parent.width - parent.spacing * 2) / 3
                    height: parent.height
                    label: "RAM"
                    value: perf && perf.memoryTotal > 0 ? perf.memoryUsed / perf.memoryTotal * 100 : 0
                    available: perf ? perf.memoryTotal > 0 : false
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spacing / 2

                Repeater {
                    model: [{
                        "icon": "speed",
                        "label": "Charge moyenne (1/5/15 min)",
                        "value": perf ? `${perf.loadAverage1.toFixed(2)} / ${perf.loadAverage5.toFixed(2)} / ${perf.loadAverage15.toFixed(2)}` : "Lecture…"
                    }, {
                        "icon": "swap_horiz",
                        "label": "Swap",
                        "value": perf && perf.swapTotal > 0 ? `${perf.formatMemory(perf.swapUsed)} / ${perf.formatMemory(perf.swapTotal)}` : "Aucune swap"
                    }, {
                        "icon": "schedule",
                        "label": "Depuis le démarrage",
                        "value": perf ? perf.formatUptime(perf.uptimeSeconds) : "Lecture…"
                    }, {
                        "icon": "device_thermostat",
                        "label": "Température",
                        "value": perf && perf.temperatureKnown ? `${Math.round(perf.temperatureCelsius)} °C` : "Indisponible"
                    }, {
                        "icon": "download",
                        "label": "Réseau reçu",
                        "value": perf ? perf.formatRate(perf.networkReceiveRate) : "Lecture…"
                    }, {
                        "icon": "upload",
                        "label": "Réseau envoyé",
                        "value": perf ? perf.formatRate(perf.networkTransmitRate) : "Lecture…"
                    }]

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: parent.width
                        height: 28
                        radius: Theme.cornerRadius
                        color: index % 2 === 0
                            ? Theme.componentBackground
                            : Qt.rgba(Theme.componentBackground.r, Theme.componentBackground.g, Theme.componentBackground.b, 0.55)

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacing
                            anchors.rightMargin: Theme.spacing
                            spacing: Theme.spacing / 2

                            Text {
                                width: 20
                                height: parent.height
                                text: modelData.icon
                                color: Theme.accent
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.iconSize
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                width: Math.max(0, parent.width - 20 - valueText.implicitWidth - parent.spacing * 2)
                                height: parent.height
                                text: modelData.label
                                color: Theme.text
                                opacity: 0.75
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            Text {
                                id: valueText
                                height: parent.height
                                text: modelData.value
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 32
                color: "transparent"

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacing
                    anchors.rightMargin: Theme.spacing
                    text: "Processus les plus actifs"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Font.DemiBold
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spacing / 2

                Item {
                    width: parent.width
                    height: 18

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Text {
                            text: "CPU (cœurs)" + (root.processSort === "cpu" ? " ▾" : "")
                            color: root.processSort === "cpu" ? Theme.accent : Theme.text
                            opacity: root.processSort === "cpu" ? 1 : 0.65
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 3
                            font.weight: root.processSort === "cpu" ? Font.DemiBold : Font.Normal

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.processSort = "cpu"
                            }
                        }

                        Text {
                            text: "·"
                            color: Theme.text
                            opacity: 0.65
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 3
                        }

                        Text {
                            text: "RAM" + (root.processSort === "memory" ? " ▾" : "")
                            color: root.processSort === "memory" ? Theme.accent : Theme.text
                            opacity: root.processSort === "memory" ? 1 : 0.65
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 3
                            font.weight: root.processSort === "memory" ? Font.DemiBold : Font.Normal

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.processSort = "memory"
                            }
                        }
                    }
                }

                Repeater {
                    model: root.sortedProcesses

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: parent.width
                        height: 28
                        radius: Theme.cornerRadius
                        color: index % 2 === 0
                            ? Theme.componentBackground
                            : Qt.rgba(Theme.componentBackground.r, Theme.componentBackground.g, Theme.componentBackground.b, 0.55)

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacing
                            anchors.rightMargin: Theme.spacing
                            spacing: Theme.spacing / 2

                            Text {
                                width: Math.max(0, parent.width - processStats.implicitWidth - parent.spacing)
                                height: parent.height
                                text: `${modelData.name}${modelData.count > 1 ? ` · ${modelData.count} processus` : ""}`
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            Text {
                                id: processStats
                                height: parent.height
                                text: `${modelData.cpu.toFixed(2)} cœur${Math.round(modelData.cpu * 100) === 100 ? "" : "s"} · ${root.perf ? root.perf.formatMemory(modelData.memory) : ""}`
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 3
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }

                Text {
                    visible: !root.perf || root.perf.topProcesses.length === 0
                    text: "Lecture des processus…"
                    color: Theme.text
                    opacity: 0.65
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                }
            }
        }
    }
}
