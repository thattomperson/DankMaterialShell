import QtQuick
import Quickshell
import qs.Common
import qs.Services

QtObject {
    id: manager

    property int maxTargetNotifications: 3
    property int baseNotificationHeight: 132
    property int topMargin: 0
    property var popupWindows: []

    property Component popupComponent: Component {
        NotificationPopup {
            property var wrapper
            notificationData: wrapper
            notificationId: wrapper.notification.id
            rowHeight: manager.baseNotificationHeight
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

    function _hasWindowFor(w) { return popupWindows.some(p => p && p.notificationData === w); }

    function _sync(newWrappers) {
        for (let w of newWrappers) {
            if (!_hasWindowFor(w)) _insertNewestAtTop(w);
        }
        for (let p of popupWindows.slice()) {
            if (newWrappers.indexOf(p.notificationData) === -1 && p && !p.exiting) {
                p.notificationData.removedByLimit = true;
                p.notificationData.popup = false;
            }
        }
    }

    function _insertNewestAtTop(wrapper) {
        for (let p of popupWindows) {
            if (p && p.notificationData && p.notificationData.popup && !p.exiting) {
                p.screenY = p.screenY + baseNotificationHeight;
            }
        }

        const win = popupComponent.createObject(null, { wrapper: wrapper, screenY: topMargin });
        if (!win) {
            console.warn("Popup create failed");
            return;
        }
        popupWindows.push(win);
        _maybeStartOverflow();
    }

    function _active() {
        return popupWindows.filter(p => p && p.notificationData && p.notificationData.popup);
    }

    function _bottom() {
        let b = null, max = -1;
        for (let p of _active()) {
            if (!p.exiting && p.screenY > max) {
                max = p.screenY;
                b = p;
            }
        }
        return b;
    }

    function _maybeStartOverflow() {
        if (_active().length <= maxTargetNotifications + 1) return;
        const b = _bottom();
        if (b && !b.exiting) {
            b.notificationData.removedByLimit = true;
            b.notificationData.popup = false;
        }
    }

    function _onPopupEntered(p) {
        // Entry completed
    }

    function _onPopupExitFinished(p) {
        const i = popupWindows.indexOf(p);
        if (i !== -1) {
            popupWindows.splice(i, 1);
            popupWindows = popupWindows.slice();
        }
        if (NotificationService.releaseWrapper) NotificationService.releaseWrapper(p.notificationData);
        p.destroy();

        const survivors = _active().filter(s => !s.exiting).sort((a,b) => a.screenY - b.screenY);
        for (let k = 0; k < survivors.length; ++k)
            survivors[k].screenY = topMargin + k * baseNotificationHeight;

        _maybeStartOverflow();
    }
}