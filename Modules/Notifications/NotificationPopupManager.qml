import QtQuick
import Quickshell
import qs.Common
import qs.Services

QtObject {
    id: manager

    property var popupLoaders: []
    property int maxTargetNotifications: 3
    property int baseNotificationHeight: 132
    property bool dismissalInProgress: false

    property Timer dismissalTimer: Timer {
        interval: 200
        repeat: false
        onTriggered: dismissNextOldest()
    }

    property Component popupLoaderComponent: Component {
        Loader {
            id: popupLoader

            property var notifWrapper

            active: false
            asynchronous: true

            sourceComponent: NotificationPopup {
                id: popup

                notificationData: popupLoader.notifWrapper
                notificationId: popupLoader.notifWrapper ? popupLoader.notifWrapper.notification.id : ""
                onEntered: manager._onPopupEntered(popupLoader)
                onSlideOutChanged: {
                    if (slideOut) {
                        manager._onPopupExitStarted(popupLoader);
                    }
                }
                onExitFinished: manager._onPopupExitFinished(popupLoader)
            }
        }
    }

    property Connections notificationConnections: Connections {
        function onVisibleNotificationsChanged() {
            syncPopupsWithQueue(NotificationService.visibleNotifications);
        }

        target: NotificationService
    }

    function _createPopupLoader(notifWrapper) {
        const L = popupLoaderComponent.createObject(manager, {
            "notifWrapper": notifWrapper
        });
        popupLoaders.push(L);
        return L;
    }

    function _destroyPopupLoader(L) {
        const i = popupLoaders.indexOf(L);
        if (i !== -1) {
            popupLoaders.splice(i, 1);
            popupLoaders = popupLoaders.slice();
        }
        L.active = false;
        L.sourceComponent = null;
    }

    function _activeItems() {
        return popupLoaders.filter((L) => {
            return L.item && L.item.notificationData && L.item.notificationData.popup;
        });
    }

    function _stableItems() {
        return _activeItems().filter((L) => {
            return !L.item.entering;
        });
    }

    function repositionAll() {
        const stable = _stableItems();
        for (let i = 0; i < stable.length; ++i) {
            const it = stable[i].item;
            if (it)
                it.verticalOffset = i * baseNotificationHeight;

        }
    }

    function syncPopupsWithQueue(newWrappers) {
        for (let w of newWrappers) {
            if (!popupLoaders.some((L) => {
                return L.notifWrapper === w;
            })) {
                const L = _createPopupLoader(w);
                const actives = _activeItems().length;
                w.initialOffset = actives * baseNotificationHeight;
                L.active = true;
            }
        }
        for (let L of popupLoaders.slice()) {
            if (newWrappers.indexOf(L.notifWrapper) === -1)
                _destroyPopupLoader(L);

        }
        repositionAll();
    }

    function _onPopupEntered(L) {
        repositionAll();
        maybeStartOverflow();
    }

    function _onPopupExitStarted(L) {
        const it = L.item;
        if (!it)
            return ;

        if (it.shadowLayers) {
            for (let layer of it.shadowLayers) {
                if (layer)
                    layer.visible = false;

            }
        }
        if (it.iconContainer && it.iconContainer.iconImage) {
            it.iconContainer.iconImage.source = "";
        }
    }

    function _onPopupExitFinished(L) {
        NotificationService.releaseWrapper(L.notifWrapper);
        _destroyPopupLoader(L);
        repositionAll();
        maybeStartOverflow();
    }

    function maybeStartOverflow() {
        const active = _activeItems();
        if (dismissalInProgress)
            return ;

        if (active.length > maxTargetNotifications)
            startSequentialDismissal();

    }

    function startSequentialDismissal() {
        dismissalInProgress = true;
        dismissNextOldest();
    }

    function dismissNextOldest() {
        const active = _activeItems();
        if (active.length <= maxTargetNotifications) {
            dismissalInProgress = false;
            return ;
        }
        const oldest = active[0].item;
        if (oldest) {
            oldest.notificationData.removedByLimit = true;
            oldest.notificationData.popup = false;
            dismissalTimer.restart();
        }
    }


}
