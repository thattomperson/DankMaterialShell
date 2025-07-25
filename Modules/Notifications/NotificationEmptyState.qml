import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root
    
    width: parent.width
    height: 200
    visible: NotificationService.notifications.length === 0

    Column {
        anchors.centerIn: parent
        spacing: Theme.spacingM
        width: parent.width * 0.8

        DankIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "notifications_none"
            size: Theme.iconSizeLarge + 16
            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.3)
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No notifications"
            font.pixelSize: Theme.fontSizeLarge
            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.6)
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Notifications will appear here"
            font.pixelSize: Theme.fontSizeMedium
            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.4)
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }
}