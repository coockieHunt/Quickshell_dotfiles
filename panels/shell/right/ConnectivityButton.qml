import QtQuick
import "../../../components/action"
import "../../../components/tooltip"
import "../../../theme"

Item {
    id: root

    property string icon: ""
    property string title: ""
    property bool stateKnown: false
    property bool stateEnabled: false
    property string detail: ""
    property string emptyDetail: ""
    signal clicked()
    signal rightClicked()

    width: Theme.buttonSize
    height: Theme.buttonSize

    BarButton {
        id: button
        anchors.fill: parent
        label: root.icon
        onClicked: root.clicked()
        onRightClicked: root.rightClicked()
    }

    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        width: 7
        height: 7
        radius: width / 2
        color: Theme.accent
        visible: root.stateKnown && root.stateEnabled
        border.width: 1
        border.color: Theme.componentBackground
        z: 1
    }

    ConnectivityTooltip {
        anchorItem: button
        shown: button.hovered
        title: root.title
        icon: root.icon
        status: !root.stateKnown
            ? "Lecture…"
            : root.stateEnabled ? "Activé" : "Désactivé"
        detail: !root.stateKnown || !root.stateEnabled
            ? ""
            : root.detail || root.emptyDetail
    }
}
