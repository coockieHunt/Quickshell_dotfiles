import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../../../components"
import "../../../theme"
import "services"

Scope {
    id: root

    property bool panelOpen: false
    property string panelMode: "notifications"
    property var macroControl: null
    property var performanceControl: null

    NetworkService { id: network }
    AudioService { id: audioService }
    BrightnessService { id: brightnessService }

    PowerService {
        id: power
        brightnessService: brightnessService
    }

    readonly property bool wifiEnabled: network.wifiEnabled
    readonly property bool bluetoothEnabled: network.bluetoothEnabled
    readonly property string wifiNetworkName: network.wifiNetworkName
    readonly property string bluetoothConnectedNames: network.bluetoothConnectedNames
    readonly property bool wifiStateKnown: network.wifiStateKnown
    readonly property bool bluetoothStateKnown: network.bluetoothStateKnown
    readonly property bool airplaneEnabled: network.airplaneEnabled

    readonly property bool soundMuted: audioService.soundMuted
    readonly property bool soundStateKnown: audioService.soundStateKnown
    readonly property var audio: audioService.audio

    readonly property real brightness: brightnessService.brightness
    readonly property bool brightnessStateKnown: brightnessService.brightnessStateKnown

    readonly property string powerProfile: power.powerProfile
    readonly property bool ecoModeActive: power.ecoModeActive
    readonly property string tlpChargeMode: power.tlpChargeMode
    readonly property bool tlpChargeCommandRunning: power.tlpChargeCommandRunning

    function togglePanel() {
        panelOpen = !panelOpen
        console.info("Control panel", panelOpen ? "opened" : "closed")
        if (panelOpen) {
            panelMode = Theme.controlPanelDefaultMode
            refreshQuickSettings()
        }
    }

    function showPanelMode(mode) {
        panelMode = mode
    }

    IpcHandler {
        target: "control-panel"
        function toggle(): void { root.togglePanel() }
        function show(): void {
            root.panelOpen = true
            root.panelMode = Theme.controlPanelDefaultMode
            root.refreshQuickSettings()
        }
        function hide(): void { root.panelOpen = false }
    }

    function refreshQuickSettings() {
        refreshNetworkStatus()
        audioService.refresh()
        brightnessService.refresh()
    }

    function refreshNetworkStatus() {
        network.refresh()
    }

    function toggleWifi() { network.toggleWifi() }
    function toggleBluetooth() { network.toggleBluetooth() }
    function toggleAirplane() { network.toggleAirplane() }
    function toggleSound() { audioService.toggleSound() }
    function setBrightness(value) { brightnessService.setBrightness(value) }

    function toggleEcoMode() { power.toggleEcoMode() }
    function handlePowerProfileSelected(profile) { power.handlePowerProfileSelected(profile) }
    function returnToBalancedProfile() { power.returnToBalancedProfile() }
    function setTlpChargeMode(mode) {
        panelOpen = false
        power.setTlpChargeMode(mode)
    }
    function refreshTlpChargeMode() { power.refreshTlpChargeMode() }

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.refreshNetworkStatus()
    }

    Timer {
        interval: 10000
        repeat: true
        running: root.panelOpen
        onTriggered: root.refreshQuickSettings()
    }

    Component.onCompleted: refreshNetworkStatus()

    PanelWindow {
        visible: root.panelOpen
        screen: Quickshell.screens[0]
        anchors { top: true; right: true; bottom: true; left: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "control-center"
        WlrLayershell.keyboardFocus: root.panelOpen
            ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        onVisibleChanged: {
            console.info("Control panel window visible:", visible)
            if (visible)
                keyHandler.forceActiveFocus()
        }

        Item {
            id: keyHandler
            anchors.fill: parent
            focus: root.panelOpen

            Keys.onPressed: event => {
                if (!root.panelOpen)
                    return
                if (event.key === Qt.Key_Up)
                    root.showPanelMode("both")
                else if (event.key === Qt.Key_Left)
                    root.showPanelMode("performance")
                else if (event.key === Qt.Key_Right)
                    root.showPanelMode("notifications")
                else
                    return
                event.accepted = true
            }
        }

        ModalBackdrop {
            anchors.fill: parent
            onDismissed: root.panelOpen = false
        }

        ControlCenter {
            anchors.fill: parent
            controller: root
        }

        PerformanceCenter {
            anchors.fill: parent
            controller: root
        }

        Rectangle {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 4
            }
            width: 312
            height: 36
            radius: Theme.cornerRadius
            color: Qt.rgba(
                Theme.componentBackground.r,
                Theme.componentBackground.g,
                Theme.componentBackground.b,
                0.82
            )
            border.width: 1
            border.color: Theme.buttonHover

            Row {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 2

                Repeater {
                    model: [
                        { mode: "performance", label: "Perf.", icon: "keyboard_arrow_left" },
                        { mode: "both", label: "Les deux", icon: "keyboard_arrow_up" },
                        { mode: "notifications", label: "Controlle", icon: "keyboard_arrow_right" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        width: (parent.width - parent.spacing * 2) / 3
                        height: parent.height
                        radius: Theme.cornerRadius
                        color: root.panelMode === modelData.mode
                            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                            : modeMouse.containsMouse
                                ? Qt.rgba(Theme.buttonHover.r, Theme.buttonHover.g, Theme.buttonHover.b, 0.55)
                                : "transparent"

                        Row {
                            anchors.centerIn: parent
                            height: parent.height
                            spacing: 2

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.icon
                                color: root.panelMode === modelData.mode ? Theme.accent : Theme.text
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.iconSize
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: root.panelMode === modelData.mode ? Theme.accent : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                                font.weight: root.panelMode === modelData.mode ? Font.DemiBold : Font.Normal
                            }
                        }

                        MouseArea {
                            id: modeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showPanelMode(modelData.mode)
                        }
                    }
                }
            }
        }
    }
}
