import QtQuick
import "../../theme"
import "../../components/action"

Item {
    id: root

    property bool opened: false
    property string title: "Confirmer l’action"
    property string message: ""
    property string cancelText: "Annuler"
    property string confirmText: "Confirmer"

    signal confirmed()
    signal cancelled()

    anchors.fill: parent
    visible: opened
    z: 10

    focus: opened
    activeFocusOnTab: true

    function confirm() {
        if (root.opened)
            root.confirmed()
    }

    function cancel() {
        if (root.opened)
            root.cancelled()
    }

    Keys.onReturnPressed: root.confirm()
    Keys.onEnterPressed: root.confirm()
    Keys.onEscapePressed: root.cancel()

    onOpenedChanged: {
        if (opened)
            forceActiveFocus()
    }

    Rectangle {
        anchors.fill: parent
        color: "#99000000"
        opacity: root.opened ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 160 }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: root.cancel()
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - 36, 400)
        height: dialogContent.implicitHeight + 48
        radius: Theme.cornerRadius
        color: Theme.componentBackground
        border.color: Theme.componentBorder
        border.width: 1

        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.94

        Behavior on opacity {
            NumberAnimation { duration: 160 }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Column {
            id: dialogContent
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            Text {
                width: parent.width
                text: root.title
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 5
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
            }

            Text {
                width: parent.width
                text: root.message
                color: Theme.text
                opacity: 0.8
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                wrapMode: Text.WordWrap
            }

            Row {
                width: parent.width
                spacing: 10

                TextButton {
                    width: (parent.width - parent.spacing) / 2
                    height: 44
                    stretched: true
                    paddingH: Theme.margin * 0.75
                    text: root.cancelText
                    keycap: "Esc"
                    onClicked: root.cancel()
                }

                TextButton {
                    width: (parent.width - parent.spacing) / 2
                    height: 44
                    stretched: true
                    paddingH: Theme.margin * 0.75
                    highlighted: true
                    text: root.confirmText
                    keycap: "↵"
                    onClicked: root.confirm()
                }
            }
        }
    }
}
