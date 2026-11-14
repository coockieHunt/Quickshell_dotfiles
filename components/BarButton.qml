// Used by: 5 file(s)
import QtQuick
import "../theme"

Rectangle {
    id: root
    property string label: ""
    property string iconFont: Theme.iconFont
    property string tooltip: ""
    property int iconSize: Theme.iconSize
    property bool highlighted: false
    property color idleColor: highlighted ? Theme.accent : "transparent"
    property color hoverColor: "transparent"
    property color iconColor: highlighted ? Theme.textOnAccent : Theme.text
    property color hoverIconColor: Theme.accent
    readonly property bool hovered: mouse.containsMouse
    signal clicked()
    signal rightClicked()
    signal middleClicked()

    width: Theme.buttonSize
    height: Theme.buttonSize
    radius: Theme.cornerRadius
    color: mouse.containsMouse ? hoverColor : idleColor

    PopupTooltip {
        anchorItem: root
        text: root.tooltip
        shown: mouse.containsMouse
    }

    Text {
        anchors.centerIn: parent
        text: root.label
        color: mouse.containsMouse ? root.hoverIconColor : root.iconColor
        font.family: root.iconFont
        font.pixelSize: root.iconSize

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked()
            else if (mouse.button === Qt.MiddleButton)
                root.middleClicked()
            else
                root.clicked()
        }
    }
}
