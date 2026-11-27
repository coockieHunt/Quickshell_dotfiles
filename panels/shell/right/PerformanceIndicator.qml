

import QtQuick
import "../../../theme"

Row {
    id: root

    required property var source

    readonly property int ramPercent: source.memoryTotal > 0
        ? Math.round(source.memoryUsed / source.memoryTotal * 100)
        : 0
    readonly property int cpuPercent: Math.round(source.cpuUsage)

    height: Theme.buttonSize
    spacing: Theme.spacing / 3

    TextMetrics {
        id: widest
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        text: "100%"
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "RAM"
        color: Theme.accent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 2
        font.weight: Font.DemiBold
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: `${root.ramPercent}%`
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }

    Item { width: Theme.spacing; height: 1 }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "CPU"
        color: Theme.accent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 2
        font.weight: Font.DemiBold
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: `${root.cpuPercent}%`
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }
}
