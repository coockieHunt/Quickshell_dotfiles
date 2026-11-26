import QtQuick
import Quickshell.Services.UPower

QtObject {
    id: root

    required property var device
    required property string tlpChargeMode

    readonly property string status: {
        if (device.state === UPowerDeviceState.Charging)
            return "En charge"
        if (device.state === UPowerDeviceState.Discharging)
            return "En décharge"
        if (device.state === UPowerDeviceState.FullyCharged)
            return "Chargée"
        if (device.state === UPowerDeviceState.PendingCharge)
            return "Charge en attente"
        if (device.state === UPowerDeviceState.PendingDischarge)
            return "Décharge en attente"
        return "État inconnu"
    }

    readonly property string powerFlow: {
        const rate = device.changeRate
        if (rate > 0 && device.state === UPowerDeviceState.Charging)
            return `+${Math.abs(rate).toFixed(1)} W`
        if (rate > 0 && device.state === UPowerDeviceState.Discharging)
            return `-${Math.abs(rate).toFixed(1)} W`
        return "0 W"
    }

    readonly property string chargeMode: {
        if (tlpChargeMode === "deplacement")
            return "Déplacement"
        if (tlpChargeMode === "safe")
            return "Safe"
        return "Inconnu"
    }

    readonly property string chargeModeIcon: tlpChargeMode === "deplacement"
        ? "directions_walk"
        : tlpChargeMode === "safe" ? "health_and_safety" : "battery_unknown"

    readonly property bool chargeIconVisible: device.state === UPowerDeviceState.Charging
        || (!UPower.onBattery && (
            device.state === UPowerDeviceState.FullyCharged
            || device.state === UPowerDeviceState.PendingCharge
        ))

    readonly property string chargeIcon: device.state === UPowerDeviceState.Charging
        ? "bolt" : "electrical_services"

    readonly property string percentageText: `${Math.round(device.percentage * 100)}%`
}
