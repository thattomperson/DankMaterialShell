pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property list<NotifWrapper> notifications: []
    readonly property list<NotifWrapper> popups: notifications.filter(n => n.popup)
    
    // Android 16-style grouped notifications
    readonly property var groupedNotifications: getGroupedNotifications()
    readonly property var groupedPopups: getGroupedPopups()
    
    property var expandedGroups: ({}) // Track which groups are expanded
    property var expandedMessages: ({}) // Track which individual messages are expanded

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        inlineReplySupported: true

        onNotification: notif => {
            console.log("=== RAW NOTIFICATION DATA ===");
            console.log("appName:", notif.appName);
            console.log("summary:", notif.summary);
            console.log("body:", notif.body);
            console.log("appIcon:", notif.appIcon);
            console.log("image:", notif.image);
            console.log("urgency:", notif.urgency);
            console.log("=============================");
            notif.tracked = true;

            const wrapper = notifComponent.createObject(root, {
                popup: true,
                notification: notif
            });

            if (wrapper) {
                root.notifications.push(wrapper);
                console.log("Notification added. Total notifications:", root.notifications.length);
                console.log("Grouped notifications:", root.groupedNotifications.length);
            } else {
                console.error("Failed to create notification wrapper");
            }
        }
    }

    component NotifWrapper: QtObject {
        id: wrapper

        property bool popup: true
        readonly property date time: new Date()
        readonly property string timeStr: {
            const now = new Date();
            const diff = now.getTime() - time.getTime();
            const m = Math.floor(diff / 60000);
            const h = Math.floor(m / 60);

            if (h < 1 && m < 1)
                return "now";
            if (h < 1)
                return `${m}m`;
            return `${h}h`;
        }

        required property Notification notification
        readonly property string summary: notification.summary
        readonly property string body: notification.body
        readonly property string appIcon: notification.appIcon
        readonly property string cleanAppIcon: {
            if (!appIcon) return "";
            if (appIcon.startsWith("file://")) {
                return appIcon.substring(7);
            }
            return appIcon;
        }
        readonly property string appName: notification.appName
        readonly property string image: notification.image
        readonly property string cleanImage: {
            if (!image) return "";
            if (image.startsWith("file://")) {
                return image.substring(7);
            }
            return image;
        }
        readonly property int urgency: notification.urgency
        readonly property list<NotificationAction> actions: notification.actions

        // Enhanced properties for better handling
        readonly property bool hasImage: image && image.length > 0
        readonly property bool hasAppIcon: appIcon && appIcon.length > 0
        readonly property bool isConversation: notification.hasInlineReply
        readonly property bool isMedia: detectIsMedia()
        readonly property bool isSystem: detectIsSystem()


        function detectIsMedia() {
            const appNameLower = appName.toLowerCase();
            const summaryLower = summary.toLowerCase();
            
            return appNameLower.includes("spotify") ||
                   appNameLower.includes("vlc") ||
                   appNameLower.includes("mpv") ||
                   appNameLower.includes("music") ||
                   appNameLower.includes("player") ||
                   summaryLower.includes("now playing") ||
                   summaryLower.includes("playing");
        }

        function detectIsSystem() {
            const appNameLower = appName.toLowerCase();
            const summaryLower = summary.toLowerCase();
            
            return appNameLower.includes("system") ||
                   appNameLower.includes("update") ||
                   summaryLower.includes("update") ||
                   summaryLower.includes("system");
        }


        readonly property Timer timer: Timer {
            running: wrapper.popup
            interval: wrapper.notification.expireTimeout > 0 ? wrapper.notification.expireTimeout : 5000 // 5 second default
            onTriggered: {
                wrapper.popup = false;
            }
        }

        readonly property Connections conn: Connections {
            target: wrapper.notification.Retainable

            function onDropped(): void {
                const index = root.notifications.indexOf(wrapper);
                if (index !== -1) {
                    root.notifications.splice(index, 1);
                }
            }

            function onAboutToDestroy(): void {
                wrapper.destroy();
            }
        }
    }

    Component {
        id: notifComponent
        NotifWrapper {}
    }

    // Helper functions
    function clearAllNotifications() {
        // Create a copy of the array to avoid modification during iteration
        const notificationsCopy = [...root.notifications];
        for (const notif of notificationsCopy) {
            notif.notification.dismiss();
        }
    }

    function dismissNotification(wrapper) {
        wrapper.notification.dismiss();
    }


    // Android 16-style notification grouping functions
    function getGroupKey(wrapper) {
        const appName = wrapper.appName.toLowerCase();
        
        // Conversation apps with inline reply
        if (wrapper.isConversation) {
            const summary = wrapper.summary.toLowerCase();
            
            // Group by conversation/channel name from summary
            if (summary.includes("#")) {
                const channelMatch = summary.match(/#[\w-]+/);
                if (channelMatch) {
                    return `${appName}:${channelMatch[0]}`;
                }
            }
            
            // Group by sender/conversation name if meaningful
            if (summary && !summary.includes("new message") && !summary.includes("notification")) {
                return `${appName}:${summary}`;
            }
            
            // Default conversation grouping
            return `${appName}:conversation`;
        }
        
        
        // Media: Replace previous media notification from same app
        if (wrapper.isMedia) {
            return `${appName}:media`;
        }
        
        // System: Group by type
        if (wrapper.isSystem) {
            const summary = wrapper.summary.toLowerCase();
            if (summary.includes("update")) {
                return "system:updates";
            }
            if (summary.includes("battery")) {
                return "system:battery";
            }
            if (summary.includes("network")) {
                return "system:network";
            }
            return "system:general";
        }
        
        // Default: Group by app
        return appName;
    }

    function getGroupedNotifications() {
        const groups = {};
        
        for (const notif of notifications) {
            const groupKey = getGroupKey(notif);
            if (!groups[groupKey]) {
                groups[groupKey] = {
                    key: groupKey,
                    appName: notif.appName,
                    notifications: [],
                    latestNotification: null,
                    count: 0,
                    hasInlineReply: false,
                    isConversation: notif.isConversation,
                    isMedia: notif.isMedia,
                    isSystem: notif.isSystem
                };
            }
            
            groups[groupKey].notifications.unshift(notif);
            groups[groupKey].latestNotification = groups[groupKey].notifications[0];
            groups[groupKey].count = groups[groupKey].notifications.length;
            
            if (notif.notification.hasInlineReply) {
                groups[groupKey].hasInlineReply = true;
            }
        }
        
        return Object.values(groups).sort((a, b) => {
            return b.latestNotification.time.getTime() - a.latestNotification.time.getTime();
        });
    }

    function getGroupedPopups() {
        const groups = {};
        
        for (const notif of popups) {
            const groupKey = getGroupKey(notif);
            if (!groups[groupKey]) {
                groups[groupKey] = {
                    key: groupKey,
                    appName: notif.appName,
                    notifications: [],
                    latestNotification: null,
                    count: 0,
                    hasInlineReply: false,
                    isConversation: notif.isConversation,
                    isMedia: notif.isMedia,
                    isSystem: notif.isSystem
                };
            }
            
            groups[groupKey].notifications.unshift(notif);
            groups[groupKey].latestNotification = groups[groupKey].notifications[0];
            groups[groupKey].count = groups[groupKey].notifications.length;
            
            if (notif.notification.hasInlineReply) {
                groups[groupKey].hasInlineReply = true;
            }
        }
        
        return Object.values(groups).sort((a, b) => {
            return b.latestNotification.time.getTime() - a.latestNotification.time.getTime();
        });
    }

    function toggleGroupExpansion(groupKey) {
        let newExpandedGroups = {};
        for (const key in expandedGroups) {
            newExpandedGroups[key] = expandedGroups[key];
        }
        newExpandedGroups[groupKey] = !newExpandedGroups[groupKey];
        expandedGroups = newExpandedGroups;
    }

    function dismissGroup(groupKey) {
        // Use array iteration to avoid spread operator issues
        for (let i = notifications.length - 1; i >= 0; i--) {
            const notif = notifications[i];
            if (getGroupKey(notif) === groupKey) {
                notif.notification.dismiss();
            }
        }
    }

    function toggleMessageExpansion(messageId) {
        let newExpandedMessages = {};
        for (const key in expandedMessages) {
            newExpandedMessages[key] = expandedMessages[key];
        }
        newExpandedMessages[messageId] = !newExpandedMessages[messageId];
        expandedMessages = newExpandedMessages;
    }

    function getGroupTitle(group) {
        if (group.count === 1) {
            return group.latestNotification.summary;
        }
        
        if (group.isConversation) {
            const keyParts = group.key.split(":");
            if (keyParts.length > 1) {
                const conversationKey = keyParts[keyParts.length - 1];
                if (conversationKey !== "conversation") {
                    return `${conversationKey}: ${group.count} messages`;
                }
            }
            return `${group.count} new messages`;
        }
        
        if (group.isMedia) {
            return "Now playing";
        }
        
        
        if (group.isSystem) {
            const keyParts = group.key.split(":");
            if (keyParts.length > 1) {
                const systemType = keyParts[1];
                switch (systemType) {
                    case "updates": return `${group.count} system updates`;
                    case "battery": return `${group.count} battery notifications`;
                    case "network": return `${group.count} network notifications`;
                    default: return `${group.count} system notifications`;
                }
            }
            return `${group.count} system notifications`;
        }
        
        return `${group.count} notifications`;
    }

    function getGroupBody(group) {
        if (group.count === 1) {
            return group.latestNotification.body;
        }
        
        if (group.isConversation) {
            const latest = group.latestNotification;
            if (latest.body && latest.body.length > 0) {
                return latest.body;
            }
            return "Tap to view conversation";
        }
        
        if (group.isMedia) {
            return group.latestNotification.body || "Media playback";
        }
        
        
        return `Latest: ${group.latestNotification.summary}`;
    }
}