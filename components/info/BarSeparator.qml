import QtQuick
import "../../theme"

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
