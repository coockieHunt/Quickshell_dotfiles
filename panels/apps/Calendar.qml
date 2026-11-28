import Quickshell
import QtQuick
import "../../theme"

PopupWindow {
    id: root

    required property Item anchorItem

    readonly property var locale: Qt.locale("fr_FR")
    property var today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()   

    readonly property int cellWidth: 34
    readonly property int cellHeight: 30
    readonly property int weekColumnWidth: 26
    readonly property var weekdayLabels: ["L", "M", "M", "J", "V", "S", "D"]
    readonly property bool onCurrentMonth:
        viewYear === today.getFullYear() && viewMonth === today.getMonth()

    function shiftMonth(delta) {
        const d = new Date(viewYear, viewMonth + delta, 1)
        viewYear = d.getFullYear()
        viewMonth = d.getMonth()
    }

    function goToToday() {
        viewYear = today.getFullYear()
        viewMonth = today.getMonth()
    }

    function cellDate(index) {
        const first = new Date(viewYear, viewMonth, 1)
        const offset = (first.getDay() + 6) % 7
        return new Date(viewYear, viewMonth, 1 - offset + index)
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate()
    }

    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
        const day = t.getUTCDay() || 7
        t.setUTCDate(t.getUTCDate() + 4 - day)
        const yearStart = new Date(Date.UTC(t.getUTCFullYear(), 0, 1))
        return Math.ceil(((t - yearStart) / 86400000 + 1) / 7)
    }

    function capitalize(s) {
        return s.length > 0 ? s.charAt(0).toUpperCase() + s.slice(1) : s
    }

    anchor.window: anchorItem.QsWindow.window
    anchor.adjustment: PopupAdjustment.None
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.onAnchoring: {
        const content = anchorItem.QsWindow.contentItem
        const pos = content.mapFromItem(
            anchorItem,
            anchorItem.width / 2 - root.width / 2,
            anchorItem.height
        )
        anchor.rect.x = Math.max(4, Math.min(pos.x, content.width - root.width - 4))
        anchor.rect.y = pos.y + Theme.dropdownGap
    }

    visible: true
    grabFocus: true
    color: "transparent"
    implicitWidth: weekColumnWidth + cellWidth * 7 + 24
    implicitHeight: content.implicitHeight + 24

    onVisibleChanged: {
        if (!visible)
            root.closed()
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Theme.componentBackground
        border.width: 1
        border.color: Theme.componentBorder

        WheelHandler {
            onWheel: event => root.shiftMonth(event.angleDelta.y > 0 ? -1 : 1)
        }

        Column {
            id: content
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Item {
                width: parent.width
                height: 30

                Rectangle {
                    id: prevButton
                    anchors.left: parent.left
                    width: 30
                    height: 30
                    radius: Theme.cornerRadius
                    color: prevMouse.containsMouse ? Theme.buttonHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "chevron_left"
                        color: Theme.text
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.iconSize
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shiftMonth(-1)
                    }
                }

                Rectangle {
                    anchors.left: prevButton.right
                    anchors.right: nextButton.left
                    anchors.margins: 4
                    height: 30
                    radius: Theme.cornerRadius
                    color: titleMouse.containsMouse && !root.onCurrentMonth
                        ? Theme.buttonHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: root.capitalize(root.locale.monthName(root.viewMonth, Locale.LongFormat))
                            + " " + root.viewYear
                        color: root.onCurrentMonth ? Theme.text : Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: titleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: root.onCurrentMonth ? Qt.ArrowCursor : Qt.PointingHandCursor
                        onClicked: root.goToToday()
                    }
                }

                Rectangle {
                    id: nextButton
                    anchors.right: parent.right
                    width: 30
                    height: 30
                    radius: Theme.cornerRadius
                    color: nextMouse.containsMouse ? Theme.buttonHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "chevron_right"
                        color: Theme.text
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.iconSize
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shiftMonth(1)
                    }
                }
            }

            Row {
                Item {
                    width: root.weekColumnWidth
                    height: 20

                    Text {
                        anchors.centerIn: parent
                        text: "S"
                        color: Theme.text
                        opacity: 0.4
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 3
                    }
                }

                Repeater {
                    model: root.weekdayLabels

                    Item {
                        required property string modelData
                        width: root.cellWidth
                        height: 20

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: Theme.text
                            opacity: 0.6
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 3
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }

            Row {
                Column {
                    width: root.weekColumnWidth

                    Repeater {
                        model: 6

                        Item {
                            required property int index
                            width: root.weekColumnWidth
                            height: root.cellHeight

                            Text {
                                anchors.centerIn: parent
                                text: root.isoWeek(root.cellDate(index * 7))
                                color: Theme.text
                                opacity: 0.4
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 3
                            }
                        }
                    }
                }

                Grid {
                    columns: 7

                    Repeater {
                        model: 42

                        Rectangle {
                            id: cell
                            required property int index
                            readonly property var date: root.cellDate(index)
                            readonly property bool inMonth: date.getMonth() === root.viewMonth
                            readonly property bool isToday: root.sameDay(date, root.today)

                            width: root.cellWidth
                            height: root.cellHeight
                            radius: Theme.cornerRadius
                            color: isToday
                                ? Theme.accent
                                : cellMouse.containsMouse ? Theme.buttonHover : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: cell.date.getDate()
                                color: cell.isToday ? Theme.textOnAccent : Theme.text
                                opacity: cell.inMonth || cell.isToday ? 1 : 0.35
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.weight: cell.isToday ? Font.DemiBold : Font.Normal
                            }

                            MouseArea {
                                id: cellMouse
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.capitalize(
                    root.today.toLocaleString(root.locale, "dddd d MMMM yyyy"))
                color: Theme.text
                opacity: 0.6
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
            }
        }
    }
}
