// Used by: 0 file(s)
import QtQuick
import "../theme"

Item {
    id: root

    property var controller: null

    readonly property int steps: 3
    readonly property var labels: ["Éco", "Équilibré", "Performance"]
    readonly property var icons: ["󰾬", "󰾅", "󰓅"]

    readonly property int committed: controller ? controller.powerProfile : 1
    property int dragIndex: -1
    readonly property int current: dragIndex >= 0 ? dragIndex : committed
    readonly property real fraction: (current + 0.5) / steps

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
                text: root.icons[root.current]
                color: textColor
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconSize + 4
            }

            Text {
                text: root.labels[root.current]
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

        Repeater {
            model: root.steps
            Rectangle {
                y: track.height * (1 - (index + 0.5) / root.steps) - height / 2
                anchors.right: parent.right
                anchors.rightMargin: 8
                width: 14
                height: 3
                radius: 2
                color: Theme.text
                opacity: root.current === index ? 0.0 : 0.35
            }
        }

        Rectangle {
            id: fill
            anchors.bottom: parent.bottom
            width: parent.width
            height: parent.height * root.fraction
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

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 8
                width: 36
                height: 4
                radius: 2
                color: Theme.componentBackground
                opacity: 0.7
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        function indexFromY(y) {
            const ratio = 1 - Math.max(0, Math.min(height, y)) / height
            return Math.max(0, Math.min(root.steps - 1, Math.floor(ratio * root.steps)))
        }

        onPressed: mouse => root.dragIndex = indexFromY(mouse.y)
        onPositionChanged: mouse => {
            if (pressed)
                root.dragIndex = indexFromY(mouse.y)
        }
        onReleased: {
            const idx = root.dragIndex
            root.dragIndex = -1
            if (idx >= 0 && idx !== root.committed && root.controller)
                root.controller.setPowerProfile(idx)
        }
        onCanceled: root.dragIndex = -1
    }
}