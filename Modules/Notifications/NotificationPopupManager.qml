import QtQuick
import Quickshell
import qs.Common
import qs.Services

QtObject {
    id: manager
    property int topMargin: 48
    property int baseNotificationHeight: 132
    property int maxTargetNotifications: 3
    property var popupWindows: []   // strong refs to windows (live until exitFinished)

    // Factory
    property Component popupComponent: Component {
        NotificationPopup {
            onEntered: manager._onPopupEntered(this)
            onExitFinished: manager._onPopupExitFinished(this)
        }
    }

    property Connections notificationConnections: Connections {
        target: NotificationService
        function onVisibleNotificationsChanged() {
            manager._sync(NotificationService.visibleNotifications);
        }
    }

    function _hasWindowFor(w) { 
        return popupWindows.some(p => p && p.notificationData === w); 
    }

    function _sync(newWrappers) {
        for (let w of newWrappers) {
            if (!_hasWindowFor(w)) insertNewestAtTop(w);
        }
        for (let p of popupWindows.slice()) {
            if (p && p.notificationData && newWrappers.indexOf(p.notificationData) === -1 && !p.exiting) {
                p.notificationData.removedByLimit = true;
                p.notificationData.popup = false;
            }
        }
    }

    // Insert newest at top
    function insertNewestAtTop(wrapper) {
        // Shift live, non-exiting windows down *now*
        for (let p of popupWindows) {
            if (!p) continue;
            if (p.exiting) continue;
            // Guard: skip if p is already being destroyed
            if (p.status === Component.Null) continue;
            p.screenY = p.screenY + baseNotificationHeight;
        }

        // Create the new top window at fixed Y
        const notificationId = wrapper && wrapper.notification ? wrapper.notification.id : "";
        const win = popupComponent.createObject(null, { notificationData: wrapper, notificationId: notificationId, screenY: topMargin });
        if (!win) { 
            console.warn("Popup create failed"); 
            return; 
        }
        popupWindows.push(win);

        _maybeStartOverflow();
    }


    // Overflow: keep one extra (slot #4), then ask bottom to exit gracefully
    function _active() { 
        return popupWindows.filter(p => p && p.notificationData && p.notificationData.popup); 
    }
    
    function _bottom() {
        let b = null, maxY = -1;
        for (let p of _active()) {
            if (p.exiting) continue;
            if (p.screenY > maxY) { 
                maxY = p.screenY; 
                b = p; 
            }
        }
        return b;
    }
    
    function _maybeStartOverflow() {
        if (_active().length <= maxTargetNotifications + 1) return;
        const b = _bottom();
        if (b && !b.exiting) {
            // Tell the popup to animate out (don't destroy here)
            b.notificationData.removedByLimit = true;
            b.notificationData.popup = false;
        }
    }

    // After entrance, you may kick overflow (optional)
    function _onPopupEntered(p) { 
        _maybeStartOverflow(); 
    }

    // Primary cleanup path (after the popup finishes its exit)
    function _onPopupExitFinished(p) {
        const i = popupWindows.indexOf(p);
        if (i !== -1) { 
            popupWindows.splice(i,1); 
            popupWindows = popupWindows.slice(); 
        }
        if (NotificationService.releaseWrapper) 
            NotificationService.releaseWrapper(p.notificationData);
        // Finally destroy the window object
        p.destroy();

        // Compact survivors (only live, non-exiting)
        const survivors = _active().filter(s => !s.exiting)
                          .sort((a,b) => a.screenY - b.screenY);
        for (let k = 0; k < survivors.length; ++k)
            survivors[k].screenY = topMargin + k * baseNotificationHeight;

        _maybeStartOverflow();
    }

    // Optional sweeper (dev only): catch any stranded windows every 2s
    property Timer sweeper: Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            for (let p of popupWindows.slice()) {
                if (!p) continue;
                if (!p.visible && !p.notificationData) {
                    const i = popupWindows.indexOf(p);
                    if (i !== -1) { 
                        popupWindows.splice(i,1); 
                        popupWindows = popupWindows.slice(); 
                    }
                }
            }
        }
    }
}