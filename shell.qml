//@ pragma UseQApplication

import Quickshell
import qs.Modules
import qs.Modules.CenterCommandCenter
import qs.Modules.ControlCenter
import qs.Modules.TopBar

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

    ProcessListWidget {
        id: processListWidget
    }

    ClipboardHistory {
        id: clipboardHistoryPopup
    }

    Toast {
        id: toastWidget
    }
}
