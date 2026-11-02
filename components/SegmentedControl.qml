import QtQuick
import "../theme"

Rectangle {
    id: root

    required property var options
    property int selectedIndex: 0
    property bool enabled: true
    property bool dragEnabled: false
    property int dragIndex: -1

    readonly property int currentIndex: dragIndex >= 0 ? dragIndex : selectedIndex

    signal selected(int index)

    implicitHeight: 40
    height: 40
    radius: Theme.cornerRadius
    color: Theme.surface

    function indexFromX(x) {
        if (options.length === 0)
            return -1
        return Math.max(0, Math.min(options.length - 1,
            Math.floor(x / (width / options.length))))
    }

    Item {
        id: track
        anchors.fill: parent
        anchors.margins: 4
        clip: true

        Rectangle {
            width: track.width / root.options.length
            height: track.height
            radius: Theme.cornerRadius - 2
            color: Theme.accent
            visible: root.currentIndex >= 0 && root.currentIndex < root.options.length
            x: track.width / root.options.length * root.currentIndex

            Behavior on x {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
        }

        Repeater {
            model: root.options

            Item {
                required property int index
                required property var modelData

                x: track.width / root.options.length * index
                width: track.width / root.options.length
                height: track.height

                Row {
                    anchors.centerIn: parent
                    spacing: modelData.icon ? 5 : 0

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !!modelData.icon
                        text: modelData.icon || ""
                        color: root.currentIndex === index ? Theme.textOnAccent : Theme.text
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.iconSize - 2
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: root.currentIndex === index ? Theme.textOnAccent : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                        font.weight: root.currentIndex === index ? Font.DemiBold : Font.Normal
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.enabled && !root.dragEnabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selected(index)
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.enabled && root.dragEnabled
            cursorShape: Qt.PointingHandCursor

            onPressed: mouse => root.dragIndex = root.indexFromX(mouse.x)
            onPositionChanged: mouse => {
                if (pressed)
                    root.dragIndex = root.indexFromX(mouse.x)
            }
            onReleased: mouse => {
                const index = root.indexFromX(mouse.x)
                root.dragIndex = -1
                root.selected(index)
            }
            onCanceled: root.dragIndex = -1
        }
    }
}
