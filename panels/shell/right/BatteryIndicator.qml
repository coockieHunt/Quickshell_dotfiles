import QtQuick
import "../../../components/tooltip"
import "../../../theme"
import "services"

Row {
    id: root

    required property var device
    required property string tlpChargeMode

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
        color: Theme.accent
        font.family: Theme.iconFont
        font.pixelSize: Theme.iconSize
        y: (parent.height - implicitHeight) / 2
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
