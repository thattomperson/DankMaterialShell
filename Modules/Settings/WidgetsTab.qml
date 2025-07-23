import QtQuick
import qs.Common
import qs.Widgets

Column {
    width: parent.width
    spacing: Theme.spacingM

    DankToggle {
        text: "Focused Window"
        description: "Show the currently focused application in the top bar"
        checked: Prefs.showFocusedWindow
        onToggled: (checked) => {
            return Prefs.setShowFocusedWindow(checked);
        }
    }

    DankToggle {
        text: "Weather Widget"
        description: "Display weather information in the top bar"
        checked: Prefs.showWeather
        onToggled: (checked) => {
            return Prefs.setShowWeather(checked);
        }
    }

    DankToggle {
        text: "Media Controls"
        description: "Show currently playing media in the top bar"
        checked: Prefs.showMusic
        onToggled: (checked) => {
            return Prefs.setShowMusic(checked);
        }
    }

    DankToggle {
        text: "Clipboard Button"
        description: "Show clipboard access button in the top bar"
        checked: Prefs.showClipboard
        onToggled: (checked) => {
            return Prefs.setShowClipboard(checked);
        }
    }

    DankToggle {
        text: "System Resources"
        description: "Display CPU and RAM usage indicators"
        checked: Prefs.showSystemResources
        onToggled: (checked) => {
            return Prefs.setShowSystemResources(checked);
        }
    }

    DankToggle {
        text: "System Tray"
        description: "Show system tray icons in the top bar"
        checked: Prefs.showSystemTray
        onToggled: (checked) => {
            return Prefs.setShowSystemTray(checked);
        }
    }

    DankToggle {
        text: "Use OS Logo for App Launcher"
        description: "Display operating system logo instead of apps icon"
        checked: Prefs.useOSLogo
        onToggled: (checked) => {
            return Prefs.setUseOSLogo(checked);
        }
    }
}