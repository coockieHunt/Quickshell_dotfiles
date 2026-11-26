import QtQuick
import "../../../components"
import "../../../components/action"
import "../../../components/info"
import "../../../theme"
import "../../apps"

BarBlock {
    id: root

    required property var hostBar
    required property var weatherService
    required property var systemClock
    property bool weatherOpen: false
    readonly property Item weatherAnchor: weatherButton
    signal calendarClicked()
    signal weatherClicked()

    width: clockText.implicitWidth
        + (ecoBadge.visible ? ecoBadge.implicitWidth + 8 : 0)
        + (root.hostBar.controller.powerProfile === "performance" ? performanceBadge.implicitWidth + 8 : 0)
        + Theme.margin * 2
    borderColor: Theme.superHighlightEnabled && root.hostBar.superHeld
        ? Theme.accent
        : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)

    Behavior on border.color {
        ColorAnimation { duration: 120 }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.calendarClicked()
    }

    Row {
        id: clockText
        anchors.centerIn: parent
        height: parent.height
        spacing: 4

        Item {
            id: weatherButton
            visible: root.weatherService.available
            width: weatherContent.implicitWidth + 10
            height: parent.height

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: Theme.buttonSize + 4
                radius: Theme.cornerRadius
                color: weatherMouse.containsMouse || root.weatherOpen
                    ? Theme.buttonHover : "transparent"
            }

            Row {
                id: weatherContent
                anchors.centerIn: parent
                spacing: 4

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.weatherService.icon
                    color: Theme.accent
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.iconSize
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.weatherService.temperatureText
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
                onClicked: root.weatherClicked()
            }
        }

        BarSeparator {
            visible: root.weatherService.available
            height: parent.height
        }

        Text {
            height: parent.height
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            verticalAlignment: Text.AlignVCenter
            text: root.systemClock.date.toLocaleString(Qt.locale("fr_FR"), "ddd")
        }

        Text {
            height: parent.height
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            verticalAlignment: Text.AlignVCenter
            text: Qt.formatDateTime(root.systemClock.date, "d")
        }

        Text {
            height: parent.height
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            verticalAlignment: Text.AlignVCenter
            text: root.systemClock.date.toLocaleString(Qt.locale("fr_FR"), "MMM")
        }

        Text {
            height: parent.height
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            verticalAlignment: Text.AlignVCenter
            text: Qt.formatDateTime(root.systemClock.date, "HH:mm")
        }

        BarSeparator {
            visible: ecoBadge.visible || performanceBadge.visible
                || caffeineButton.visible || airplaneButton.visible
            height: parent.height
        }

        StatusBadge {
            id: ecoBadge
            visible: root.hostBar.controller.ecoModeActive
                || root.hostBar.controller.powerProfile === "power-saver"
            icon: "eco"
            label: "ÉCO"
            tooltipTitle: "Mode Économie"
            tooltipText: "Consommation réduite.\nClic pour revenir au mode équilibré."
            onClicked: root.hostBar.controller.returnToBalancedProfile()
        }

        StatusBadge {
            id: performanceBadge
            visible: root.hostBar.controller.powerProfile === "performance"
            icon: "bolt"
            label: "MAX"
            tooltipTitle: "Mode Performance"
            tooltipText: "Performances maximales.\nClic pour revenir au mode équilibré."
            onClicked: root.hostBar.controller.returnToBalancedProfile()
        }

        BarButton {
            id: caffeineButton
            anchors.verticalCenter: parent.verticalCenter
            visible: root.hostBar.controller.caffeineEnabled
            label: "coffee"
            iconColor: Theme.accent
            tooltip: "Mode Caféine\nLa mise en veille est bloquée.\nClic pour désactiver."
            onClicked: root.hostBar.controller.caffeineEnabled = false
        }

        BarButton {
            id: airplaneButton
            anchors.verticalCenter: parent.verticalCenter
            visible: root.hostBar.controller.airplaneEnabled
            label: "airplanemode_active"
            iconColor: Theme.accent
            tooltip: "Mode Avion\nWi-Fi et Bluetooth désactivés.\nClic pour désactiver."
            onClicked: root.hostBar.controller.toggleAirplane()
        }


        BarSeparator {
            visible: mediaWidget.visible
            height: parent.height
        }

        MediaWidget {
            id: mediaWidget
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
