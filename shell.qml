//@ pragma UseQApplication

import Quickshell
import qs.Modules
import qs.Modules.CentcomCenter
import qs.Modules.ControlCenter
import qs.Modules.Settings
import qs.Modules.TopBar
import qs.Modules.ProcessList
import qs.Modules.ControlCenter.Network
import qs.Modules.Popouts
import qs.Modals

ShellRoot {
    id: root

    // Multi-monitor support using Variants
    Variants {
        model: Quickshell.screens

        delegate: TopBar {
            modelData: item
        }

    }

    // Global popup windows
    CentcomPopout {
        id: centcomPopout
    }

    TrayMenuPopup {
        id: trayMenuPopup
    }

    NotificationCenter {
        id: notificationCenter
    }

    NotificationPopup {
        id: notificationPopup
    }

    ControlCenterPopout {
        id: controlCenterPopout
        onPowerActionRequested: (action, title, message) => {
            powerConfirmModal.powerConfirmAction = action;
            powerConfirmModal.powerConfirmTitle = title;
            powerConfirmModal.powerConfirmMessage = message;
            powerConfirmModal.powerConfirmVisible = true;
        }
    }

    WifiPasswordModal {
        id: wifiPasswordModal
    }

    NetworkInfoModal {
        id: networkInfoModal
    }

    BatteryPopout {
        id: batteryPopout
    }

    PowerMenuPopup {
        id: powerMenuPopup
    }

    PowerConfirmModal {
        id: powerConfirmModal
    }

    ProcessListPopout {
        id: processListPopout
    }

    SettingsModal {
        id: settingsModal
    }


    // Application and clipboard components
    AppDrawerPopout {
        id: appDrawerPopout
    }

    SpotlightModal {
        id: spotlightModal
    }

    ProcessListModal {
        id: processListModal
    }

    ClipboardHistoryModal {
        id: clipboardHistoryModalPopup
    }

    Toast {
        id: toastWidget
    }

}
