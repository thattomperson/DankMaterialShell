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

    visible: NotificationService.groupedPopups.length > 0
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
    implicitWidth: 400
    implicitHeight: Math.min(Screen.height * 0.6, Math.max(400, (notificationsList.contentHeight || 0) + 32))

    anchors {
        top: true
        right: true
    }

    margins {
        top: Theme.barHeight
        right: 12
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        width: 380
        height: Math.min(Screen.height * 0.6 - 32, Math.max(368, (notificationsList.contentHeight || 0) + 32))
        color: "transparent"
        radius: 12
        clip: true

        ScrollView {
            anchors.fill: parent
            clip: true

            Column {
                id: notificationsList

                width: parent.width
                spacing: 12

                Repeater {
                    model: NotificationService.groupedPopups

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool expanded: NotificationService.expandedGroups[modelData.key] || false
                        readonly property string groupKey: modelData.key
                        readonly property bool isPopup: modelData.latestNotification.popup
                        readonly property int expireTimeout: modelData.latestNotification.notification.expireTimeout
                        property string stableGroupKey: ""
                        property var currentLatestNotification: modelData.latestNotification

                        Component.onCompleted: {
                            stableGroupKey = modelData.key;
                        }
                        width: parent.width
                        height: {
                            if (expanded && modelData.count >= 1) {
                                const baseHeight = (116 * modelData.count) + (12 * (modelData.count - 1));
                                const bottomMargin = modelData.count === 1 ? 70 : (modelData.count < 3 ? 50 : -28);
                                return baseHeight + bottomMargin;
                            }
                            return 116;
                        }
                        radius: Theme.cornerRadiusLarge
                        color: Theme.popupBackground()
                        border.color: modelData.latestNotification.urgency === 2 ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
                        border.width: modelData.latestNotification.urgency === 2 ? 2 : 1
                        clip: true
                        onCurrentLatestNotificationChanged: {
                            if (isPopup && !cardHoverArea.containsMouse)
                                dismissTimer.restart();

                        }

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

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            visible: modelData.latestNotification.urgency === 2
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
                            id: collapsedContent

                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.topMargin: 12
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            height: 86
                            visible: !expanded

                            Rectangle {
                                id: iconContainer

                                readonly property bool hasNotificationImage: modelData.latestNotification.image && modelData.latestNotification.image !== ""
                                readonly property bool appIconIsImage: modelData.latestNotification.appIcon && (modelData.latestNotification.appIcon.startsWith("file://") || modelData.latestNotification.appIcon.startsWith("http://") || modelData.latestNotification.appIcon.startsWith("https://"))

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
                                            return modelData.latestNotification.cleanImage;

                                        if (modelData.latestNotification.appIcon) {
                                            const appIcon = modelData.latestNotification.appIcon;
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
                                    visible: !parent.hasNotificationImage && (!modelData.latestNotification.appIcon || modelData.latestNotification.appIcon === "")
                                    text: {
                                        const appName = modelData.appName || "?";
                                        return appName.charAt(0).toUpperCase();
                                    }
                                    font.pixelSize: 20
                                    font.weight: Font.Bold
                                    color: Theme.primaryText
                                }

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: Theme.primary
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.topMargin: -2
                                    anchors.rightMargin: -2
                                    visible: modelData.count > 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.count > 99 ? "99+" : modelData.count.toString()
                                        color: Theme.primaryText
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                    }

                                }

                            }

                            Rectangle {
                                id: textContainer

                                anchors.left: iconContainer.right
                                anchors.leftMargin: 12
                                anchors.right: controlsContainer.left
                                anchors.rightMargin: 0
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 8
                                color: "transparent"
                                opacity: 1
                                border.color: "transparent"
                                border.width: 0

                                Item {
                                    width: parent.width
                                    height: parent.height
                                    anchors.top: parent.top
                                    anchors.topMargin: 2

                                    Column {
                                        id: textContent

                                        width: parent.width
                                        spacing: 2

                                        Text {
                                            width: parent.width
                                            text: {
                                                if (modelData.latestNotification.timeStr.length > 0)
                                                    return modelData.appName + " • " + modelData.latestNotification.timeStr;
                                                else
                                                    return modelData.appName;
                                            }
                                            color: Theme.surfaceVariantText
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                        }

                                        Text {
                                            text: modelData.latestNotification.summary
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
                                                return urlRegex.test(modelData.latestNotification.body);
                                            }

                                            text: {
                                                let bodyText = modelData.latestNotification.body;
                                                if (bodyText.length > 105)
                                                    bodyText = bodyText.substring(0, 102) + "...";

                                                const urlRegex = /(https?:\/\/[^\s]+)/g;
                                                return bodyText.replace(urlRegex, '<a href="$1" style="color: ' + Theme.primary + '; text-decoration: underline;">$1</a>');
                                            }
                                            color: Theme.surfaceVariantText
                                            font.pixelSize: Theme.fontSizeSmall
                                            width: parent.width
                                            elide: Text.ElideRight
                                            maximumLineCount: modelData.count > 1 ? 1 : 2
                                            wrapMode: Text.WordWrap
                                            visible: text.length > 0
                                            textFormat: Text.RichText
                                            onLinkActivated: function(link) {
                                                Qt.openUrlExternally(link);
                                            }
                                        }

                                    }

                                }

                            }

                            Item {
                                id: controlsContainer

                                anchors.right: parent.right
                                anchors.rightMargin: 0
                                anchors.top: parent.top
                                anchors.topMargin: 0
                                width: modelData.count > 1 ? 40 : 20
                                height: 24

                                DankActionButton {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    visible: modelData.count > 1
                                    iconName: expanded ? "expand_less" : "expand_more"
                                    iconSize: 14
                                    buttonSize: 20
                                    z: 15
                                    onClicked: NotificationService.toggleGroupExpansion(modelData.key)
                                }

                                DankActionButton {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    iconName: "close"
                                    iconSize: 14
                                    buttonSize: 20
                                    z: 15
                                    onClicked: {
                                        for (const notif of modelData.notifications) {
                                            notif.popup = false;
                                        }
                                    }
                                }

                            }

                        }

                        Item {
                            anchors.fill: parent
                            anchors.margins: 16
                            visible: expanded

                            Column {
                                id: expandedColumn

                                width: parent.width
                                spacing: 10

                                Item {
                                    width: parent.width
                                    height: 32

                                    Row {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 8

                                        Text {
                                            text: modelData.appName
                                            color: Theme.surfaceText
                                            font.pixelSize: Theme.fontSizeLarge
                                            font.weight: Font.Bold
                                        }

                                        Rectangle {
                                            width: 20
                                            height: 20
                                            radius: 10
                                            color: Theme.primary
                                            visible: modelData.count > 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.count.toString()
                                                color: Theme.primaryText
                                                font.pixelSize: 10
                                                font.weight: Font.Bold
                                            }

                                        }

                                    }

                                    Item {
                                        id: expandedControls

                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 56
                                        height: 24

                                        Row {
                                            anchors.fill: parent
                                            spacing: 8

                                            DankActionButton {
                                                iconName: "expand_less"
                                                iconSize: 14
                                                buttonSize: 20
                                                z: 15
                                                onClicked: NotificationService.toggleGroupExpansion(modelData.key)
                                            }

                                            DankActionButton {
                                                iconName: "close"
                                                iconSize: 14
                                                buttonSize: 20
                                                z: 15
                                                onClicked: {
                                                    for (const notif of modelData.notifications) {
                                                        notif.popup = false;
                                                    }
                                                }
                                            }

                                        }

                                    }

                                }

                                Rectangle {
                                    width: parent.width
                                    height: Math.min(400, modelData.notifications.length * 90) // Fixed height constraint for inner scroll
                                    radius: Theme.cornerRadiusLarge
                                    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.1)
                                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.05)
                                    border.width: 1
                                    clip: true

                                    ScrollView {
                                        anchors.fill: parent
                                        clip: true

                                        Column {
                                            width: parent.width
                                            spacing: 16

                                            Repeater {
                                                model: modelData.notifications

                                                delegate: Rectangle {
                                                    required property var modelData
                                                    readonly property bool messageExpanded: NotificationService.expandedMessages[modelData.notification.id] || false

                                                    width: parent.width
                                                    height: messageExpanded ? Math.min(120, 50 + (bodyText.contentHeight || 0)) : 80
                                                    radius: Theme.cornerRadiusLarge
                                                    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.2)
                                                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.05)
                                                    border.width: 1

                                                    Item {
                                                        anchors.fill: parent
                                                        anchors.margins: 12

                                                        // Small icon for individual message
                                                        Rectangle {
                                                            id: messageIcon

                                                            readonly property bool hasNotificationImage: modelData.image && modelData.image !== ""
                                                            readonly property bool appIconIsImage: modelData.appIcon && (modelData.appIcon.startsWith("file://") || modelData.appIcon.startsWith("http://") || modelData.appIcon.startsWith("https://"))

                                                            width: 32
                                                            height: 32
                                                            radius: 16
                                                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
                                                            anchors.left: parent.left
                                                            anchors.top: parent.top

                                                            IconImage {
                                                                anchors.fill: parent
                                                                anchors.margins: 2
                                                                source: {
                                                                    // Priority 1: Use notification image if available
                                                                    if (parent.hasNotificationImage)
                                                                        return modelData.cleanImage;

                                                                    // Priority 2: Use appIcon - handle URLs directly, use iconPath for icon names
                                                                    if (modelData.appIcon) {
                                                                        const appIcon = modelData.appIcon;
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
                                                                visible: !parent.hasNotificationImage && (!modelData.appIcon || modelData.appIcon === "")
                                                                text: {
                                                                    const appName = modelData.appName || "?";
                                                                    return appName.charAt(0).toUpperCase();
                                                                }
                                                                font.pixelSize: 14
                                                                font.weight: Font.Bold
                                                                color: Theme.primaryText
                                                            }

                                                        }

                                                        // Message content
                                                        Column {
                                                            anchors.left: messageIcon.right
                                                            anchors.leftMargin: 12
                                                            anchors.right: messageControls.left
                                                            anchors.rightMargin: 0
                                                            anchors.top: parent.top
                                                            spacing: 4

                                                            // App Title • Timestamp line
                                                            Text {
                                                                width: parent.width
                                                                text: {
                                                                    const appName = modelData.appName || "";
                                                                    const timeStr = modelData.timeStr || "";
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

                                                            // Summary line (if exists)
                                                            Text {
                                                                width: parent.width
                                                                text: modelData.summary || ""
                                                                color: Theme.surfaceText
                                                                font.pixelSize: Theme.fontSizeMedium
                                                                font.weight: Font.Medium
                                                                elide: Text.ElideRight
                                                                maximumLineCount: 1
                                                                visible: text.length > 0
                                                            }

                                                            // Body text with expand capability
                                                            Text {
                                                                id: bodyText

                                                                property bool hasUrls: {
                                                                    const urlRegex = /(https?:\/\/[^\s]+)/g;
                                                                    return urlRegex.test(modelData.body || "");
                                                                }

                                                                width: parent.width
                                                                text: {
                                                                    let bodyText = modelData.body || "";
                                                                    if (messageExpanded)
                                                                        bodyText = bodyText.length > 500 ? bodyText.substring(0, 497) + "..." : bodyText;
                                                                    else
                                                                        bodyText = bodyText.length > 80 ? bodyText.substring(0, 77) + "..." : bodyText;
                                                                    const urlRegex = /(https?:\/\/[^\s]+)/g;
                                                                    return bodyText.replace(urlRegex, '<a href="$1" style="color: ' + Theme.primary + '; text-decoration: underline;">$1</a>');
                                                                }
                                                                color: Theme.surfaceVariantText
                                                                font.pixelSize: Theme.fontSizeSmall
                                                                elide: messageExpanded ? Text.ElideNone : Text.ElideRight
                                                                maximumLineCount: messageExpanded ? -1 : 2
                                                                wrapMode: Text.WordWrap
                                                                visible: text.length > 0
                                                                textFormat: Text.RichText
                                                                onLinkActivated: function(link) {
                                                                    Qt.openUrlExternally(link);
                                                                }
                                                            }

                                                        }

                                                        // Message controls (expand and close buttons)
                                                        Row {
                                                            id: messageControls

                                                            anchors.right: parent.right
                                                            anchors.top: parent.top
                                                            spacing: 4

                                                            // Expand/collapse button for individual message
                                                            DankActionButton {
                                                                visible: (modelData.body || "").length > 80
                                                                iconName: messageExpanded ? "expand_less" : "expand_more"
                                                                iconSize: 12
                                                                buttonSize: 20
                                                                z: 15
                                                                onClicked: NotificationService.toggleMessageExpansion(modelData.notification.id)
                                                            }

                                                            // Close button for individual message
                                                            DankActionButton {
                                                                iconName: "close"
                                                                iconSize: 12
                                                                buttonSize: 20
                                                                z: 15
                                                                onClicked: NotificationService.dismissNotification(modelData)
                                                            }

                                                        }

                                                    }

                                                    Behavior on height {
                                                        NumberAnimation {
                                                            duration: Theme.shortDuration
                                                            easing.type: Theme.standardEasing
                                                        }

                                                    }

                                                }

                                            }

                                        }

                                    }

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
                                dismissTimer.stop();
                            }
                            onExited: {
                                if (modelData.latestNotification.popup)
                                    dismissTimer.restart();

                            }
                            onClicked: {
                                for (const notif of modelData.notifications) {
                                    notif.popup = false;
                                }
                            }
                        }

                        // Action buttons positioned at bottom-left of notification card
                        Row {
                            anchors.right: dismissButton.left
                            anchors.rightMargin: 8
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 8
                            spacing: 4
                            z: 10

                            Repeater {
                                model: modelData.latestNotification.actions || []

                                Rectangle {
                                    property bool isHovered: false

                                    width: Math.min(actionText.contentWidth + 12, 70)
                                    height: 24
                                    radius: 4
                                    color: isHovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1) : "transparent"

                                    Text {
                                        id: actionText

                                        text: modelData.text || ""
                                        color: parent.isHovered ? Theme.primary : Theme.surfaceVariantText
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Medium
                                        anchors.centerIn: parent
                                        elide: Text.ElideRight
                                        width: Math.min(contentWidth, parent.width - 8)
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: {
                                            parent.isHovered = true;
                                            dismissTimer.stop();
                                        }
                                        onExited: {
                                            parent.isHovered = false;
                                            if (modelData.latestNotification.popup && !cardHoverArea.containsMouse)
                                                dismissTimer.restart();

                                        }
                                        onClicked: {
                                            if (modelData && modelData.invoke)
                                                modelData.invoke();

                                        }
                                    }

                                }

                            }

                        }

                        // Dismiss button positioned at bottom-right of notification card
                        Rectangle {
                            id: dismissButton

                            property bool isHovered: false

                            anchors.right: parent.right
                            anchors.rightMargin: 16
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 8
                            width: dismissText.width + 16
                            height: dismissText.height + 8
                            radius: 6
                            color: isHovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1) : "transparent"
                            z: 10

                            Text {
                                id: dismissText

                                text: "Dismiss"
                                color: dismissButton.isHovered ? Theme.primary : Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: popupDismissArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                z: 11
                                onEntered: {
                                    dismissButton.isHovered = true;
                                    dismissTimer.stop();
                                }
                                onExited: {
                                    dismissButton.isHovered = false;
                                    if (modelData.latestNotification.popup && !cardHoverArea.containsMouse)
                                        dismissTimer.restart();

                                }
                                onClicked: {
                                    NotificationService.dismissGroup(modelData.key);
                                }
                            }

                        }

                        Timer {
                            id: dismissTimer

                            running: isPopup
                            interval: 5000 // Fixed 5-second timer for all notifications
                            onTriggered: {
                                // Move to notification center (don't dismiss completely)
                                const groupKey = stableGroupKey || modelData.key;
                                modelData.latestNotification.popup = false;
                                // Clear expansion state when hiding from popup
                                NotificationService.clearGroupExpansionState(groupKey);
                            }
                        }

                        transform: Translate {
                            x: root.visible ? 0 : 400

                            Behavior on x {
                                NumberAnimation {
                                    duration: 350
                                    easing.type: Easing.OutCubic
                                }

                            }

                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                }

            }

        }

        Behavior on height {
            NumberAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }

        }

    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Theme.mediumDuration
            easing.type: Theme.emphasizedEasing
        }

    }

}
