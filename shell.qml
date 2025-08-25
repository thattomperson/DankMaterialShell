//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Modals
import qs.Modules
import qs.Modules.AppDrawer
import qs.Modules.OSD
import qs.Modules.CentcomCenter
import qs.Modules.ControlCenter
import qs.Modules.ControlCenter.Network
import qs.Modules.Lock
import qs.Modules.Notifications.Center
import qs.Modules.Notifications.Popup
import qs.Modules.ProcessList
import qs.Modules.Settings
import qs.Modules.TopBar
import qs.Modules.Dock
import qs.Services
import qs.Common

ShellRoot {
    id: root

    Component.onCompleted: {
        PortalService.init()
    }

    WallpaperBackground {}

    Lock {
        id: lock

        anchors.fill: parent
    }

    Variants {
        model: SettingsData.getFilteredScreens("topBar")

        delegate: TopBar {
            modelData: item
        }
    }

    Variants {
        model: SettingsData.getFilteredScreens("dock")

        delegate: Dock {
            modelData: item
            contextMenu: dockContextMenuLoader.item ? dockContextMenuLoader.item : null

            Component.onCompleted: {
                dockContextMenuLoader.active = true
            }
        }
    }

    Loader {
        id: centcomPopoutLoader
        active: false
        sourceComponent: Component {
            CentcomPopout {
                id: centcomPopout
            }
        }
    }

    LazyLoader {
        id: dockContextMenuLoader
        active: false

        DockContextMenu {
            id: dockContextMenu
        }
    }


    LazyLoader {
        id: notificationCenterLoader
        active: false

        NotificationCenterPopout {
            id: notificationCenter
        }
    }

    Variants {
        model: SettingsData.getFilteredScreens("notifications")

        delegate: NotificationPopupManager {
            modelData: item
        }
    }

    LazyLoader {
        id: controlCenterLoader
        active: false

        ControlCenterPopout {
            id: controlCenterPopout

            onPowerActionRequested: (action, title, message) => {
                                        powerConfirmModalLoader.active = true
                                        if (powerConfirmModalLoader.item) {
                                            powerConfirmModalLoader.item.show(
                                                action, title, message)
                                        }
                                    }
            onLockRequested: {
                lock.activate()
            }
        }
    }

    LazyLoader {
        id: wifiPasswordModalLoader
        active: false

        WifiPasswordModal {
            id: wifiPasswordModal
        }
    }

    LazyLoader {
        id: networkInfoModalLoader
        active: false

        NetworkInfoModal {
            id: networkInfoModal
        }
    }

    LazyLoader {
        id: batteryPopoutLoader
        active: false

        BatteryPopout {
            id: batteryPopout
        }
    }

    LazyLoader {
        id: powerMenuLoader
        active: false

        PowerMenu {
            id: powerMenu
            onPowerActionRequested: (action, title, message) => {
                                        powerConfirmModalLoader.active = true
                                        if (powerConfirmModalLoader.item) {
                                            powerConfirmModalLoader.item.show(
                                                action, title, message)
                                        }
                                    }
        }
    }

    LazyLoader {
        id: powerConfirmModalLoader
        active: false

        PowerConfirmModal {
            id: powerConfirmModal
        }
    }

    LazyLoader {
        id: processListPopoutLoader
        active: false

        ProcessListPopout {
            id: processListPopout
        }
    }

    SettingsModal {
        id: settingsModal
    }

    LazyLoader {
        id: appDrawerLoader
        active: false

        AppDrawerPopout {
            id: appDrawerPopout
        }
    }

    SpotlightModal {
        id: spotlightModal
    }

    ClipboardHistoryModal {
        id: clipboardHistoryModalPopup
    }

    NotificationModal {
        id: notificationModal
    }

    LazyLoader {
        id: processListModalLoader

        active: false

        ProcessListModal {
            id: processListModal
        }
    }

    IpcHandler {
        function open() {
            processListModalLoader.active = true
            if (processListModalLoader.item)
                processListModalLoader.item.show()

            return "PROCESSLIST_OPEN_SUCCESS"
        }

        function close() {
            if (processListModalLoader.item)
                processListModalLoader.item.hide()

            return "PROCESSLIST_CLOSE_SUCCESS"
        }

        function toggle() {
            processListModalLoader.active = true
            if (processListModalLoader.item)
                processListModalLoader.item.toggle()

            return "PROCESSLIST_TOGGLE_SUCCESS"
        }

        target: "processlist"
    }

    Variants {
        model: SettingsData.getFilteredScreens("toast")

        delegate: Toast {
            modelData: item
            visible: ToastService.toastVisible
        }
    }

    Variants {
        model: SettingsData.getFilteredScreens("osd")

        delegate: VolumeOSD {
            modelData: item
        }
    }




    Variants {
        model: SettingsData.getFilteredScreens("osd")

        delegate: MicMuteOSD {
            modelData: item
        }
    }

    Variants {
        model: SettingsData.getFilteredScreens("osd")

        delegate: BrightnessOSD {
            modelData: item
        }
    }

    Variants {
        model: SettingsData.getFilteredScreens("osd")

        delegate: IdleInhibitorOSD {
            modelData: item
        }
    }
}
