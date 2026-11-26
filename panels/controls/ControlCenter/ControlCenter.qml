import QtQuick
import Quickshell
import Quickshell.Io
import "../../../components"
import "../../../components/action"
import "../../../theme"
import "../../shell"

Item {
    id: root

    required property var controller

    Process {
        id: openConfigWithDefaultApp
        command: ["xdg-open", Theme.configFilePath]

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("Opening config.jsonc with the default application failed:", exitCode, exitStatus)
                openConfigWithEditor.running = true
            }
        }
    }
 
    Process {
        id: openConfigWithEditor
        command: [Theme.textEditorApplication, Theme.configFilePath]

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("Opening config.jsonc with the configured text editor failed:", exitCode, exitStatus)
        }
    }

    Rectangle {
        visible: controller.panelMode !== "performance"
        width: 360
        radius: Theme.cornerRadius
        color: Theme.componentBackground
        border.width: 1
        border.color: Theme.componentBorder

        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
            margins: 4
        }

        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.margin
            spacing: Theme.spacing

            Item {
                width: parent.width
                height: 28

                Text {
                    anchors.left: parent.left
                    anchors.rightMargin: Theme.spacing
                    text: "Centre de contrôle"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 2
                    font.weight: Font.DemiBold
                    verticalAlignment: Text.AlignVCenter
                }
            }


            Row {
                width: parent.width
                height: 72
                spacing: Theme.spacing

                QuickSetting {
                    width: (parent.width - parent.spacing) / 2
                    label: "Wi-Fi"
                    icon: "wifi"
                    active: controller.wifiEnabled
                    known: controller.wifiStateKnown
                    detail: controller.wifiNetworkName
                    onClicked: controller.toggleWifi()
                }

                QuickSetting {
                    width: (parent.width - parent.spacing) / 2
                    label: "Bluetooth"
                    icon: "bluetooth"
                    active: controller.bluetoothEnabled
                    known: controller.bluetoothStateKnown
                    detail: controller.bluetoothConnectedNames
                    onClicked: controller.toggleBluetooth()
                }
            }

            Row {
                width: parent.width
                height: 72
                spacing: Theme.spacing

                QuickSetting {
                    width: (parent.width - parent.spacing) / 2
                    label: "Son"
                    icon: controller.soundMuted ? "volume_off" : "volume_up"
                    active: controller.soundStateKnown && !controller.soundMuted
                    known: controller.soundStateKnown
                    onClicked: controller.toggleSound()
                }

                QuickSetting {
                    width: (parent.width - parent.spacing) / 2
                    label: "Avion"
                    icon: "airplanemode_active"
                    active: controller.airplaneEnabled
                    known: controller.wifiStateKnown && controller.bluetoothStateKnown
                    onClicked: controller.toggleAirplane()
                }
            }

            PowerSlider {
                id: powerSlider
                width: parent.width

                Connections {
                    target: controller
                    function onPanelOpenChanged() {
                        if (controller.panelOpen) {
                            powerSlider.refresh()
                        }
                    }
                }

                Connections {
                    target: powerSlider
                    function onProfileRequested(profile) {
                        controller.panelOpen = false
                    }
                    function onProfileChanged(profile) {
                        controller.handlePowerProfileSelected(
                            ["power-saver", "balanced", "performance"][profile])
                    }
                }
            }

            SegmentedControl {
                width: parent.width
                options: [
                    { label: "Déplacement" },
                    { label: "Safe" }
                ]
                selectedIndex: root.controller.tlpChargeMode === "deplacement" ? 0
                    : root.controller.tlpChargeMode === "safe" ? 1 : -1
                enabled: !root.controller.tlpChargeCommandRunning
                onSelected: index => root.controller.setTlpChargeMode(
                    ["deplacement", "safe"][index])
            }

            LevelSlider {
                width: parent.width
                icon: "volume_up"
                value: controller.audio ? controller.audio.volume : 0
                maximumValue: 1
                enabled: controller.audio !== null
                unavailableText: "0%"
                onDragged: (value) => {
                    if (controller.audio)
                        controller.audio.volume = value
                }
            }

            LevelSlider {
                width: parent.width
                icon: "brightness_6"
                value: controller.brightness
                enabled: controller.brightnessStateKnown
                onDragged: (value) => controller.setBrightness(value)
            }

        }
    }
}
