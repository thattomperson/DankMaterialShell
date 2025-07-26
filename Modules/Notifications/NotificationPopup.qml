import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets

PanelWindow {
    id: win

    required property var notificationData
    required property string notificationId
    readonly property bool isPopup: notificationData.popup
    readonly property int expireTimeout: notificationData.notification.expireTimeout
    
    property int screenY: 0
    onScreenYChanged: margins.top = Theme.barHeight + 16 + screenY
    Behavior on screenY {
        enabled: !exiting
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    property int rowHeight: 132
    property bool exiting: false

    signal entered()
    signal exitFinished()

    visible: true
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
    implicitWidth: 400
    implicitHeight: 116

    anchors {
        top: true
        right: true
    }

    margins {
        top: Theme.barHeight + 16
        right: 12
    }

    Item {
        id: content
        anchors.fill: parent

        transform: Translate {
            id: tx
            x: 400
            Behavior on x {
                NumberAnimation {
                    id: xAnim
                    duration: 240
                    easing.type: Easing.OutCubic
                    onRunningChanged: {
                        if (!running && win && !win.exiting && Math.abs(tx.x) < 0.5) win.entered();
                        if (!running && win && win.exiting && Math.abs(tx.x - 96) < 0.5) maybeFinishExit();
                    }
                }
            }
        }

        opacity: win.exiting ? 0 : 1
        Behavior on opacity {
            NumberAnimation {
                id: fadeAnim
                duration: 200
                easing.type: Easing.OutCubic
                onRunningChanged: if (!running && win && win.exiting && content && content.opacity === 0) maybeFinishExit()
            }
        }

        scale: win.exiting ? 0.98 : 1.0
        Behavior on scale {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        layer.enabled: (Math.abs(tx.x) > 0.5) || win.exiting
        layer.smooth: true

        Rectangle {
            property var shadowLayers: [shadowLayer1, shadowLayer2, shadowLayer3]

            anchors.fill: parent
            anchors.margins: 4
            radius: Theme.cornerRadiusLarge
            color: Theme.popupBackground()
            border.color: notificationData.urgency === 2 ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
            border.width: notificationData.urgency === 2 ? 2 : 1
            clip: true

            Rectangle {
                id: shadowLayer1
                anchors.fill: parent
                anchors.margins: -3
                color: "transparent"
                radius: parent.radius + 3
                border.color: Qt.rgba(0, 0, 0, 0.05)
                border.width: 1
                z: -3
            }

            Rectangle {
                id: shadowLayer2
                anchors.fill: parent
                anchors.margins: -2
                color: "transparent"
                radius: parent.radius + 2
                border.color: Qt.rgba(0, 0, 0, 0.08)
                border.width: 1
                z: -2
            }

            Rectangle {
                id: shadowLayer3
                anchors.fill: parent
                color: "transparent"
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                border.width: 1
                radius: parent.radius
                z: -1
            }

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
                    property alias iconImage: iconImage

                    width: 55
                    height: 55
                    radius: 27.5
                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
                    border.color: "transparent"
                    border.width: 0
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    IconImage {
                        id: iconImage
                        anchors.fill: parent
                        anchors.margins: 2
                        asynchronous: true
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

    Component.onCompleted: {
        enterDelay.start();
        Qt.callLater(() => { tx.x = 0; });
    }

    Timer {
        id: enterDelay
        interval: Anims.durMed
        repeat: false
        onTriggered: notificationData.timer.start()
    }

    Connections {
        target: notificationData
        function onPopupChanged() {
            if (!notificationData.popup && !win.exiting) {
                win.exiting = true;
                win.screenY = win.screenY;
                tx.x = 96;
                exitWatchdog.restart();
                forceCleanupTimer.restart();
                NotificationService.removeFromVisibleNotifications(notificationData);
            }
        }
    }

    Timer {
        id: exitWatchdog
        interval: 500
        repeat: false
        onTriggered: if (win) win.exitFinished()
    }
    
    Timer {
        id: forceCleanupTimer
        interval: 2000
        repeat: false
        onTriggered: if (win) win.exitFinished()
    }

    function maybeFinishExit() {
        if (win && win.exiting && content && Math.abs(tx.x - 96) < 0.5 && content.opacity === 0) {
            exitWatchdog.stop();
            forceCleanupTimer.stop();
            win.exitFinished();
        }
    }
}