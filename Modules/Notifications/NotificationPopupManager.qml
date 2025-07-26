import QtQuick
import qs.Common
import qs.Services

Item {
    id: root

    property list<var> popupInstances: []
    property int baseNotificationHeight: 130 // Height of a single notification + margins
    property bool dismissalInProgress: false
    property int maxTargetNotifications: 3 // Target number of notifications to maintain
    
    Timer {
        id: dismissalTimer
        interval: 500 // Half second delay between dismissals
        onTriggered: dismissNextOldest()
    }
    
    Timer {
        id: dismissalDelayTimer
        interval: 1 // Start immediately 
        onTriggered: startSequentialDismissal()
    }

    Component {
        id: popupComponent
        NotificationPopup {}
    }

    Connections {
        target: NotificationService
        function onNotificationQueueChanged() {
            syncPopupsWithQueue();
            repositionAll();
        }
        function onVisibleNotificationsChanged() {
            repositionAll();
        }
    }


    function syncPopupsWithQueue() {
        const queue = NotificationService.notificationQueue.filter(n => n && n.popup);
        
        // Clean up destroyed popups first
        popupInstances = popupInstances.filter(p => p && p.notificationId);
        
        // DON'T aggressively destroy popups - let them handle their own lifecycle
        // Only remove popups that are actually destroyed/invalid
        // The popup will destroy itself when notificationData.popup becomes false
        
        // Only create NEW notifications, don't touch existing ones AT ALL
        for (const notif of queue) {
            const existingPopup = popupInstances.find(p => p.notificationId === notif.notification.id);
            if (existingPopup) {
                // CRITICAL: Do absolutely NOTHING to existing popups
                // Don't change their verticalOffset, don't touch any properties
                continue;
            }
            
            // Calculate position for NEW notification only - at the bottom of ACTIVE stack
            const currentActive = popupInstances.filter(p => p && p.notificationData && p.notificationData.popup).length;
            const popup = popupComponent.createObject(root, {
                notificationData: notif,
                notificationId: notif.notification.id,
                verticalOffset: currentActive * baseNotificationHeight  // ✅ bottom of active stack
            });
            
            if (popup) {
                popupInstances.push(popup);

                // Pin it until entrance finishes, then maybe start overflow
                popup.entered.connect(function() {
                    repositionAll();                 // it's now "stable"; allow vertical compaction
                    maybeStartOverflow();            // defer overflow until after slot N is fully occupied
                });
            }
        }
        
        // Overflow dismissal handled in Connections now
    }
    
    function repositionAll() {
        // Only compact stable (non-entering) active popups
        const stable = popupInstances.filter(p => p && p.notificationData && p.notificationData.popup && !p.entering);
        for (let i = 0; i < stable.length; ++i)
            stable[i].verticalOffset = i * baseNotificationHeight;

        // Newcomers keep their creation-time offset (slot N) until `entered()`
    }
    
    function maybeStartOverflow() {
        const active = popupInstances.filter(p => p && p.notificationData && p.notificationData.popup);
        if (active.length > maxTargetNotifications && !dismissalInProgress)
            startSequentialDismissal();
    }
    
    function startSequentialDismissal() {
        if (dismissalInProgress) return; // Don't start multiple dismissals
        
        dismissalInProgress = true;
        dismissNextOldest();
    }
    
    function dismissNextOldest() {
        const active = popupInstances.filter(p => p && p.notificationData.popup);
        if (active.length <= maxTargetNotifications) { dismissalInProgress = false; return; }
        const oldest = active[0];
        if (oldest) {
            oldest.notificationData.removedByLimit = true;
            oldest.notificationData.popup = false;  // triggers slide-out in popup
            dismissalTimer.restart();               // your existing 500ms is fine
        }
    }
}