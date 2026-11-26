import QtQuick
import Quickshell.Services.UPower
import "../../../components"
import "../../../components/action"
import "../../../components/info"
import "../../../theme"
import "../../controls"

BarBlock {
    id: root

    required property var hostBar
    property bool trayOpen: false
    property bool historyOpen: false
    readonly property Item trayAnchor: trayButton
    readonly property Item historyAnchor: historyButton
    signal trayClicked()
    signal historyClicked()

    contentWidth: rightContent.implicitWidth

    Row {
        id: rightContent
        anchors.centerIn: parent
        spacing: Theme.spacing / 2

        ConnectivityButton {
            icon: "wifi"
            title: "Wi-Fi"
            stateKnown: root.hostBar.controller.wifiStateKnown
            stateEnabled: root.hostBar.controller.wifiEnabled
            detail: root.hostBar.controller.wifiNetworkName
            emptyDetail: "Non connecté"
            onClicked: root.hostBar.popup(Theme.wifiApplication)
            onRightClicked: {
                if (Theme.barWifiRightClick === "toggle")
                    root.hostBar.controller.toggleWifi()
            }
        }

        ConnectivityButton {
            icon: "bluetooth"
            title: "Bluetooth"
            stateKnown: root.hostBar.controller.bluetoothStateKnown
            stateEnabled: root.hostBar.controller.bluetoothEnabled
            detail: root.hostBar.controller.bluetoothConnectedNames
            emptyDetail: "Aucun appareil"
            onClicked: root.hostBar.popup(Theme.bluetoothApplication)
            onRightClicked: {
                if (Theme.barBluetoothRightClick === "toggle")
                    root.hostBar.controller.toggleBluetooth()
            }
        }

        BarButton { label: "volume_up"; onClicked: root.hostBar.popup("pavucontrol") }

        BarSeparator {}

        Repeater {
            model: UPower.devices

            BatteryIndicator {
                required property var modelData
                device: modelData
                tlpChargeMode: root.hostBar.controller.tlpChargeMode
            }
        }

        BarSeparator {}

        Item {
            width: Theme.spacing
            height: 1
        }

        BarButton {
            id: trayButton
            label: root.trayOpen ? "expand_less" : "expand_more"
            highlighted: root.trayOpen
            onClicked: root.trayClicked()
        }

        BarButton {
            id: historyButton
            label: root.hostBar.notificationController.notificationsMuted
                ? "notifications_paused" : "notifications"
            highlighted: root.historyOpen
            onClicked: root.historyClicked()
        }

        BarButton {
            label: "view_cozy"
            highlighted: root.hostBar.controller.panelOpen
            onClicked: root.hostBar.controller.togglePanel()
        }

        MoreMenu {
            id: moreMenu
            hostBar: root.hostBar
        }
    }
}
