// Used by: 1 file(s)
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import QtQuick
import "../components"
import "../components/tooltip"
import "../components/tooltip"
import "../theme"

Scope {
    id: barRoot
    required property bool barVisible
    required property var launcherControl
    required property var wallpaperPicker
    required property var powerMenuControl
    required property var notificationControl
    property var performanceSource: null
    property bool updateCheckKnown: false
    property bool updateCheckHadErrors: false
    property int availableUpdateCount: 0
    signal hideRequested()

    Process {
        id: updateCheckProcess
        command: ["pacman", "-Qu"]
        stdout: StdioCollector {
            onStreamFinished: {
                const updates = text.trim()
                barRoot.availableUpdateCount = updates.length === 0
                    ? 0
                    : updates.split("\n").filter(line => line.trim() !== "").length
            }
        }
        stderr: SplitParser {
            onRead: line => {
                barRoot.updateCheckHadErrors = true
                console.warn("Vérification des mises à jour Pacman:", line)
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 || (exitCode === 1 && !barRoot.updateCheckHadErrors)) {
                barRoot.updateCheckKnown = true
            } else {
                barRoot.updateCheckKnown = false
                console.warn("La vérification des mises à jour Pacman a échoué:", exitCode, exitStatus)
            }
        }
    }

    function checkForUpdates() {
        if (updateCheckProcess.running)
            return
        updateCheckHadErrors = false
        updateCheckProcess.running = true
    }

    Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: true
        onTriggered: barRoot.checkForUpdates()
    }

    Component.onCompleted: checkForUpdates()

    function popup(cmd, size) {
        const s = size || "700 500"
        Quickshell.execDetached(["hyprctl", "dispatch",
            'hl.dsp.exec_cmd("' + cmd + '", { float = true, center = true, size = "' + s + '" })'])
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
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
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.activate()
                            }
                        }
                    }

                    BarButton {
                        label: "apps"
                        iconColor: Theme.accent
                        onClicked: barRoot.launcherControl.toggle()
                    }
                    BarButton {
                        label: "wallpaper"
                        onClicked: barRoot.wallpaperPicker.toggle()
                    }
                    BarButton {
                        label: "fullscreen"
                        tooltip: "Masquer la barre"
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
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)

                Row {
                    id: clockText
                    anchors.centerIn: parent
                    height: parent.height
                    spacing: 4

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

                        PopupTooltip {
                            anchorItem: ecoBadge
                            text: "Cliquer pour revenir au mode équilibré"
                            shown: ecoBadgeMouse.containsMouse
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

                        PopupTooltip {
                            anchorItem: performanceBadge
                            text: "Cliquer pour revenir au mode équilibré"
                            shown: performanceBadgeMouse.containsMouse
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
                            tooltip: ""
                            anchors.fill: parent
                            onClicked: barRoot.popup("nm-connection-editor")
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
                            tooltip: ""
                            anchors.fill: parent
                            onClicked: barRoot.popup("blueman-manager")
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

                    Item {
                        width: updatesButton.width
                        height: updatesButton.height

                        BarButton {
                            id: updatesButton
                            label: "system_update_alt"
                            tooltip: ""
                            anchors.fill: parent
                            onClicked: barRoot.popup(Theme.updateApplicationCommand.join(" "), "900 650")
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                            width: 7
                            height: 7
                            radius: width / 2
                            color: Theme.accent
                            visible: barRoot.updateCheckKnown && barRoot.availableUpdateCount > 0
                            border.width: 1
                            border.color: Theme.componentBackground
                            z: 1
                        }

                        ConnectivityTooltip {
                            anchorItem: updatesButton
                            shown: updatesButton.hovered
                            title: "Mises à jour"
                            icon: "system_update_alt"
                            status: !barRoot.updateCheckKnown
                                ? "Vérification indisponible"
                                : barRoot.availableUpdateCount > 0
                                    ? barRoot.availableUpdateCount === 1
                                        ? "1 mise à jour disponible"
                                        : `${barRoot.availableUpdateCount} mises à jour disponibles`
                                    : "Aucune mise à jour disponible"
                            detail: "État des paquets installés (pacman -Qu)"
                        }
                    }

                    BarButton {
                        label: "notifications"
                        highlighted: barRoot.notificationControl.panelOpen
                        onClicked: barRoot.notificationControl.togglePanel()
                    }

                    BarButton {
                        label: "power_settings_new"
                        iconColor: Theme.accent
                        onClicked: barRoot.powerMenuControl.openOn(modelData)
                    }

                }

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 1
                    color: Qt.rgba(Theme.componentBackground.r, Theme.componentBackground.g, Theme.componentBackground.b, 0.95)
                }
            }
        }
    }
}
