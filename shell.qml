//@ pragma UseQApplication

import Quickshell
import qs.Modules
import qs.Modules.CenterCommandCenter
import qs.Modules.ControlCenter
import qs.Modules.Settings
import qs.Modules.TopBar
import qs.Modules.ProcessList

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
    CenterCommandCenter {
        id: centerCommandCenter
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

    ControlCenterPopup {
        id: controlCenterPopup
        onPowerActionRequested: (action, title, message) => {
            powerConfirmDialog.powerConfirmAction = action;
            powerConfirmDialog.powerConfirmTitle = title;
            powerConfirmDialog.powerConfirmMessage = message;
            powerConfirmDialog.powerConfirmVisible = true;
        }
    }

    WifiPasswordDialog {
        id: wifiPasswordDialog
    }

    NetworkInfoDialog {
        id: networkInfoDialog
    }

    InputDialog {
        id: globalInputDialog
    }

    BatteryControlPopup {
        id: batteryControlPopup
    }

    PowerMenuPopup {
        id: powerMenuPopup
    }

    PowerConfirmDialog {
        id: powerConfirmDialog
    }

    ProcessListDropdown {
        id: processListDropdown
    }

    SettingsPopup {
        id: settingsPopup
    }

    GlobalDropdown {
        id: globalDropdownWindow
    }

    // Application and clipboard components
    AppLauncher {
        id: appLauncher
    }

    SpotlightLauncher {
        id: spotlightLauncher
    }

    ProcessListPopup {
        id: processListPopup
    }

    ClipboardHistory {
        id: clipboardHistoryPopup
    }

    Toast {
        id: toastWidget
    }

}
