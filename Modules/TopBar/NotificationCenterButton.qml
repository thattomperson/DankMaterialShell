import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property bool hasUnread: false
    property bool isActive: false

    signal clicked()

    width: 40
    height: 30
    radius: Theme.cornerRadius
    color: {
        const baseColor = notificationArea.containsMouse || root.isActive ? Theme.primaryPressed : Theme.secondaryHover;
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, baseColor.a * Theme.widgetTransparency);
    }

    DankIcon {
        anchors.centerIn: parent
        name: Prefs.doNotDisturb ? "notifications_off" : "notifications"
        size: Theme.iconSize - 6
        color: Prefs.doNotDisturb ? Theme.error : (notificationArea.containsMouse || root.isActive ? Theme.primary : Theme.surfaceText)
    }

    // Notification dot indicator
    Rectangle {
        width: 8
        height: 8
        radius: 4
        color: Theme.error
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 6
        anchors.topMargin: 6
        visible: root.hasUnread
    }

    MouseArea {
        id: notificationArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.clicked();
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing
        }

    }

}
