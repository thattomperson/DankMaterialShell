import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets

PanelWindow {
    id: root

    property bool notificationHistoryVisible: false

    visible: notificationHistoryVisible
    onNotificationHistoryVisibleChanged: {
        NotificationService.disablePopups(notificationHistoryVisible);
    }
    implicitWidth: 400
    implicitHeight: Math.min(Screen.height * 0.8, 400)
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            notificationHistoryVisible = false;
        }
    }

    Rectangle {
        id: mainRect

        function calculateHeight() {
            let baseHeight = Theme.spacingL * 2;
            baseHeight += notificationHeader.height;
            baseHeight += Theme.spacingM;
            let listHeight = notificationList.listContentHeight;
            if (NotificationService.groupedNotifications.length === 0)
                listHeight = 200;

            baseHeight += Math.min(listHeight, 600);
            return Math.max(300, baseHeight);
        }

        width: 400
        height: calculateHeight()
        x: Screen.width - width - Theme.spacingL
        y: Theme.barHeight + Theme.spacingXS
        color: Theme.popupBackground()
        radius: Theme.cornerRadiusLarge
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
        border.width: 1
        opacity: notificationHistoryVisible ? 1 : 0
        scale: notificationHistoryVisible ? 1 : 0.9

        MouseArea {
            anchors.fill: parent
            onClicked: {
            }
        }

        Column {
            id: contentColumn

            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            NotificationHeader {
                id: notificationHeader
            }

            NotificationList {
                id: notificationList

                width: parent.width
                height: parent.height - notificationHeader.height - contentColumn.spacing
            }

        }

        Connections {
            function onNotificationsChanged() {
                mainRect.height = mainRect.calculateHeight();
            }

            function onGroupedNotificationsChanged() {
                mainRect.height = mainRect.calculateHeight();
            }

            function onExpandedGroupsChanged() {
                mainRect.height = mainRect.calculateHeight();
            }

            function onExpandedMessagesChanged() {
                mainRect.height = mainRect.calculateHeight();
            }

            target: NotificationService
        }

        Behavior on height {
            NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: Anims.durMed
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anims.emphasized
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: Anims.durMed
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anims.emphasized
            }

        }

    }

}
