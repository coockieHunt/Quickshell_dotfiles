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
    spacing: 0

    TextMetrics {
        id: widest
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        text: "100%"
    }

    Row {
        height: Theme.buttonSize
        spacing: Theme.spacing / 2

        Text {
            anchors.baseline: value.baseline
            text: "RAM"
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            font.weight: Font.DemiBold
        }

        Text {
            id: value
            anchors.verticalCenter: parent.verticalCenter
            width: widest.width
            text: `${root.ramPercent}%`
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }

    Row {
        height: Theme.buttonSize
        spacing: Theme.spacing / 2

        Text {
            anchors.baseline: cpuValue.baseline
            text: "CPU"
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            font.weight: Font.DemiBold
        }

        Text {
            id: cpuValue
            anchors.verticalCenter: parent.verticalCenter
            width: widest.width
            text: `${root.cpuPercent}%`
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }
}
