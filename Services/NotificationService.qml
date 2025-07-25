pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.Services

Singleton {
    id: root

    readonly property list<NotifWrapper> notifications: []
    readonly property list<NotifWrapper> popups: notifications.filter(n => n.popup)
    
    // Android 16-style grouped notifications
    readonly property var groupedNotifications: getGroupedNotifications()
    readonly property var groupedPopups: getGroupedPopups()
    
    property var expandedGroups: ({})
    property var expandedMessages: ({})
    property bool popupsDisabled: false
    
    // Notification persistence settings
    property int maxStoredNotifications: 100
    property int maxNotificationAge: 7 * 24 * 60 * 60 * 1000 // 7 days in milliseconds
    property var persistedNotifications: ([]) // Stored notification history

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        actionIconsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        inlineReplySupported: true

        onNotification: notif => {
            
            
            notif.tracked = true;

            const wrapper = notifComponent.createObject(root, {
                popup: !notif.transient, // Transient notifications show as popups but don't persist
                notification: notif
            });

            if (wrapper) {
                const groupKey = getGroupKey(wrapper);
                
                // Only add to notifications list if not transient
                if (!notif.transient) {
                    root.notifications.push(wrapper);
                    addToPersistentStorage(wrapper);
                }
            }
        }
    }

    component NotifWrapper: QtObject {
        id: wrapper

        property bool popup: false
        
        Component.onCompleted: {
            popup = !root.popupsDisabled && !notification.transient;
        }
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
        readonly property string desktopEntry: notification.desktopEntry
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

        readonly property Connections conn: Connections {
            target: wrapper.notification.Retainable

            function onDropped(): void {
                const index = root.notifications.indexOf(wrapper);
                if (index !== -1) {
                    // Get the group key before removing the notification
                    const groupKey = getGroupKey(wrapper);
                    root.notifications.splice(index, 1);
                    
                    // Check if this group now has no notifications left or only 1 left
                    const remainingInGroup = root.notifications.filter(n => getGroupKey(n) === groupKey);
                    if (remainingInGroup.length === 0) {
                        // Immediately clear expansion state for empty group
                        clearGroupExpansionState(groupKey);
                    } else if (remainingInGroup.length === 1) {
                        // Collapse groups that only have 1 notification left
                        clearGroupExpansionState(groupKey);
                    }
                    
                    // Clean up all expansion states
                    cleanupExpansionStates();
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
        // Actually dismiss all notifications from center
        const notificationsCopy = [...root.notifications];
        notificationsCopy.forEach(notif => {
            notif.notification.dismiss();
        });
        // Clear all expansion states
        expandedGroups = {};
        expandedMessages = {};
    }

    function dismissNotification(wrapper) {
        wrapper.notification.dismiss();
    }
    
    function hidePopup(wrapper) {
        wrapper.popup = false;
    }
    
    function disablePopups(disable) {
        popupsDisabled = disable;
        if (disable) {
            for (const notif of root.notifications) {
                notif.popup = false;
            }
        }
    }


    // Android 16-style notification grouping functions
    function getGroupKey(wrapper) {
        // Priority 1: Use desktopEntry if available
        if (wrapper.desktopEntry && wrapper.desktopEntry !== "") {
            return wrapper.desktopEntry.toLowerCase();
        }
        
        // Priority 2: Use appName as fallback
        return wrapper.appName.toLowerCase();
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
            const aUrgency = a.latestNotification.urgency || 0;
            const bUrgency = b.latestNotification.urgency || 0;
            if (aUrgency !== bUrgency) {
                return bUrgency - aUrgency;
            }
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
            const aUrgency = a.latestNotification.urgency || 0;
            const bUrgency = b.latestNotification.urgency || 0;
            if (aUrgency !== bUrgency) {
                return bUrgency - aUrgency;
            }
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
        const group = groupedNotifications.find(g => g.key === groupKey);
        if (group) {
            for (const notif of group.notifications) {
                notif.notification.dismiss();
            }
        }
    }
    
    function clearGroupExpansionState(groupKey) {
        let newExpandedGroups = {};
        for (const key in expandedGroups) {
            if (key !== groupKey && expandedGroups[key]) {
                newExpandedGroups[key] = true;
            }
        }
        expandedGroups = newExpandedGroups;
    }

    function cleanupExpansionStates() {
        const currentGroupKeys = new Set(groupedNotifications.map(g => g.key));
        const currentMessageIds = new Set();
        for (const group of groupedNotifications) {
            for (const notif of group.notifications) {
                currentMessageIds.add(notif.notification.id);
            }
        }
        let newExpandedGroups = {};
        for (const key in expandedGroups) {
            if (currentGroupKeys.has(key) && expandedGroups[key]) {
                newExpandedGroups[key] = true;
            }
        }
        expandedGroups = newExpandedGroups;
        let newExpandedMessages = {};
        for (const messageId in expandedMessages) {
            if (currentMessageIds.has(messageId) && expandedMessages[messageId]) {
                newExpandedMessages[messageId] = true;
            }
        }
        expandedMessages = newExpandedMessages;
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
        return `${group.count} notifications`;
    }
    function getGroupBody(group) {
        if (group.count === 1) {
            return group.latestNotification.body;
        }
        return `Latest: ${group.latestNotification.summary}`;
    }

    function addToPersistentStorage(wrapper) {
        const persistedNotif = {
            id: wrapper.notification.id,
            appName: wrapper.appName,
            summary: wrapper.summary,
            body: wrapper.body,
            appIcon: wrapper.appIcon,
            image: wrapper.image,
            urgency: wrapper.urgency,
            timestamp: wrapper.time.getTime(),
        };
        persistedNotifications.unshift(persistedNotif);
        cleanupPersistentStorage();
    }

    function cleanupPersistentStorage() {
        const now = new Date().getTime();
        let newPersisted = [];
        for (let i = 0; i < persistedNotifications.length && i < maxStoredNotifications; i++) {
            const notif = persistedNotifications[i];
            if (now - notif.timestamp < maxNotificationAge) {
                newPersisted.push(notif);
            }
        }
        persistedNotifications = newPersisted;
    }

    function getPersistentNotificationsByApp(appName) {
        return persistedNotifications.filter(notif => notif.appName.toLowerCase() === appName.toLowerCase());
    }
    function getPersistentNotificationsByType(type) {
        return persistedNotifications;
    }
    function searchPersistentNotifications(query) {
        const searchLower = query.toLowerCase();
        return persistedNotifications.filter(notif => 
            notif.appName.toLowerCase().includes(searchLower) ||
            notif.summary.toLowerCase().includes(searchLower) ||
            notif.body.toLowerCase().includes(searchLower)
        );
    }
    Component.onCompleted: {
        cleanupPersistentStorage();
    }
}