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
        top: Theme.barHeight + 4
        right: 12
    }

    // Manager drives vertical stacking with this proxy:
    property int screenY: 0
    onScreenYChanged: margins.top = Theme.barHeight + 4 + screenY

    // Disable vertical tween while exiting so there is never diagonal motion
    Behavior on screenY {
        id: screenYAnim
        enabled: !exiting
        NumberAnimation { 
            duration: Anims.durShort
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Anims.standardDecel
        }
    }

    // State
    property bool exiting: false
    signal entered()
    signal exitFinished()

    Item {
        id: content
        anchors.fill: parent

        // We animate a Translate so anchors never override horizontal motion
        transform: Translate { id: tx; x: Anims.slidePx }   // start off-screen right

        // Optional: layer while animating for smoothness
        layer.enabled: (enterX.running || exitAnim.running)
        layer.smooth: true

        Rectangle {
            property var shadowLayers: [shadowLayer1, shadowLayer2, shadowLayer3]

            anchors.fill: parent
            anchors.margins: 4
            radius: Theme.cornerRadiusLarge
            color: Theme.popupBackground()
            border.color: notificationData && notificationData.urgency === 2 ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
            border.width: notificationData && notificationData.urgency === 2 ? 2 : 1
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
                visible: notificationData && notificationData.urgency === 2
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
                    readonly property bool hasNotificationImage: notificationData && notificationData.image && notificationData.image !== ""
                    readonly property bool appIconIsImage: notificationData && notificationData.appIcon && (notificationData.appIcon.startsWith("file://") || notificationData.appIcon.startsWith("http://") || notificationData.appIcon.startsWith("https://"))
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
                            if (!notificationData) return "";
                            
                            if (parent.hasNotificationImage)
                                return notificationData.cleanImage || "";

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
                        visible: !parent.hasNotificationImage && (!notificationData || !notificationData.appIcon || notificationData.appIcon === "")
                        text: {
                            const appName = notificationData && notificationData.appName ? notificationData.appName : "?";
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
                                if (!notificationData) return "";
                                const appName = notificationData.appName || "";
                                const timeStr = notificationData.timeStr || "";
                                if (timeStr.length > 0)
                                    return appName + " • " + timeStr;
                                else
                                    return appName;
                            }
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Text {
                            text: notificationData ? (notificationData.summary || "") : ""
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
                                if (!notificationData || !notificationData.body) return false;
                                const urlRegex = /(https?:\/\/[^\s]+)/g;
                                return urlRegex.test(notificationData.body);
                            }

                            text: {
                                if (!notificationData || !notificationData.body) return "";
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
                        if (notificationData)
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
                    if (notificationData && notificationData.timer)
                        notificationData.timer.stop();
                }
                onExited: {
                    if (notificationData && notificationData.popup && notificationData.timer)
                        notificationData.timer.restart();
                }
                onClicked: {
                    if (notificationData)
                        notificationData.popup = false;
                }
            }
        }
    }

    // Entrance: slide in from right using slowed Anims curves
    NumberAnimation {
        id: enterX
        target: tx; property: "x"; from: Anims.slidePx; to: 0
        duration: Anims.durMed
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Anims.emphasizedDecel
        onStopped: if (!win.exiting && Math.abs(tx.x) < 0.5) win.entered();
    }

    // Exit: slide out to right + fade using slowed Anims curves
    ParallelAnimation {
        id: exitAnim
        PropertyAnimation { 
            target: tx; property: "x"; from: 0; to: Anims.slidePx
            duration: Anims.durShort
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Anims.emphasizedAccel
        }
        NumberAnimation { 
            target: content; property: "opacity"; from: 1; to: 0
            duration: Anims.durShort
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Anims.standardAccel
        }
        NumberAnimation { 
            target: content; property: "scale"; from: 1; to: 0.98
            duration: Anims.durShort
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Anims.emphasizedAccel
        }
        onStopped: finalizeExit("animStopped")
    }

    // Start entrance one tick after create (so it always animates)
    Component.onCompleted: Qt.callLater(() => enterX.restart())

    // Safe connection to wrapper: disable automatically when wrapper is null
    Connections {
        id: wrapperConn
        target: win.notificationData || null
        ignoreUnknownSignals: true
        function onPopupChanged() {
            if (!win.notificationData) return;        // guard
            if (!win.notificationData.popup && !win.exiting) {
                // Freeze vertical and start exit
                win.exiting = true;                   // disables screenY Behavior
                exitAnim.restart();
                exitWatchdog.restart();               // safety net
                if (NotificationService.removeFromVisibleNotifications)
                    NotificationService.removeFromVisibleNotifications(win.notificationData);
            }
        }
    }
    onNotificationDataChanged: wrapperConn.target = win.notificationData || null

    // Timer to start on entrance
    Timer {
        id: enterDelay
        interval: 160
        repeat: false
        onTriggered: {
            if (notificationData && notificationData.timer)
                notificationData.timer.start();
        }
    }

    // Start timer after entrance animation
    onEntered: enterDelay.start()

    // Idempotent finalizer so we never "half-exit"
    property bool _finalized: false
    function finalizeExit(reason) {
        if (_finalized) return;
        _finalized = true;
        exitWatchdog.stop();
        win.exitFinished();                           // manager will destroy the window
    }
    Timer { id: exitWatchdog; interval: 600; repeat: false; onTriggered: finalizeExit("watchdog") }

    // If the popup is torn down unexpectedly, don't leave dangling timers
    Component.onDestruction: { exitWatchdog.stop(); }
}