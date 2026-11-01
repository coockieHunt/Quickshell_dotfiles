// Used by: 1 file(s)
import QtQuick
import "../theme"

Item {
    id: root

    required property string label
    required property real value         
    property bool available: true
    readonly property real boundedValue: Math.max(0, Math.min(100, value))

    implicitWidth: 96
    implicitHeight: 200

    component Labels: Item {
        property color textColor

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            spacing: -2

            Text {
                text: root.available ? `${Math.round(root.boundedValue)}%` : "--"
                color: textColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 4
                font.weight: Font.Bold
            }

            Text {
                text: root.label
                color: textColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.DemiBold
            }
        }
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: Theme.cornerRadius + 4
        color: Theme.surface
        clip: true

        Labels {
            anchors.fill: parent
            textColor: Theme.text
        }

        Rectangle {
            id: fill
            anchors.bottom: parent.bottom
            width: parent.width
            height: root.available ? parent.height * root.boundedValue / 100 : 0
            radius: track.radius
            color: Theme.accent
            clip: true

            Behavior on height {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            Labels {
                anchors.bottom: parent.bottom
                width: parent.width
                height: track.height
                textColor: Theme.componentBackground
            }
        }
    }
}