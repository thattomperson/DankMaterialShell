import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets

PanelWindow {
    id: root

    required property var notificationData  // Individual notification wrapper
    required property string notificationId
    readonly property bool isPopup: notificationData.popup
    readonly property int expireTimeout: notificationData.notification.expireTimeout

    property int verticalOffset: 0
    property bool initialAnimation: true
    property bool fadingOut: false
    property bool slideOut: false
    property bool entering: true

    signal entered()
    signal exitFinished()

    visible: isPopup || fadingOut || slideOut
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
    
    implicitWidth: 400
    implicitHeight: 116  // Individual notifications have fixed height

    anchors {
        top: true
        right: true
    }

    margins {
        top: Theme.barHeight + 16 + verticalOffset
        right: 12
    }

    Behavior on verticalOffset {
        NumberAnimation {
            duration: Anims.durMed
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Anims.emphasized
        }
    }

    Timer {
        id: enterDelay
        interval: Anims.durMed            // must match the entrance duration
        repeat: false
        onTriggered: notificationData.timer.start()
    }

    Component.onCompleted: {
        initialAnimation = false;         // kicks the right→left slide-in
        enterDelay.start();               // start TTL after entrance
    }

    Connections {
        target: notificationData
        function onPopupChanged() {
            if (!notificationData.popup) {
                if (notificationData.removedByLimit) {
                    slideOut = true;
                } else {
                    fadingOut = true;
                }
                // When a notification is no longer a popup, we want to remove it from the visible list
                // so that other notifications can move into its place.
                NotificationService.removeFromVisibleNotifications(notificationData);
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: Theme.cornerRadiusLarge
        color: Theme.popupBackground()
        border.color: notificationData.urgency === 2 ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
        border.width: notificationData.urgency === 2 ? 2 : 1
        clip: true
        opacity: (fadingOut || slideOut) ? 0 : 1
        scale: slideOut ? 0.98 : 1.0

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anims.emphasized
                onRunningChanged: if (!running && opacity === 0) root.visible = false
            }
        }

        Behavior on scale {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        transform: Translate {
            x: {
                if (initialAnimation) return 400;   // start off-screen right
                if (slideOut) return 64;            // gentle nudge on exit (was 400)
                return 0;
            }
            Behavior on x {
                enabled: initialAnimation || slideOut
                NumberAnimation {
                    id: xAnim
                    duration: Anims.durMed
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: slideOut ? Anims.emphasized : Anims.emphasizedDecel
                    onRunningChanged: {
                        if (!running) {
                            if (!slideOut) {        // entrance finished
                                entering = false;
                                entered();
                            } else {                // exit finished
                                exitFinished();
                            }
                        }
                    }
                }
            }
        }

        // Shadow layers
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            color: "transparent"
            radius: parent.radius + 3
            border.color: Qt.rgba(0, 0, 0, 0.05)
            border.width: 1
            z: -3
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            color: "transparent"
            radius: parent.radius + 2
            border.color: Qt.rgba(0, 0, 0, 0.08)
            border.width: 1
            z: -2
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
            border.width: 1
            radius: parent.radius
            z: -1
        }

        // Critical notification accent
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: notificationData.urgency === 2
            opacity: 1

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: Theme.primary
                }

                GradientStop {
                    position: 0.02
                    color: Theme.primary
                }

                GradientStop {
                    position: 0.021
                    color: "transparent"
                }
            }
        }

        Item {
            id: notificationContent
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 12
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            height: 86

            Rectangle {
                id: iconContainer
                readonly property bool hasNotificationImage: notificationData.image && notificationData.image !== ""
                readonly property bool appIconIsImage: notificationData.appIcon && (notificationData.appIcon.startsWith("file://") || notificationData.appIcon.startsWith("http://") || notificationData.appIcon.startsWith("https://"))

                width: 55
                height: 55
                radius: 27.5
                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
                border.color: "transparent"
                border.width: 0
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                IconImage {
                    anchors.fill: parent
                    anchors.margins: 2
                    source: {
                        if (parent.hasNotificationImage)
                            return notificationData.cleanImage;

                        if (notificationData.appIcon) {
                            const appIcon = notificationData.appIcon;
                            if (appIcon.startsWith("file://") || appIcon.startsWith("http://") || appIcon.startsWith("https://"))
                                return appIcon;
                            return Quickshell.iconPath(appIcon, "");
                        }
                        return "";
                    }
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: !parent.hasNotificationImage && (!notificationData.appIcon || notificationData.appIcon === "")
                    text: {
                        const appName = notificationData.appName || "?";
                        return appName.charAt(0).toUpperCase();
                    }
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    color: Theme.primaryText
                }
            }

            Rectangle {
                id: textContainer
                anchors.left: iconContainer.right
                anchors.leftMargin: 12
                anchors.right: closeButton.left
                anchors.rightMargin: 8
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
                color: "transparent"

                Column {
                    width: parent.width
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        width: parent.width
                        text: {
                            if (notificationData.timeStr.length > 0)
                                return notificationData.appName + " • " + notificationData.timeStr;
                            else
                                return notificationData.appName;
                        }
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Text {
                        text: notificationData.summary
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        width: parent.width
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        visible: text.length > 0
                    }

                    Text {
                        property bool hasUrls: {
                            const urlRegex = /(https?:\/\/[^\s]+)/g;
                            return urlRegex.test(notificationData.body);
                        }

                        text: {
                            let bodyText = notificationData.body;
                            if (bodyText.length > 105)
                                bodyText = bodyText.substring(0, 102) + "...";

                            const urlRegex = /(https?:\/\/[^\s]+)/g;
                            return bodyText.replace(urlRegex, '<a href="$1" style="color: ' + Theme.primary + '; text-decoration: underline;">$1</a>');
                        }
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                        width: parent.width
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.WordWrap
                        visible: text.length > 0
                        textFormat: Text.RichText
                        onLinkActivated: function(link) {
                            Qt.openUrlExternally(link);
                        }
                    }
                }
            }

            DankActionButton {
                id: closeButton
                anchors.right: parent.right
                anchors.top: parent.top
                iconName: "close"
                iconSize: 14
                buttonSize: 20
                z: 15
                onClicked: {
                    notificationData.popup = false;
                }
            }
        }

        // Main hover area for persistence and click handling
        MouseArea {
            id: cardHoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            propagateComposedEvents: true
            z: 0
            onEntered: {
                notificationData.timer.stop();
            }
            onExited: {
                if (notificationData.popup)
                    notificationData.timer.restart();
            }
            onClicked: {
                notificationData.popup = false;
            }
        }
    }
}
