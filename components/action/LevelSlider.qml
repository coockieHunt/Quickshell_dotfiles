import QtQuick
import QtQuick.Controls
import "../../theme"

Row {
    id: root

    required property string icon
    required property real value
    property real maximumValue: 1
    property string unavailableText: "—"

    property bool iconClickable: false
    property bool iconDimmed: false

    signal dragged(real value)
    signal iconClicked()

    height: 28
    spacing: 2

    TextMetrics {
        id: barMetrics

        font.family: Theme.monoFont
        font.pixelSize: 12
        text: "-"
    }

    Item {
        id: iconArea
        width: 22
        height: parent.height

        Text {
            id: iconText
            anchors.fill: parent
            text: root.icon
            color: Theme.text
            opacity: root.iconDimmed ? 0.45 : (iconMouse.containsMouse && root.iconClickable ? 0.7 : 1.0)
            font.family: Theme.iconFont
            font.pixelSize: Theme.iconSize
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }
        }

        MouseArea {
            id: iconMouse
            anchors.fill: parent
            enabled: root.iconClickable
            hoverEnabled: root.iconClickable
            cursorShape: root.iconClickable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.iconClicked()
        }
    }

    Slider {
        id: slider

        width: root.width - 22 - valueLabel.width - root.spacing * 2
        height: root.height
        from: 0
        to: root.maximumValue
        value: root.value
        enabled: root.enabled
        padding: 0
        onMoved: root.dragged(value)

        background: Item {
            x: slider.leftPadding
            y: slider.topPadding
            width: slider.availableWidth
            height: slider.availableHeight
            clip: true

            Text {
                anchors.fill: parent
                text: "-".repeat(Math.ceil(slider.availableWidth / barMetrics.advanceWidth))
                color: Theme.componentSurface
                font.family: Theme.monoFont
                font.pixelSize: 12
                font.bold: true
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }

            Item {
                width: parent.width * slider.visualPosition
                height: parent.height
                clip: true

                Text {
                    width: slider.availableWidth
                    height: parent.height
                    text: "#".repeat(Math.ceil(slider.availableWidth / barMetrics.advanceWidth))
                    color: Theme.accent
                    opacity: root.iconDimmed ? 0.45 : 1.0
                    font.family: Theme.monoFont
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        handle: Item {
            implicitWidth: 1
            implicitHeight: 1
        }
    }

    Text {
        id: valueLabel

        width: 38
        height: parent.height
        text: root.enabled ? Math.round(slider.value * 100) + "%" : root.unavailableText
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 1
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignRight
    }
}
