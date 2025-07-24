//NotificationCenter.qml
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
    implicitWidth: 400
    implicitHeight: Math.min(Screen.height * 0.6, Math.max(580, (notificationsList.contentHeight || 0) + 140))
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

    // Background to close popup when clicking outside
    MouseArea {
        anchors.fill: parent
        onClicked: {
            notificationHistoryVisible = false;
        }
    }

    Rectangle {
        width: 400
        height: Math.min(Screen.height * 0.6, Math.max(580, (notificationsList.contentHeight || 0) + 140))
        x: Screen.width - width - Theme.spacingL
        y: Theme.barHeight + Theme.spacingXS
        color: Theme.popupBackground()
        radius: Theme.cornerRadiusLarge
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
        border.width: 0.5
        opacity: notificationHistoryVisible ? 1 : 0
        // Animation
        transform: [
            Scale {
                id: scaleTransform

                origin.x: 400 // Use fixed width since popup is 400px wide
                origin.y: 0
                xScale: notificationHistoryVisible ? 1 : 0.95
                yScale: notificationHistoryVisible ? 1 : 0.8
            },
            Translate {
                id: translateTransform

                x: notificationHistoryVisible ? 0 : 15
                y: notificationHistoryVisible ? 0 : -30
            }
        ]
        states: [
            State {
                name: "visible"
                when: notificationHistoryVisible

                PropertyChanges {
                    target: scaleTransform
                    xScale: 1
                    yScale: 1
                }

                PropertyChanges {
                    target: translateTransform
                    x: 0
                    y: 0
                }

            },
            State {
                name: "hidden"
                when: !notificationHistoryVisible

                PropertyChanges {
                    target: scaleTransform
                    xScale: 0.95
                    yScale: 0.8
                }

                PropertyChanges {
                    target: translateTransform
                    x: 15
                    y: -30
                }

            }
        ]
        transitions: [
            Transition {
                from: "*"
                to: "*"

                ParallelAnimation {
                    NumberAnimation {
                        targets: [scaleTransform, translateTransform]
                        properties: "xScale,yScale,x,y"
                        duration: Theme.mediumDuration
                        easing.type: Theme.emphasizedEasing
                    }

                }

            }
        ]

        // Prevent clicks from propagating to background
        MouseArea {
            // Stop propagation - do nothing

            anchors.fill: parent
            onClicked: {
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            // Header
            Item {
                width: parent.width
                height: 32

                Text {
                    text: "Notifications"
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.surfaceText
                    font.weight: Font.Medium
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Clear All Button - fixed width aligned to right
                Rectangle {
                    width: 120
                    height: 28
                    radius: Theme.cornerRadius
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: NotificationService.notifications.length > 0
                    color: clearArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Theme.surfaceContainer
                    border.color: clearArea.containsMouse ? Theme.primary : Theme.outline
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

            // Notification List
            ScrollView {
                width: parent.width
                height: parent.height - 140
                clip: true
                contentWidth: -1
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ListView {
                    id: notificationsList

                    model: NotificationService.groupedNotifications
                    spacing: Theme.spacingL
                    interactive: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 1500
                    maximumFlickVelocity: 2000

                    // Enhanced smooth animations to prevent layout jumping
                    add: Transition {
                        ParallelAnimation {
                            NumberAnimation {
                                properties: "opacity"
                                from: 0
                                to: 1
                                duration: Theme.mediumDuration
                                easing.type: Theme.emphasizedEasing
                            }

                            NumberAnimation {
                                properties: "height"
                                from: 0
                                duration: Theme.mediumDuration
                                easing.type: Theme.emphasizedEasing
                            }

                        }

                    }

                    remove: Transition {
                        SequentialAnimation {
                            // Pause to let internal content animations complete
                            PauseAnimation {
                                duration: 50
                            }

                            ParallelAnimation {
                                NumberAnimation {
                                    properties: "opacity"
                                    to: 0
                                    duration: Theme.mediumDuration
                                    easing.type: Theme.emphasizedEasing
                                }

                                NumberAnimation {
                                    properties: "height,anchors.topMargin,anchors.bottomMargin"
                                    to: 0
                                    duration: Theme.mediumDuration
                                    easing.type: Theme.emphasizedEasing
                                }

                            }

                        }

                    }

                    displaced: Transition {
                        NumberAnimation {
                            properties: "y"
                            duration: Theme.mediumDuration
                            easing.type: Theme.emphasizedEasing
                        }

                    }

                    // Add move transition for internal content changes
                    move: Transition {
                        NumberAnimation {
                            properties: "y"
                            duration: Theme.mediumDuration
                            easing.type: Theme.emphasizedEasing
                        }

                    }

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool expanded: NotificationService.expandedGroups[modelData.key] || false
                        readonly property string groupKey: modelData.key

                        width: ListView.view.width
                        height: {
                            if (expanded && modelData.count >= 1) {
                                const baseHeight = (116 * modelData.count) + (12 * (modelData.count - 1));
                                // Add extra bottom margin for expanded groups
                                const bottomMargin = modelData.count === 1 ? 65 : (modelData.count <= 3 ? 30 : -30);
                                return baseHeight + bottomMargin;
                            }
                            return 116;
                        }
                        radius: 12
                        color: Theme.popupBackground()
                        border.color: modelData.latestNotification.urgency === 2 ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
                        border.width: modelData.latestNotification.urgency === 2 ? 2 : 1
                        clip: true

                        // Priority indicator for urgent notifications
                        Rectangle {
                            width: 4
                            height: parent.height - 16
                            anchors.left: parent.left
                            anchors.leftMargin: 2
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 2
                            color: Theme.primary
                            visible: modelData.latestNotification.urgency === 2
                        }

                        // Collapsed view - show latest notification using popup style
                        Item {
                            id: collapsedContent

                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.topMargin: 12
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            height: 92
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
                                        // Priority 1: Use notification image if available
                                        if (parent.hasNotificationImage)
                                            return modelData.latestNotification.cleanImage;

                                        // Priority 2: Use appIcon - handle URLs directly, use iconPath for icon names
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
                                            // No truncation for notification center - show full text

                                            property bool hasUrls: {
                                                const urlRegex = /(https?:\/\/[^\s]+)/g;
                                                return urlRegex.test(modelData.latestNotification.body);
                                            }

                                            text: {
                                                // Auto-detect and make URLs clickable, with truncation for center notifications
                                                let bodyText = modelData.latestNotification.body;
                                                const urlRegex = /(https?:\/\/[^\s]+)/g;
                                                return bodyText.replace(urlRegex, '<a href="$1" style="color: ' + Theme.primary + '; text-decoration: underline;">$1</a>');
                                            }
                                            color: Theme.surfaceVariantText
                                            font.pixelSize: Theme.fontSizeSmall
                                            width: parent.width
                                            elide: Text.ElideRight
                                            maximumLineCount: modelData.count > 1 ? 2 : 3
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
                                width: modelData.count > 1 ? 40 : 20 // Dynamic width: 40px for expand+close, 20px for close only
                                height: 24

                                // Expand button - always takes up space but only visible when needed
                                Rectangle {
                                    id: collapsedExpandButton

                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: expandArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"
                                    visible: modelData.count > 1

                                    DankIcon {
                                        anchors.centerIn: parent
                                        name: expanded ? "expand_less" : "expand_more"
                                        size: 14
                                        color: Theme.surfaceText
                                    }

                                    MouseArea {
                                        id: expandArea

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NotificationService.toggleGroupExpansion(modelData.key)
                                    }

                                }

                                // Close button - always positioned at the right edge
                                Rectangle {
                                    id: closeButton

                                    property bool isHovered: false

                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: isHovered ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"
                                    z: 10

                                    DankIcon {
                                        id: closeIcon

                                        name: "close"
                                        size: 14
                                        color: closeButton.isHovered ? Theme.primary : Theme.surfaceText
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        id: dismissArea

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        z: 11
                                        onEntered: {
                                            closeButton.isHovered = true;
                                        }
                                        onExited: {
                                            closeButton.isHovered = false;
                                        }
                                        onClicked: NotificationService.dismissGroup(modelData.key)
                                    }

                                }

                            }

                        }

                        // Expanded view - shows all notifications stacked
                        Column {
                            id: expandedContent

                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.topMargin: 14 // Reduced from Theme.spacingL (16px) by 10%
                            anchors.bottomMargin: 14 // Reduced from Theme.spacingL (16px) by 10%
                            anchors.leftMargin: Theme.spacingL
                            anchors.rightMargin: Theme.spacingL
                            spacing: -1 // Reduced by 10px from original 9px
                            visible: expanded

                            // 1st tier controls with app name - optimized spacing
                            Item {
                                width: parent.width
                                height: 40

                                // App name and count badge - left side
                                Row {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.spacingS

                                    Text {
                                        text: modelData.appName
                                        color: Theme.surfaceText
                                        font.pixelSize: Theme.fontSizeLarge
                                        font.weight: Font.Bold
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    // Message count badge when expanded
                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        color: Theme.primary
                                        visible: modelData.count > 1
                                        anchors.verticalCenter: parent.verticalCenter

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.count.toString()
                                            color: Theme.primaryText
                                            font.pixelSize: 10
                                            font.weight: Font.Bold
                                        }

                                    }

                                }

                                // Controls container - fixed position on right
                                Item {
                                    width: 48
                                    height: 24
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.topMargin: 2

                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        anchors.left: parent.left
                                        color: collapseAreaTop.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"

                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: "expand_less"
                                            size: 14
                                            color: Theme.surfaceText
                                        }

                                        MouseArea {
                                            id: collapseAreaTop

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NotificationService.toggleGroupExpansion(modelData.key)
                                        }

                                    }

                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        anchors.right: parent.right
                                        color: dismissAllAreaTop.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"

                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: "close"
                                            size: 14
                                            color: Theme.surfaceText
                                        }

                                        MouseArea {
                                            id: dismissAllAreaTop

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NotificationService.dismissGroup(modelData.key)
                                        }

                                    }

                                }

                            }

                            // Individual notifications
                            Column {
                                width: parent.width
                                spacing: 16 // Increased margin between individual message cards

                                Repeater {
                                    model: modelData.notifications.slice(0, 10)

                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property bool messageExpanded: NotificationService.expandedMessages[modelData.notification.id] || false

                                        width: parent.width
                                        height: messageExpanded ? Math.min(120, 50 + (bodyText.contentHeight || 0)) : 80
                                        radius: 8
                                        color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.3)
                                        border.color: "transparent"
                                        border.width: 0

                                        Item {
                                            anchors.fill: parent
                                            anchors.margins: 12

                                            Rectangle {
                                                id: messageIcon

                                                readonly property bool hasNotificationImage: modelData.image && modelData.image !== ""

                                                width: 32
                                                height: 32
                                                radius: 16
                                                anchors.left: parent.left
                                                anchors.top: parent.top
                                                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
                                                border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                                                border.width: 1

                                                IconImage {
                                                    anchors.fill: parent
                                                    anchors.margins: 1
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
                                                    font.pixelSize: 12
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
                                                        // Show up to 500 characters when expanded
                                                        // Show truncated version when collapsed
                                                        let bodyText = modelData.body || "";
                                                        if (messageExpanded)
                                                            bodyText = bodyText.length > 500 ? bodyText.substring(0, 497) + "..." : bodyText;
                                                        else
                                                            bodyText = bodyText.length > 80 ? bodyText.substring(0, 77) + "..." : bodyText;
                                                        // Auto-detect and make URLs clickable
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
                                                anchors.rightMargin: -6
                                                anchors.top: parent.top
                                                spacing: 4

                                                // Expand/collapse button for individual message
                                                Rectangle {
                                                    id: expandButton

                                                    width: 20
                                                    height: 20
                                                    radius: 10
                                                    color: expandMessageArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"
                                                    visible: (modelData.body || "").length > 80

                                                    DankIcon {
                                                        anchors.centerIn: parent
                                                        name: {
                                                            const messageExpanded = NotificationService.expandedMessages[modelData.notification.id] || false;
                                                            return messageExpanded ? "expand_less" : "expand_more";
                                                        }
                                                        size: 12
                                                        color: Theme.surfaceText
                                                    }

                                                    MouseArea {
                                                        id: expandMessageArea

                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: NotificationService.toggleMessageExpansion(modelData.notification.id)
                                                    }

                                                }

                                                // Close button for individual message
                                                Rectangle {
                                                    width: 20
                                                    height: 20
                                                    radius: 10
                                                    color: closeMessageArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"

                                                    DankIcon {
                                                        anchors.centerIn: parent
                                                        name: "close"
                                                        size: 12
                                                        color: closeMessageArea.containsMouse ? Theme.primary : Theme.surfaceText
                                                    }

                                                    MouseArea {
                                                        id: closeMessageArea

                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: NotificationService.dismissNotification(modelData)
                                                    }

                                                }

                                            }

                                        }

                                    }

                                }

                            }

                        }

                        // View button positioned at bottom-right of notification card
                        Rectangle {
                            id: viewButton

                            property bool isHovered: false

                            anchors.right: dismissButton.left
                            anchors.rightMargin: 4
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 8
                            width: viewText.width + 16
                            height: viewText.height + 8
                            radius: 6
                            color: isHovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1) : "transparent"
                            z: 10

                            Text {
                                id: viewText

                                text: "View"
                                color: viewButton.isHovered ? Theme.primary : Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: viewArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                z: 11
                                onEntered: {
                                    viewButton.isHovered = true;
                                }
                                onExited: {
                                    viewButton.isHovered = false;
                                }
                                onClicked: {
                                    // Handle navigation to source message
                                    if (modelData.latestNotification.actions) {
                                        for (const action of modelData.latestNotification.actions) {
                                            if (action.text && action.text.toLowerCase() === "view") {
                                                if (action.invoke) {
                                                    action.invoke();
                                                    return ;
                                                }
                                            }
                                        }
                                        // If no View action, try the first available action
                                        if (modelData.latestNotification.actions.length > 0) {
                                            const firstAction = modelData.latestNotification.actions[0];
                                            if (firstAction.invoke)
                                                firstAction.invoke();

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
                                id: centerDismissArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                z: 11
                                onEntered: {
                                    dismissButton.isHovered = true;
                                }
                                onExited: {
                                    dismissButton.isHovered = false;
                                }
                                onClicked: {
                                    // Dismiss from notification center completely
                                    NotificationService.dismissGroup(modelData.key);
                                }
                            }

                        }

                        // Tap to expand for collapsed groups
                        MouseArea {
                            anchors.fill: parent
                            visible: !expanded && modelData.count > 1
                            onClicked: NotificationService.toggleGroupExpansion(modelData.key)
                            z: -1
                        }

                        Behavior on height {
                            SequentialAnimation {
                                PauseAnimation {
                                    duration: 25
                                }

                                NumberAnimation {
                                    duration: Theme.mediumDuration
                                    easing.type: Theme.emphasizedEasing
                                }

                            }

                        }

                    }

                }

                // Empty state
                Item {
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

            }

        }

        Behavior on height {
            NumberAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
            }

        }

    }

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: notificationHistoryVisible = false
    }

}
