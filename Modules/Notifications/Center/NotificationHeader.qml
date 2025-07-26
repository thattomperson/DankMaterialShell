import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root

    width: parent.width
    height: 32

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingXS

        Text {
            text: "Notifications"
            font.pixelSize: Theme.fontSizeLarge
            color: Theme.surfaceText
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }

        DankActionButton {
            iconName: Prefs.doNotDisturb ? "notifications_off" : "notifications"
            iconColor: Prefs.doNotDisturb ? Theme.error : Theme.surfaceText
            buttonSize: 28
            anchors.verticalCenter: parent.verticalCenter
            onClicked: Prefs.setDoNotDisturb(!Prefs.doNotDisturb)
        }
    }

    Rectangle {
        id: clearAllButton
        width: 120
        height: 28
        radius: Theme.cornerRadiusLarge
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: NotificationService.notifications.length > 0
        color: clearArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
        border.color: clearArea.containsMouse ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
        border.width: 1

        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingXS

            DankIcon {
                name: "delete_sweep"
                size: Theme.iconSizeSmall
                color: clearArea.containsMouse ? Theme.primary : Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "Clear All"
                font.pixelSize: Theme.fontSizeSmall
                color: clearArea.containsMouse ? Theme.primary : Theme.surfaceText
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }

        }

        MouseArea {
            id: clearArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: NotificationService.clearAllNotifications()
        }

        Behavior on color {
            ColorAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }

        }

        Behavior on border.color {
            ColorAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }

        }

    }

}
