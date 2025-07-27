import QtQuick
import Quickshell
import qs.Common
import qs.Services

QtObject {
    id: manager
    
    property var modelData
       
    property int topMargin: 0
    property int baseNotificationHeight: 120
    property int maxTargetNotifications: 3
    property var popupWindows: []   // strong refs to windows (live until exitFinished)

    // Track destroying windows to prevent duplicate cleanup
    property var destroyingWindows: new Set()

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
        return popupWindows.some(p => {
            // More robust check for valid windows
            return p && 
                   p.notificationData === w && 
                   !p._isDestroying &&
                   p.status !== Component.Null;
        });
    }

    function _isValidWindow(p) {
        return p && 
               p.status !== Component.Null && 
               !p._isDestroying &&
               p.hasValidData;
    }

    function _sync(newWrappers) {
        // Add new notifications
        for (let w of newWrappers) {
            if (w && !_hasWindowFor(w)) {
                insertNewestAtTop(w);
            }
        }
        
        // Remove old notifications
        for (let p of popupWindows.slice()) {
            if (!_isValidWindow(p)) continue;
            
            if (p.notificationData && newWrappers.indexOf(p.notificationData) === -1 && !p.exiting) {
                p.notificationData.removedByLimit = true;
                p.notificationData.popup = false;
            }
        }
    }

    // Insert newest at top
    function insertNewestAtTop(wrapper) {
        if (!wrapper) {
            console.warn("insertNewestAtTop: wrapper is null");
            return;
        }
        
        // Shift live, non-exiting windows down *now*
        for (let p of popupWindows) {
            if (!_isValidWindow(p)) continue;
            if (p.exiting) continue;
            
            p.screenY = p.screenY + baseNotificationHeight;
        }

        // Create the new top window at fixed Y
        const notificationId = wrapper && wrapper.notification ? wrapper.notification.id : "";
        const win = popupComponent.createObject(null, { 
            notificationData: wrapper, 
            notificationId: notificationId, 
            screenY: topMargin,
            screen: manager.modelData
        });
        
        if (!win) { 
            console.warn("Popup create failed"); 
            return; 
        }
        
        // Validate the window was created properly
        if (!win.hasValidData) {
            console.warn("Popup created with invalid data, destroying");
            win.destroy();
            return;
        }
        
        popupWindows.push(win);
        
        // Start sweeper if it's not running
        if (!sweeper.running) {
            sweeper.start();
        }
        
        _maybeStartOverflow();
    }

    // Overflow: keep one extra (slot #4), then ask bottom to exit gracefully
    function _active() { 
        return popupWindows.filter(p => {
            return _isValidWindow(p) && 
                   p.notificationData && 
                   p.notificationData.popup &&
                   !p.exiting;
        });
    }
    
    function _bottom() {
        let b = null, maxY = -1;
        for (let p of _active()) {
            if (p.screenY > maxY) { 
                maxY = p.screenY; 
                b = p; 
            }
        }
        return b;
    }
    
    function _maybeStartOverflow() {
        const activeWindows = _active();
        if (activeWindows.length <= maxTargetNotifications + 1) return;
        
        const b = _bottom();
        if (b && !b.exiting) {
            // Tell the popup to animate out (don't destroy here)
            b.notificationData.removedByLimit = true;
            b.notificationData.popup = false;
        }
    }

    // After entrance, you may kick overflow (optional)
    function _onPopupEntered(p) {
        if (_isValidWindow(p)) {
            _maybeStartOverflow();
        }
    }

    // Primary cleanup path (after the popup finishes its exit)
    function _onPopupExitFinished(p) {
        if (!p) return;
        
        // Prevent duplicate cleanup
        const windowId = p.toString();
        if (destroyingWindows.has(windowId)) {
            return;
        }
        destroyingWindows.add(windowId);
        
        // Remove from popupWindows
        const i = popupWindows.indexOf(p);
        if (i !== -1) { 
            popupWindows.splice(i, 1);
            popupWindows = popupWindows.slice(); 
        }
        
        // Release the wrapper
        if (NotificationService.releaseWrapper && p.notificationData) {
            NotificationService.releaseWrapper(p.notificationData);
        }
        
        // Schedule destruction
        Qt.callLater(() => {
            if (p && p.destroy) {
                try {
                    p.destroy();
                } catch (e) {
                    console.warn("Error destroying popup:", e);
                }
            }
            // Clean up tracking after a delay
            Qt.callLater(() => {
                destroyingWindows.delete(windowId);
            });
        });

        // Compact survivors (only live, non-exiting)
        const survivors = _active().sort((a, b) => a.screenY - b.screenY);
        for (let k = 0; k < survivors.length; ++k) {
            survivors[k].screenY = topMargin + k * baseNotificationHeight;
        }

        _maybeStartOverflow();
    }

    // Smart sweeper that only runs when needed
    property Timer sweeper: Timer {
        interval: 2000
        running: false  // Not running by default
        repeat: true
        onTriggered: {
            let toRemove = [];
            
            for (let p of popupWindows) {
                if (!p) {
                    toRemove.push(p);
                    continue;
                }
                
                // Check for various zombie conditions
                const isZombie = 
                    p.status === Component.Null ||
                    (!p.visible && !p.exiting) ||
                    (!p.notificationData && !p._isDestroying) ||
                    (!p.hasValidData && !p._isDestroying);
                
                if (isZombie) {
                    console.warn("Sweeper found zombie window, cleaning up");
                    toRemove.push(p);
                    
                    // Try to force cleanup
                    if (p.forceExit) {
                        p.forceExit();
                    } else if (p.destroy) {
                        try {
                            p.destroy();
                        } catch (e) {
                            console.warn("Error destroying zombie:", e);
                        }
                    }
                }
            }
            
            // Remove all zombies from array
            if (toRemove.length > 0) {
                for (let zombie of toRemove) {
                    const i = popupWindows.indexOf(zombie);
                    if (i !== -1) {
                        popupWindows.splice(i, 1);
                    }
                }
                popupWindows = popupWindows.slice();
                
                // Recompact after cleanup
                const survivors = _active().sort((a, b) => a.screenY - b.screenY);
                for (let k = 0; k < survivors.length; ++k) {
                    survivors[k].screenY = topMargin + k * baseNotificationHeight;
                }
            }
            
            // Stop the timer if no windows remain
            if (popupWindows.length === 0) {
                sweeper.stop();
            }
        }
    }
    
    // Watch for changes to popup windows array
    onPopupWindowsChanged: {
        if (popupWindows.length > 0 && !sweeper.running) {
            sweeper.start();
        } else if (popupWindows.length === 0 && sweeper.running) {
            sweeper.stop();
        }
    }
    
    // Emergency cleanup function
    function cleanupAllWindows() {
        sweeper.stop();
        
        for (let p of popupWindows.slice()) {
            if (p) {
                try {
                    if (p.forceExit) p.forceExit();
                    else if (p.destroy) p.destroy();
                } catch (e) {
                    console.warn("Error during emergency cleanup:", e);
                }
            }
        }
        
        popupWindows = [];
        destroyingWindows.clear();        
    }
}