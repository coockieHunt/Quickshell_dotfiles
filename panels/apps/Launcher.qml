import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../../components"
import "../../components/action"
import "../../theme"

PanelWindow {
    id: root
    visible: false

    function toggle() { visible = !visible }

    function openWebSearch() {
        if (search.text.trim().length > 0) {
            Quickshell.execDetached([
                "xdg-open",
                Theme.launcherSearchUrl.replace(
                    /\{query\}/g,
                    encodeURIComponent(search.text.trim())
                )
            ])
            root.visible = false
        }
    }


    property var results: {
        if (desktopEntryParser.status !== Loader.Ready)
            return []
        return desktopEntryParser.item.filterApplications(
            DesktopEntries.applications.values, search.text)
    }
    property bool detailsVisible: false
    readonly property int detailsWidth: 280
    readonly property var selectedEntry: list.currentIndex >= 0
        && list.currentIndex < results.length ? results[list.currentIndex] : null

    onVisibleChanged: {
        if (visible) {
            search.text = ""
            search.forceActiveFocus()
        }
    }

    implicitWidth: 500
    implicitHeight: 420
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle() }
    }

    Loader {
        id: desktopEntryParser
        source: Qt.resolvedUrl("../../services/DesktopEntryParser.qml")
    }

    ModalBackdrop {
        anchors.fill: parent
        onDismissed: root.visible = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: root.implicitWidth + (root.detailsVisible ? root.detailsWidth : 0)
        height: root.implicitHeight
        radius: Theme.cornerRadius
        color: Qt.rgba(
            Theme.componentBackground.r * 0.97 + Theme.accent.r * 0.03,
            Theme.componentBackground.g * 0.97 + Theme.accent.g * 0.03,
            Theme.componentBackground.b * 0.97 + Theme.accent.b * 0.03,
            Theme.componentBackground.a
        )
        border.color: Theme.componentBorder
        border.width: 1

        Rectangle {
            id: launcherPanel
            width: root.implicitWidth
            height: root.implicitHeight
            anchors.left: parent.left
            color: "transparent"
            border.width: 0

            MouseArea {
                anchors.fill: parent
            }

            Column {
                anchors.fill: parent
                anchors.margins: Theme.margin
                spacing: Theme.spacing

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: Theme.cornerRadius
                    color: Theme.componentSurface

                    TextInput {
                        id: search
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 52
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize

                        Keys.onEscapePressed: root.visible = false
                        Keys.onDownPressed: list.incrementCurrentIndex()
                        Keys.onUpPressed: list.decrementCurrentIndex()
                        Keys.onReturnPressed: {
                            if (root.selectedEntry) {
                                root.selectedEntry.execute()
                                root.visible = false
                            } else {
                                root.openWebSearch()
                            }
                        }

                        onTextChanged: list.currentIndex = 0
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: search.text.length > 0 ? 30 : 38
                        height: 22
                        radius: Theme.cornerRadius
                        color: Theme.componentSurface

                    Text {
                        anchors.centerIn: parent
                        text: search.text.trim().length === 0 ? "↑ ↓" : "travel_explore"
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.65)
                        font.family: search.text.trim().length === 0
                            ? Theme.fontFamily : Theme.iconFont
                        font.pixelSize: search.text.trim().length === 0
                            ? Theme.fontSize - 1 : Theme.iconSize
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: search.text.trim().length > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openWebSearch()
                    }


                    }

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 52
                        verticalAlignment: Text.AlignVCenter
                        text: "Rechercher une application..."
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        visible: search.text.length === 0
                        enabled: false
                    }
                }

        ListView {
            id: list
            width: parent.width
            height: parent.height - 36 - 18 - Theme.spacing * 2
            clip: true
            model: root.results
            currentIndex: 0

            Text {
                anchors.centerIn: parent
                width: parent.width - 32
                visible: search.text.trim().length > 0
                    && root.results.length === 0
                text: "0 trouvée\nAppuyez sur Entrée pour chercher sur Internet"
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.65)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                z: 1
            }

            delegate: Rectangle {
                required property var modelData
                required property int index
                property bool selected: ListView.isCurrentItem

                width: list.width
                height: 36
                radius: Theme.cornerRadius
                color: selected
                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
                    : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    spacing: 10

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22
                        height: 22
                        source: Quickshell.iconPath(
                            modelData.icon,
                            "application-x-executable"
                        )
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: list.currentIndex = index

                    onClicked: {
                        list.currentIndex = index
                        modelData.execute()
                        root.visible = false
                    }
                }
            }
        }


                Row {
                    width: parent.width
                    height: 20
                    spacing: Theme.spacing / 2

                    Text {
                        width: parent.width - countLabel.implicitWidth
                            - detailsButton.width - desktopFolderButton.width - parent.spacing * 3
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        text: root.selectedEntry ? root.selectedEntry.id : ""
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                    }

                    Text {
                        id: countLabel
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        text: root.results.length + (root.results.length === 1 ? " application" : " applications")
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                    }

                    BarButton {
                        id: detailsButton
                        width: 20
                        height: 20
                        label: "info"
                        tooltip: root.detailsVisible ? "Masquer les détails" : "Afficher les détails"
                        highlighted: root.detailsVisible
                        onClicked: root.detailsVisible = !root.detailsVisible
                    }

                    BarButton {
                        id: desktopFolderButton
                        width: 20
                        height: 20
                        label: "folder_open"
                        tooltip: "Ouvrir les lanceurs personnalisés"
                        onClicked: Quickshell.execDetached([
                            Theme.openUserAppsScript,
                            Theme.fileManagerApplication
                        ])
                    }
                }
            }
        }

        Rectangle {
            id: detailsPanel
            visible: root.detailsVisible
            anchors.left: launcherPanel.right
            width: root.detailsWidth
            height: launcherPanel.height
            color: "transparent"
            border.width: 0

            MouseArea {
                anchors.fill: parent
            }

            Column {
                anchors.fill: parent
                anchors.margins: Theme.margin
                spacing: Theme.spacing

                Row {
                    width: parent.width
                    height: 44
                    spacing: Theme.spacing

                    Image {
                        width: 32
                        height: 32
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: 0.62
                        source: root.selectedEntry
                            ? Quickshell.iconPath(root.selectedEntry.icon, "application-x-executable")
                            : ""
                    }

                    Text {
                        width: parent.width - 32 - parent.spacing
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        text: root.selectedEntry ? root.selectedEntry.name : "Aucune application"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        font.weight: Font.DemiBold
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.buttonHover
                }

                Flickable {
                    width: parent.width
                    height: parent.height - 44 - Theme.spacing * 2 - 1
                    contentHeight: detailsColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: detailsColumn
                        width: parent.width
                        spacing: Theme.spacing

                        Repeater {
                            model: root.selectedEntry && desktopEntryParser.status === Loader.Ready
                                ? desktopEntryParser.item.detailsFor(root.selectedEntry) : []

                            delegate: Column {
                                required property var modelData
                                width: detailsColumn.width
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: modelData.label
                                    color: Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 2
                                }

                                Text {
                                    width: parent.width
                                    text: modelData.value
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 1
                                    wrapMode: Text.Wrap
                                    textFormat: Text.PlainText
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: root.detailsVisible
            anchors {
                left: launcherPanel.right
                top: parent.top
                bottom: parent.bottom
            }
            width: 1
            color: Theme.componentBorder
        }
    }
}
