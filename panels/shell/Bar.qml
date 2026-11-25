import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import QtQuick
import "../../components"
import "../../components/action"
import "../../components/info"
import "../../components/tooltip"
import "../../theme"
import "../../panels/services"
import "../apps"
import "../controls"

Scope {
    id: barRoot
    required property bool barVisible
    required property var launcherControl
    required property var wallpaperPicker
    required property var notificationControl
    property var performanceSource: null
    property bool superHeld: false
    signal hideRequested()

    GlobalShortcut {
        name: Theme.superHighlightVar
        description: "État d’appui de la touche Super pour la barre"
        onPressed: barRoot.superHeld = Theme.superHighlightEnabled
        onReleased: barRoot.superHeld = false
    }

    function popup(cmd, size) {
        const s = size || "700 500"
        Quickshell.execDetached(["hyprctl", "dispatch",
            'hl.dsp.exec_cmd("' + cmd + '", { float = true, center = true, size = "' + s + '" })'])
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    WeatherService {
        id: weather
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            id: panelWindow
            property bool trayPopupOpen: false
            property bool calendarOpen: false
            property bool weatherOpen: false
            screen: modelData
            visible: barRoot.barVisible

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: Theme.barHeight
            color: "transparent"
            WlrLayershell.namespace: "quickshell-bar"

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.leftMargin: 5
                width: leftContent.implicitWidth + Theme.margin * 2
                height: Theme.barHeight
                bottomLeftRadius: Theme.cornerRadius
                bottomRightRadius: Theme.cornerRadius
                color: Qt.rgba(Theme.componentBackground.r, Theme.componentBackground.g, Theme.componentBackground.b, 0.95)
                border.width: 0.5
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)

                Row {
                    id: leftContent
                    anchors.centerIn: parent
                    spacing: Theme.spacing

                    Repeater {
                        model: Hyprland.workspaces.values
                            .filter(w => w.id > 0 && w.monitor?.name === modelData.name)
                            .sort((x, y) => x.id - y.id)

                        Rectangle {
                            required property var modelData
                            width: modelData.focused ? Theme.workspaceSize * 1.5 : Theme.workspaceSize
                            height: Theme.workspaceSize
                            radius: Theme.cornerRadius
                            color: modelData.focused ? Theme.accent : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 140 }
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 6
                                height: 6
                                radius: Theme.cornerRadius
                                visible: !modelData.focused && !workspaceMouse.containsMouse
                                color: Theme.text
                                opacity: workspaceMouse.containsMouse ? 1 : 0.6
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.id
                                visible: modelData.focused || workspaceMouse.containsMouse
                                color: modelData.focused
                                    ? Theme.textOnAccent
                                    : workspaceMouse.containsMouse ? Theme.accent : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 1
                                font.weight: modelData.focused ? Font.DemiBold : Font.Normal
                            }

                            MouseArea {
                                id: workspaceMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.activate()
                            }
                        }
                    }

                    BarButton {
                        label: Theme.archLogo
                        iconFont: Theme.brandFont
                        iconColor: Theme.accent
                        iconSize: Theme.iconSize - 2
                        onClicked: barRoot.launcherControl.toggle()
                    }
                    BarButton {
                        label: "wallpaper"
                        tooltip: "Clic gauche : ouvrir le sélecteur\nClic droit : fond aléatoire\nClic molette : supprimer l’actuel"
                        onClicked: barRoot.wallpaperPicker.toggle()
                        onRightClicked: Quickshell.execDetached([
                            Theme.wallpaperScript, "--directory", Theme.wallpaperDir, "random"
                        ])
                        onMiddleClicked: Quickshell.execDetached([
                            Theme.wallpaperScript, "--directory", Theme.wallpaperDir, "delete-current"
                        ])
                    }
                    BarButton {
                        label: "top_panel_close"
                        onClicked: barRoot.hideRequested()
                    }
                }

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 1
                    color: Qt.rgba(Theme.componentBackground.r, Theme.componentBackground.g, Theme.componentBackground.b, 0.95)
                }
            }

            Rectangle {
                id: clockBlock
                anchors.centerIn: parent
                width: clockText.implicitWidth
                    + (ecoBadge.visible ? ecoBadge.implicitWidth + 8 : 0)
                    + (barRoot.notificationControl.powerProfile === "performance" ? performanceBadge.implicitWidth + 8 : 0)
                    + (airplaneBadge.visible ? airplaneBadge.implicitWidth + 8 : 0)
                    + Theme.margin * 2
                height: Theme.barHeight
                bottomLeftRadius: Theme.cornerRadius
                bottomRightRadius: Theme.cornerRadius
                color: Qt.rgba(Theme.componentBackground.r, Theme.componentBackground.g, Theme.componentBackground.b, 0.95)
                border.width: 0.5
                border.color: Theme.superHighlightEnabled && barRoot.superHeld
                    ? Theme.accent
                    : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)

                Behavior on border.color {
                    ColorAnimation { duration: 120 }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        panelWindow.weatherOpen = false
                        panelWindow.calendarOpen = !panelWindow.calendarOpen
                    }
                }

                Row {
                    id: clockText
                    anchors.centerIn: parent
                    height: parent.height
                    spacing: 4

                    Item {
                        id: weatherButton
                        visible: weather.available
                        width: weatherContent.implicitWidth + 10
                        height: parent.height

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: Theme.buttonSize + 4
                            radius: Theme.cornerRadius
                            color: weatherMouse.containsMouse || panelWindow.weatherOpen
                                ? Theme.buttonHover : "transparent"
                        }

                        Row {
                            id: weatherContent
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: weather.icon
                                color: Theme.accent
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.iconSize
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: weather.temperatureText
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                            }
                        }

                        MouseArea {
                            id: weatherMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                panelWindow.calendarOpen = false
                                panelWindow.weatherOpen = !panelWindow.weatherOpen
                            }
                        }
                    }

                    Item {
                        visible: weather.available
                        width: Theme.spacing
                        height: parent.height

                        Rectangle {
                            anchors.centerIn: parent
                            width: 1
                            height: Theme.buttonSize * 0.65
                            color: Theme.buttonHover
                            rotation: 15
                        }
                    }

                    Text {
                        height: parent.height
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        verticalAlignment: Text.AlignVCenter
                        text: clock.date.toLocaleString(Qt.locale("fr_FR"), "ddd")
                    }

                    Text {
                        height: parent.height
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        verticalAlignment: Text.AlignVCenter
                        text: Qt.formatDateTime(clock.date, "d")
                    }

                    Text {
                        height: parent.height
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        verticalAlignment: Text.AlignVCenter
                        text: clock.date.toLocaleString(Qt.locale("fr_FR"), "MMM")
                    }

                    Text {
                        height: parent.height
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        verticalAlignment: Text.AlignVCenter
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                    }

                    Rectangle {
                        id: ecoBadge
                        visible: barRoot.notificationControl.ecoModeActive
                            || barRoot.notificationControl.powerProfile === "power-saver"
                        width: ecoBadgeContent.implicitWidth + 10
                        height: 20
                        y: (parent.height - height) / 2
                        color: "transparent"

                        Row {
                            id: ecoBadgeContent
                            anchors.centerIn: parent
                            spacing: 3

                            Text {
                                text: "eco"
                                color: Theme.accent
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.iconSize - 2
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "ÉCO"
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 4
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: ecoBadgeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: barRoot.notificationControl.returnToBalancedProfile()
                        }
                    }

                    Rectangle {
                        id: performanceBadge
                        visible: barRoot.notificationControl.powerProfile === "performance"
                        width: performanceBadgeContent.implicitWidth + 10
                        height: 20
                        y: (parent.height - height) / 2
                        color: "transparent"

                        Row {
                            id: performanceBadgeContent
                            anchors.centerIn: parent
                            spacing: 3

                            Text {
                                text: "bolt"
                                color: Theme.accent
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.iconSize - 2
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "MAX"
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 4
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: performanceBadgeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: barRoot.notificationControl.returnToBalancedProfile()
                        }
                    }

                    Rectangle {
                        id: airplaneBadge
                        visible: barRoot.notificationControl.airplaneEnabled
                        width: airplaneBadgeContent.implicitWidth + 10
                        height: 20
                        y: (parent.height - height) / 2
                        color: "transparent"

                        Row {
                            id: airplaneBadgeContent
                            anchors.centerIn: parent

                            Text {
                                text: "airplanemode_active"
                                color: Theme.accent
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.iconSize - 2
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        PopupTooltip {
                            anchorItem: airplaneBadge
                            shown: airplaneBadgeMouse.containsMouse
                            text: "Wi-Fi et Bluetooth désactivés"
                        }

                        MouseArea {
                            id: airplaneBadgeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }

                    Item {
                        visible: mediaWidget.visible
                        width: Theme.spacing
                        height: parent.height

                        Rectangle {
                            anchors.centerIn: parent
                            width: 1
                            height: Theme.buttonSize * 0.65
                            color: Theme.buttonHover
                            rotation: 15
                        }
                    }

                    MediaWidget {
                        id: mediaWidget
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 1
                    color: Qt.rgba(Theme.componentBackground.r, Theme.componentBackground.g, Theme.componentBackground.b, 0.95)
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 5
                width: rightContent.implicitWidth + Theme.margin * 2
                height: Theme.barHeight
                bottomLeftRadius: Theme.cornerRadius
                bottomRightRadius: Theme.cornerRadius
                color: Qt.rgba(Theme.componentBackground.r, Theme.componentBackground.g, Theme.componentBackground.b, 0.95)
                border.width: 0.5
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)

                Row {
                    id: rightContent
                    anchors.centerIn: parent
                    spacing: Theme.spacing / 2

                    Item {
                        width: wifiButton.width
                        height: wifiButton.height

                        BarButton {
                            id: wifiButton
                            label: "wifi"
                            anchors.fill: parent
                            onClicked: barRoot.popup(Theme.wifiApplication)
                            onRightClicked: {
                                if (Theme.barWifiRightClick === "toggle")
                                    barRoot.notificationControl.toggleWifi()
                            }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                            width: 7
                            height: 7
                            radius: width / 2
                            color: Theme.accent
                            visible: barRoot.notificationControl.wifiStateKnown
                                && barRoot.notificationControl.wifiEnabled
                            border.width: 1
                            border.color: Theme.componentBackground
                            z: 1
                        }

                        ConnectivityTooltip {
                            anchorItem: wifiButton
                            shown: wifiButton.hovered
                            title: "Wi-Fi"
                            icon: "wifi"
                            status: !barRoot.notificationControl.wifiStateKnown
                                ? "Lecture…"
                                : barRoot.notificationControl.wifiEnabled ? "Activé" : "Désactivé"
                            detail: !barRoot.notificationControl.wifiStateKnown
                                ? ""
                                : !barRoot.notificationControl.wifiEnabled
                                    ? ""
                                    : barRoot.notificationControl.wifiNetworkName || "Non connecté"
                        }
                    }

                    Item {
                        width: bluetoothButton.width
                        height: bluetoothButton.height

                        BarButton {
                            id: bluetoothButton
                            label: "bluetooth"
                            anchors.fill: parent
                            onClicked: barRoot.popup(Theme.bluetoothApplication)
                            onRightClicked: {
                                if (Theme.barBluetoothRightClick === "toggle")
                                    barRoot.notificationControl.toggleBluetooth()
                            }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                            width: 7
                            height: 7
                            radius: width / 2
                            color: Theme.accent
                            visible: barRoot.notificationControl.bluetoothStateKnown
                                && barRoot.notificationControl.bluetoothEnabled
                            border.width: 1
                            border.color: Theme.componentBackground
                            z: 1
                        }

                        ConnectivityTooltip {
                            anchorItem: bluetoothButton
                            shown: bluetoothButton.hovered
                            title: "Bluetooth"
                            icon: "bluetooth"
                            status: !barRoot.notificationControl.bluetoothStateKnown
                                ? "Lecture…"
                                : barRoot.notificationControl.bluetoothEnabled ? "Activé" : "Désactivé"
                            detail: !barRoot.notificationControl.bluetoothStateKnown
                                ? ""
                                : !barRoot.notificationControl.bluetoothEnabled
                                    ? ""
                                    : barRoot.notificationControl.bluetoothConnectedNames || "Aucun appareil"
                        }
                    }

                    Item {
                        id: airplaneIndicator
                        visible: barRoot.notificationControl.airplaneEnabled
                        width: visible ? Theme.buttonSize : 0
                        height: Theme.buttonSize

                        Text {
                            anchors.centerIn: parent
                            text: "airplanemode_active"
                            color: Theme.accent
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.iconSize
                        }

                        PopupTooltip {
                            anchorItem: airplaneIndicator
                            shown: airplaneHover.containsMouse
                            title: "Mode avion"
                            icon: "airplanemode_active"
                            text: "Wi-Fi et Bluetooth désactivés"
                        }

                        MouseArea {
                            id: airplaneHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }

                    BarButton { label: "volume_up"; onClicked: barRoot.popup("pavucontrol") }

                    Item {
                        width: Theme.spacing
                        height: Theme.buttonSize

                        Rectangle {
                            anchors.centerIn: parent
                            width: 1
                            height: Theme.buttonSize * 0.65
                            color: Theme.buttonHover
                            rotation: 15
                        }
                    }

                    Repeater {
                        model: UPower.devices

                        Row {
                            id: batteryIndicator
                            required property var modelData
                            readonly property string batteryStatus: {
                                if (modelData.state === UPowerDeviceState.Charging)
                                    return "En charge"
                                if (modelData.state === UPowerDeviceState.Discharging)
                                    return "En décharge"
                                if (modelData.state === UPowerDeviceState.FullyCharged)
                                    return "Chargée"
                                if (modelData.state === UPowerDeviceState.PendingCharge)
                                    return "Charge en attente"
                                if (modelData.state === UPowerDeviceState.PendingDischarge)
                                    return "Décharge en attente"
                                return "État inconnu"
                            }
                            readonly property string powerFlow: {
                                const rate = modelData.changeRate
                                if (rate > 0 && modelData.state === UPowerDeviceState.Charging)
                                    return `+${Math.abs(rate).toFixed(1)} W`
                                if (rate > 0 && modelData.state === UPowerDeviceState.Discharging)
                                    return `-${Math.abs(rate).toFixed(1)} W`
                                return "0 W"
                            }
                            visible: modelData.isLaptopBattery
                            height: Theme.buttonSize
                            spacing: Theme.spacing / 2

                            BatteryTooltip {
                                anchorItem: batteryIndicator
                                shown: batteryHover.hovered
                                status: batteryIndicator.batteryStatus
                                powerFlow: batteryIndicator.powerFlow
                                percentage: batteryIndicator.modelData.percentage
                                chargeMode: {
                                    const mode = barRoot.notificationControl.tlpChargeMode
                                    if (mode === "deplacement")
                                        return "Déplacement"
                                    if (mode === "safe")
                                        return "Safe"
                                    return "Inconnu"
                                }
                                chargeModeIcon: barRoot.notificationControl.tlpChargeMode === "deplacement"
                                    ? "directions_walk"
                                    : barRoot.notificationControl.tlpChargeMode === "safe"
                                        ? "health_and_safety" : "battery_unknown"
                            }

                            Text {
                                visible: modelData.state === UPowerDeviceState.Charging
                                    || (!UPower.onBattery && (
                                        modelData.state === UPowerDeviceState.FullyCharged
                                        || modelData.state === UPowerDeviceState.PendingCharge
                                    ))
                                text: modelData.state === UPowerDeviceState.Charging ? "bolt" : "electrical_services"
                                color: Theme.accent
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.iconSize
                                y: (parent.height - implicitHeight) / 2
                            }

                            Text {
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                text: `${Math.round(modelData.percentage * 100)}%`
                                y: (parent.height - implicitHeight) / 2
                            }

                            HoverHandler {
                                id: batteryHover
                            }
                        }
                    }

                    Item {
                        width: Theme.spacing
                        height: Theme.buttonSize

                        Rectangle {
                            anchors.centerIn: parent
                            width: 1
                            height: Theme.buttonSize * 0.65
                            color: Theme.buttonHover
                            rotation: 15
                        }
                    }

                    SystemUsage {
                        id: systemUsage
                        onHasCpuSampleChanged: {
                            if (systemUsage.hasCpuSample)
                                barRoot.performanceSource = systemUsage
                        }
                    }

                    Item {
                        width: Theme.spacing
                        height: 1
                    }

                    BarButton {
                        id: trayButton
                        label: panelWindow.trayPopupOpen ? "expand_less" : "expand_more"
                        highlighted: panelWindow.trayPopupOpen
                        onClicked: panelWindow.trayPopupOpen = !panelWindow.trayPopupOpen
                    }

                    BarButton {
                        label: "view_cozy"
                        highlighted: barRoot.notificationControl.panelOpen
                        onClicked: barRoot.notificationControl.togglePanel()
                    }


                    MoreMenu {
                        id: moreMenu
                        hostBar: barRoot
                    }

                }

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 1
                    color: Qt.rgba(Theme.componentBackground.r, Theme.componentBackground.g, Theme.componentBackground.b, 0.95)
                }
            }

            SystemTrayPanel {
                anchorItem: trayButton
                open: panelWindow.trayPopupOpen
                barVisible: barRoot.barVisible
                onClosed: panelWindow.trayPopupOpen = false
            }

            LazyLoader {
                active: panelWindow.calendarOpen

                Calandar {
                    anchorItem: clockBlock
                    onClosed: panelWindow.calendarOpen = false
                }
            }

            LazyLoader {
                active: panelWindow.weatherOpen

                Weather {
                    anchorItem: weatherButton
                    service: weather
                    onClosed: panelWindow.weatherOpen = false
                }
            }
        }
    }
}
