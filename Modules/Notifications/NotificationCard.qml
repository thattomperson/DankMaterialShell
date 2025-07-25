import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root
    
    property var notificationGroup
    property bool expanded: NotificationService.expandedGroups[notificationGroup?.key] || false
    
    width: parent.width
    height: {
        if (expanded && notificationGroup && notificationGroup.count >= 1) {
            const baseHeight = (116 * notificationGroup.count) + (12 * (notificationGroup.count - 1));
            const bottomMargin = notificationGroup.count === 1 ? 65 : (notificationGroup.count <= 3 ? 30 : -30);
            return baseHeight + bottomMargin;
        }
        return 116;
    }
    radius: Theme.cornerRadiusLarge
    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.1)
    border.color: notificationGroup?.latestNotification?.urgency === 2 ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.05)
    border.width: notificationGroup?.latestNotification?.urgency === 2 ? 2 : 1
    clip: true

    Rectangle {
        width: 4
        height: parent.height - 16
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        radius: 2
        color: Theme.primary
        visible: notificationGroup?.latestNotification?.urgency === 2
    }

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

            readonly property bool hasNotificationImage: notificationGroup?.latestNotification?.image && notificationGroup.latestNotification.image !== ""

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
                        return notificationGroup.latestNotification.cleanImage;

                    if (notificationGroup?.latestNotification?.appIcon) {
                        const appIcon = notificationGroup.latestNotification.appIcon;
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
                visible: !parent.hasNotificationImage && (!notificationGroup?.latestNotification?.appIcon || notificationGroup.latestNotification.appIcon === "")
                text: {
                    const appName = notificationGroup?.appName || "?";
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
                visible: (notificationGroup?.count || 0) > 1

                Text {
                    anchors.centerIn: parent
                    text: (notificationGroup?.count || 0) > 99 ? "99+" : (notificationGroup?.count || 0).toString()
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

            Item {
                width: parent.width
                height: parent.height
                anchors.top: parent.top
                anchors.topMargin: 2

                Column {
                    width: parent.width
                    spacing: 2

                    Text {
                        width: parent.width
                        text: {
                            const timeStr = notificationGroup?.latestNotification?.timeStr || "";
                            if (timeStr.length > 0)
                                return (notificationGroup?.appName || "") + " • " + timeStr;
                            else
                                return notificationGroup?.appName || "";
                        }
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Text {
                        text: notificationGroup?.latestNotification?.summary || ""
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        width: parent.width
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        visible: text.length > 0
                    }

                    Text {
                        text: {
                            let bodyText = notificationGroup?.latestNotification?.body || "";
                            const urlRegex = /(https?:\/\/[^\s]+)/g;
                            return bodyText.replace(urlRegex, '<a href="$1" style="color: ' + Theme.primary + '; text-decoration: underline;">$1</a>');
                        }
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                        width: parent.width
                        elide: Text.ElideRight
                        maximumLineCount: (notificationGroup?.count || 0) > 1 ? 2 : 3
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
            width: (notificationGroup?.count || 0) > 1 ? 40 : 20
            height: 24

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                width: 20
                height: 20
                radius: 10
                color: expandArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"
                visible: (notificationGroup?.count || 0) > 1

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
                    onClicked: NotificationService.toggleGroupExpansion(notificationGroup?.key || "")
                }
            }

            Rectangle {
                property bool isHovered: false

                anchors.right: parent.right
                anchors.top: parent.top
                width: 20
                height: 20
                radius: 10
                color: isHovered ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"

                DankIcon {
                    name: "close"
                    size: 14
                    color: parent.isHovered ? Theme.primary : Theme.surfaceText
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: parent.isHovered = true
                    onExited: parent.isHovered = false
                    onClicked: NotificationService.dismissGroup(notificationGroup?.key || "")
                }
            }
        }
    }

    Column {
        id: expandedContent

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        anchors.leftMargin: Theme.spacingL
        anchors.rightMargin: Theme.spacingL
        spacing: -1
        visible: expanded

        Item {
            width: parent.width
            height: 40

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingS

                Text {
                    text: notificationGroup?.appName || ""
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    color: Theme.primary
                    visible: (notificationGroup?.count || 0) > 1
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: (notificationGroup?.count || 0).toString()
                        color: Theme.primaryText
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }
            }

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
                    color: collapseArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"

                    DankIcon {
                        anchors.centerIn: parent
                        name: "expand_less"
                        size: 14
                        color: Theme.surfaceText
                    }

                    MouseArea {
                        id: collapseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationService.toggleGroupExpansion(notificationGroup?.key || "")
                    }
                }

                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    anchors.right: parent.right
                    color: dismissAllArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"

                    DankIcon {
                        anchors.centerIn: parent
                        name: "close"
                        size: 14
                        color: Theme.surfaceText
                    }

                    MouseArea {
                        id: dismissAllArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationService.dismissGroup(notificationGroup?.key || "")
                    }
                }
            }
        }

        Column {
            width: parent.width
            spacing: 16

            Repeater {
                model: notificationGroup?.notifications?.slice(0, 10) || []

                delegate: Rectangle {
                    required property var modelData
                    readonly property bool messageExpanded: NotificationService.expandedMessages[modelData?.notification?.id] || false

                    width: parent.width
                    height: messageExpanded ? Math.min(120, 50 + (bodyText.contentHeight || 0)) : 80
                    radius: Theme.cornerRadiusLarge
                    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.2)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.05)
                    border.width: 1

                    Item {
                        anchors.fill: parent
                        anchors.margins: 12

                        Rectangle {
                            id: messageIcon

                            readonly property bool hasNotificationImage: modelData?.image && modelData.image !== ""

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
                                    if (parent.hasNotificationImage)
                                        return modelData.cleanImage;

                                    if (modelData?.appIcon) {
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
                                visible: !parent.hasNotificationImage && (!modelData?.appIcon || modelData.appIcon === "")
                                text: {
                                    const appName = modelData?.appName || "?";
                                    return appName.charAt(0).toUpperCase();
                                }
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: Theme.primaryText
                            }
                        }

                        Column {
                            anchors.left: messageIcon.right
                            anchors.leftMargin: 12
                            anchors.right: messageControls.left
                            anchors.rightMargin: 0
                            anchors.top: parent.top
                            spacing: 4

                            Text {
                                width: parent.width
                                text: {
                                    const appName = modelData?.appName || "";
                                    const timeStr = modelData?.timeStr || "";
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
                                width: parent.width
                                text: modelData?.summary || ""
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                visible: text.length > 0
                            }

                            Text {
                                id: bodyText

                                width: parent.width
                                text: {
                                    let bodyText = modelData?.body || "";
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

                        Row {
                            id: messageControls

                            anchors.right: parent.right
                            anchors.rightMargin: -6
                            anchors.top: parent.top
                            spacing: 4

                            Rectangle {
                                width: 20
                                height: 20
                                radius: 10
                                color: expandMessageArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"
                                visible: (modelData?.body || "").length > 80

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: {
                                        const messageExpanded = NotificationService.expandedMessages[modelData?.notification?.id] || false;
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
                                    onClicked: NotificationService.toggleMessageExpansion(modelData?.notification?.id || "")
                                }
                            }

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

    Rectangle {
        property bool isHovered: false

        anchors.right: dismissButton.left
        anchors.rightMargin: 4
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        width: viewText.width + 16
        height: viewText.height + 8
        radius: 6
        color: isHovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1) : "transparent"

        Text {
            id: viewText

            text: "View"
            color: parent.isHovered ? Theme.primary : Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: parent.isHovered = true
            onExited: parent.isHovered = false
            onClicked: {
                if (notificationGroup?.latestNotification?.actions) {
                    for (const action of notificationGroup.latestNotification.actions) {
                        if (action.text && action.text.toLowerCase() === "view") {
                            if (action.invoke) {
                                action.invoke();
                                return;
                            }
                        }
                    }
                    if (notificationGroup.latestNotification.actions.length > 0) {
                        const firstAction = notificationGroup.latestNotification.actions[0];
                        if (firstAction.invoke)
                            firstAction.invoke();
                    }
                }
            }
        }
    }

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

        Text {
            id: dismissText

            text: "Dismiss"
            color: dismissButton.isHovered ? Theme.primary : Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: dismissButton.isHovered = true
            onExited: dismissButton.isHovered = false
            onClicked: NotificationService.dismissGroup(notificationGroup?.key || "")
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: !expanded && (notificationGroup?.count || 0) > 1
        onClicked: NotificationService.toggleGroupExpansion(notificationGroup?.key || "")
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