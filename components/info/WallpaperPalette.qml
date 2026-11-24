import QtQuick
import "../../theme"

Item {
    id: root

    required property var colors
    required property var labels
    property bool preview: false

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacing
        spacing: 5

        Row {
            width: parent.width
            height: 16

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Palette"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                font.weight: Font.DemiBold
            }

            Item {
                width: parent.width - stateLabel.implicitWidth - 8
                height: 1
            }

            Text {
                id: stateLabel
                anchors.verticalCenter: parent.verticalCenter
                text: root.preview ? "APERÇU" : "THÈME ACTUEL"
                color: root.preview ? Theme.accent : Theme.text
                opacity: root.preview ? 1 : 0.65
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 4
                font.weight: Font.DemiBold
            }
        }

        Row {
            width: parent.width
            spacing: Theme.spacing

            Repeater {
                model: root.colors

                Item {
                    required property var modelData
                    width: Math.min(58, (parent.width - Theme.spacing * 4) / 5)
                    height: 38

                    Column {
                        anchors.fill: parent
                        spacing: 3

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 30
                            height: 18
                            radius: 5
                            color: modelData.color
                            border.width: 1
                            border.color: Qt.rgba(
                                Theme.text.r,
                                Theme.text.g,
                                Theme.text.b,
                                0.18
                            )
                        }

                        Text {
                            width: parent.width
                            text: root.labels[modelData.key] || modelData.key
                            color: Theme.text
                            opacity: 0.78
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 4
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
