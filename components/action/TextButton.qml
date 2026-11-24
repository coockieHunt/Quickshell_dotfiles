import QtQuick
import "../../theme"

Rectangle {
    id: root

    property string text: "Button"
    property string icon: ""
    property bool highlighted: false
    property bool warning: false
    property string keycap: ""
    property color buttonColor: Theme.accent
    property color textColor: Theme.text
    property color borderColor: Theme.componentBorder
    property color hoverColor: Theme.buttonHover
    property real tint: 0.08
    property bool stretched: false
    property int spacing: 8
    property real paddingH: Theme.margin
    property real paddingV: 0
    property int contentHeight: 30

    property color filledTextColor: Theme.textOnAccent

    readonly property bool filled: (root.warning || root.highlighted) && root.tint >= 1.0
    readonly property color contentColor: root.filled
        ? root.filledTextColor
        : (root.warning || root.highlighted ? root.buttonColor : root.textColor)

    signal clicked()

    implicitWidth: contentRow.implicitWidth + root.paddingH * 2
    implicitHeight: root.contentHeight + root.paddingV * 2
    radius: Theme.cornerRadius
    border.width: 1
    border.color: {
        if (root.warning || root.highlighted)
            return Qt.rgba(root.buttonColor.r, root.buttonColor.g, root.buttonColor.b, 0.5)
        return root.borderColor
    }
    color: {
        if (root.warning || root.highlighted) {
            const base = mouse.containsMouse ? 0.25 : root.tint
            const extra = mouse.pressed ? 0.1 : 0
            return Qt.rgba(root.buttonColor.r, root.buttonColor.g, root.buttonColor.b, base + extra)
        }
        if (mouse.pressed)
            return Qt.darker(root.hoverColor, 1.1)
        return mouse.containsMouse ? root.hoverColor : Theme.componentSurface
    }

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: root.spacing
        visible: !root.stretched

        Text {
            visible: root.icon !== ""
            text: root.icon
            color: root.contentColor
            font.family: Theme.iconFont
            font.pixelSize: Theme.iconSize
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.text
            color: root.contentColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }

        KeyCap {
            visible: root.keycap !== ""
            keyText: root.keycap
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Item {
        anchors.fill: parent
        visible: root.stretched

        Row {
            id: stretchedRow
            anchors.left: parent.left
            anchors.leftMargin: root.paddingH
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.spacing

            Text {
                visible: root.icon !== ""
                text: root.icon
                color: root.contentColor
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconSize
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.text
                color: root.contentColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        KeyCap {
            visible: root.keycap !== ""
            keyText: root.keycap
            anchors.right: parent.right
            anchors.rightMargin: root.paddingH
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
