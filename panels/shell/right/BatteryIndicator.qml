import QtQuick
import Quickshell.Services.UPower
import "../../../components/tooltip"
import "../../../theme"
import "services"

Row {
    id: root

    required property var device
    required property string tlpChargeMode

    readonly property real percent: device.percentage <= 1
        ? device.percentage * 100 : device.percentage
    readonly property bool charging: device.state === UPowerDeviceState.Charging
        || device.state === UPowerDeviceState.FullyCharged

    readonly property color levelColor: {
        if (charging)     return "#4CAF50"  
        if (percent < 20) return "#F44336"   
        if (percent < 50) return "#FF9800"  
        return Theme.text                    
    }

    visible: device.isLaptopBattery
    height: Theme.buttonSize
    spacing: Theme.spacing / 2

    BatteryService {
        id: battery
        device: root.device
        tlpChargeMode: root.tlpChargeMode
    }

    BatteryTooltip {
        anchorItem: root
        shown: hover.hovered
        status: battery.status
        powerFlow: battery.powerFlow
        percentage: root.device.percentage
        chargeMode: battery.chargeMode
        chargeModeIcon: battery.chargeModeIcon
    }

    Text {
        visible: battery.chargeIconVisible
        text: battery.chargeIcon
        color: root.levelColor
        font.family: Theme.iconFont
        font.pixelSize: Theme.iconSize
        y: (parent.height - implicitHeight) / 2

        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }

    Text {
        text: battery.percentageText
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        y: (parent.height - implicitHeight) / 2
    }


    HoverHandler {
        id: hover
    }
}
