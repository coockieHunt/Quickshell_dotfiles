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
            icon: {
                const c = root.hostBar.controller
                if (!c.wifiEnabled) return "wifi_off"
                if (c.wifiNetworkName === "") return "wifi"
                if (c.wifiSignal >= 75) return "signal_wifi_4_bar"
                if (c.wifiSignal >= 50) return "network_wifi_3_bar"
                if (c.wifiSignal >= 25) return "network_wifi_2_bar"
                return "network_wifi_1_bar"
            }
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

        BarButton {
            id: soundButton
            label: {
                const c = root.hostBar.controller
                if (!c.soundStateKnown) return "volume_up"
                if (c.soundMuted) return "volume_off"
                if (c.soundVolume === 0) return "volume_mute"
                if (c.soundVolume < 50) return "volume_down"
                return "volume_up"
            }
            tooltip: "Clic souris : +/- 10%\nClic molette : muet"

            onClicked: root.hostBar.controller.changeSoundVolume(-10)
            onRightClicked: root.hostBar.controller.changeSoundVolume(10)
            onMiddleClicked: root.hostBar.controller.toggleSound()
        }

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

        PerformanceIndicator {
            source: root.hostBar.performanceSource
        }

        BarSeparator {}

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

            Rectangle {
                id: badge
                readonly property int count: root.hostBar.notificationController.notificationCount
                visible: count > 0
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.bottomMargin: -3
                anchors.rightMargin: -3
                width: Math.max(height, badgeText.implicitWidth + 6)
                height: 13
                radius: height / 2
                color: Theme.accent
                border.width: 1
                border.color: Theme.bg

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: badge.count > 99 ? "99+" : badge.count
                    color: Theme.textOnAccent
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                }
            }
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
