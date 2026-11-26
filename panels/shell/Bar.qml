import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../../theme"
import "../../panels/services"
import "../../panels/notifications"
import "../apps"
import "../controls"
import "../controls/ControlCenter/services"
import "left"
import "center"
import "right"

Scope {
    id: barRoot
    required property bool barVisible
    required property var launcherControl
    required property var wallpaperPicker
    required property var controller
    required property var notificationController
    property var performanceSource: performance
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

    PerformanceService {
        id: performance
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            id: panelWindow
            property bool trayPopupOpen: false
            property bool historyOpen: false
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

            BarLeft {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.leftMargin: 5
                hostBar: barRoot
                screenName: modelData.name
            }

            BarCenter {
                id: clockBlock
                anchors.centerIn: parent
                hostBar: barRoot
                weatherService: weather
                systemClock: clock
                weatherOpen: panelWindow.weatherOpen
                onCalendarClicked: {
                    panelWindow.weatherOpen = false
                    panelWindow.calendarOpen = !panelWindow.calendarOpen
                }
                onWeatherClicked: {
                    panelWindow.calendarOpen = false
                    panelWindow.weatherOpen = !panelWindow.weatherOpen
                }
            }

            BarRight {
                id: rightBlock
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 5
                hostBar: barRoot
                trayOpen: panelWindow.trayPopupOpen
                historyOpen: panelWindow.historyOpen
                onTrayClicked: panelWindow.trayPopupOpen = !panelWindow.trayPopupOpen
                onHistoryClicked: panelWindow.historyOpen = !panelWindow.historyOpen
            }

            SystemTrayPanel {
                anchorItem: rightBlock.trayAnchor
                open: panelWindow.trayPopupOpen
                barVisible: barRoot.barVisible
                onCloseRequested: panelWindow.trayPopupOpen = false
            }

            NotificationHistoryPanel {
                anchorItem: rightBlock.historyAnchor
                notificationController: barRoot.notificationController
                open: panelWindow.historyOpen
                barVisible: barRoot.barVisible
                onCloseRequested: panelWindow.historyOpen = false
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
                    anchorItem: clockBlock.weatherAnchor
                    service: weather
                    onClosed: panelWindow.weatherOpen = false
                }
            }
        }
    }
}
