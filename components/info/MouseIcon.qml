import QtQuick
import "../../theme"

Item {
    id: root

    property string highlight: ""

    implicitWidth: 24
    implicitHeight: 24
    width: implicitWidth
    height: implicitHeight

    Item {
        id: body
        anchors.centerIn: parent
        width: 14
        height: 20

        Canvas {
            id: buttons
            anchors.fill: parent
            antialiasing: true

            property string hl: root.highlight
            property color accent: Theme.accent

            onHlChanged: requestPaint()
            onAccentChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                if (hl !== "left" && hl !== "right")
                    return

                const inset = 1.5       
                const r = width / 2 - inset
                const left = inset
                const right = width - inset
                const top = inset
                const split = width / 2
                const bottom = 8     

                ctx.fillStyle = accent
                ctx.beginPath()
                if (hl === "left") {
                    ctx.moveTo(split, top)
                    ctx.lineTo(split, bottom)
                    ctx.lineTo(left, bottom)
                    ctx.lineTo(left, top + r)
                    ctx.arc(left + r, top + r, r, Math.PI, Math.PI * 1.5, false)
                } else {
                    ctx.moveTo(split, top)
                    ctx.arc(right - r, top + r, r, Math.PI * 1.5, 0, false)
                    ctx.lineTo(right, bottom)
                    ctx.lineTo(split, bottom)
                }
                ctx.closePath()
                ctx.fill()
            }
        }

        Rectangle {
            x: 1.5; y: 8
            width: body.width - 3
            height: 1
            color: Theme.text
            opacity: 0.6
        }

        Rectangle {
            x: body.width / 2 - 0.5; y: 1.5
            width: 1
            height: 6.5
            color: Theme.text
            opacity: 0.6
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 1.5
            border.color: Theme.text
            opacity: 0.85
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 3
            width: 3
            height: 5
            radius: 1.5
            color: root.highlight === "middle" ? Theme.accent : Theme.text
            opacity: root.highlight === "middle" ? 1 : 0.7
        }
    }
}
