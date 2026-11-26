import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import "../notifications"

Scope {
    id: root
    property bool panelOpen: false
    property var history: []
    property double notificationMuteUntil: 0
    property int muteClockTick: 0
    property string muteMessage: ""
    readonly property int notificationCount: history.length
    readonly property bool notificationsMuted: notificationMuteUntil === -1
        || notificationMuteUntil > Date.now()
    readonly property string muteTimeRemaining: {
        muteClockTick
        if (notificationMuteUntil === -1)
            return "∞"
        const seconds = Math.max(0, Math.ceil((notificationMuteUntil - Date.now()) / 1000))
        if (seconds >= 3600)
            return Math.floor(seconds / 3600) + " h " + Math.floor((seconds % 3600) / 60) + " min"
        return Math.max(1, Math.ceil(seconds / 60)) + " min"
    }

    function removeHistoryNotification(index) {
        const updatedHistory = history.slice()
        const entry = updatedHistory[index]
        if (!entry)
            return
        if (entry.notification?.tracked)
            entry.notification.dismiss()
        updatedHistory.splice(index, 1)
        history = updatedHistory
    }

    function setNotificationMute(durationMs) {
        muteTimer.stop()
        notificationMuteUntil = durationMs < 0
            ? -1 : durationMs === 0 ? 0 : Date.now() + durationMs
        if (durationMs > 0) {
            muteTimer.interval = durationMs
            muteTimer.start()
        }
        if (notificationsMuted) {
            for (const notification of server.trackedNotifications.values)
                notification.dismiss()
        }
    }

    function cancelNotificationMute() {
        setNotificationMute(0)
        muteMessage = "Sourdine annulée"
        muteMessageTimer.restart()
    }

    Timer {
        id: muteTimer
        onTriggered: root.notificationMuteUntil = 0
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.notificationMuteUntil > 0
        onTriggered: {
            root.muteClockTick++
            if (root.notificationMuteUntil > 0 && Date.now() >= root.notificationMuteUntil)
                root.notificationMuteUntil = 0
        }
    }

    Timer {
        id: muteMessageTimer
        interval: 2500
        onTriggered: root.muteMessage = ""
    }

    NotificationServer {
        id: server
        bodySupported: true
        imageSupported: true
        keepOnReload: false

        onNotification: notif => {
            root.history = [{
                appName: notif.appName || "Notification",
                summary: notif.summary || "",
                body: notif.body || "",
                receivedAt: Qt.formatDateTime(new Date(), "HH:mm"),
                notification: notif
            }, ...root.history].slice(0, 20)
            if (!root.notificationsMuted || notif.urgency === NotificationUrgency.Critical)
                notif.tracked = true
        }
    }

    NotificationToastWindow {
        notifications: server.trackedNotifications
        panelOpen: root.panelOpen
    }
}
