pragma Singleton
pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {

    id: root

    property int themeIndex: 0
    property bool themeIsDynamic: false
    property bool isLightMode: false
    property real topBarTransparency: 0.75
    property real popupTransparency: 0.92
    property var appUsageRanking: {}
    property bool use24HourClock: true
    property bool useFahrenheit: false
    property bool nightModeEnabled: false
    property string profileImage: ""
    property string weatherLocationOverride: "New York, NY"
    property bool weatherLocationOverrideEnabled: false
    property bool showFocusedWindow: true
    property bool showWeather: true
    property bool showMusic: true
    property bool showClipboard: true
    property bool showSystemResources: true
    property bool showSystemTray: true
    property bool showWorkspaceIndex: false
    property bool showWorkspacePadding: false
    property string appLauncherViewMode: "list"
    property string spotlightModalViewMode: "list"
    property string networkPreference: "auto"
    property string iconTheme: "System Default"
    property var availableIconThemes: ["System Default"]
    property string systemDefaultIconTheme: "Adwaita"
    property bool useOSLogo: false
    property string osLogoColorOverride: ""
    property real osLogoBrightness: 0.5
    property real osLogoContrast: 1.0
    property string wallpaperPath: ""
    property bool wallpaperDynamicTheming: true
    property string wallpaperLastPath: ""
    property string profileLastPath: ""

    function loadSettings() {
        parseSettings(settingsFile.text());
    }

    function parseSettings(content) {
        try {
            if (content && content.trim()) {
                var settings = JSON.parse(content);
                themeIndex = settings.themeIndex !== undefined ? settings.themeIndex : 0;
                themeIsDynamic = settings.themeIsDynamic !== undefined ? settings.themeIsDynamic : false;
                isLightMode = settings.isLightMode !== undefined ? settings.isLightMode : false;
                topBarTransparency = settings.topBarTransparency !== undefined ? (settings.topBarTransparency > 1 ? settings.topBarTransparency / 100 : settings.topBarTransparency) : 0.75;
                popupTransparency = settings.popupTransparency !== undefined ? (settings.popupTransparency > 1 ? settings.popupTransparency / 100 : settings.popupTransparency) : 0.92;
                appUsageRanking = settings.appUsageRanking || {};
                use24HourClock = settings.use24HourClock !== undefined ? settings.use24HourClock : true;
                useFahrenheit = settings.useFahrenheit !== undefined ? settings.useFahrenheit : false;
                nightModeEnabled = settings.nightModeEnabled !== undefined ? settings.nightModeEnabled : false;
                profileImage = settings.profileImage !== undefined ? settings.profileImage : "";
                weatherLocationOverride = settings.weatherLocationOverride !== undefined ? settings.weatherLocationOverride : "New York, NY";
                weatherLocationOverrideEnabled = settings.weatherLocationOverrideEnabled !== undefined ? settings.weatherLocationOverrideEnabled : false;
                showFocusedWindow = settings.showFocusedWindow !== undefined ? settings.showFocusedWindow : true;
                showWeather = settings.showWeather !== undefined ? settings.showWeather : true;
                showMusic = settings.showMusic !== undefined ? settings.showMusic : true;
                showClipboard = settings.showClipboard !== undefined ? settings.showClipboard : true;
                showSystemResources = settings.showSystemResources !== undefined ? settings.showSystemResources : true;
                showSystemTray = settings.showSystemTray !== undefined ? settings.showSystemTray : true;
                showWorkspaceIndex = settings.showWorkspaceIndex !== undefined ? settings.showWorkspaceIndex : false;
                showWorkspacePadding = settings.showWorkspacePadding !== undefined ? settings.showWorkspacePadding : false;
                appLauncherViewMode = settings.appLauncherViewMode !== undefined ? settings.appLauncherViewMode : "list";
                spotlightModalViewMode = settings.spotlightModalViewMode !== undefined ? settings.spotlightModalViewMode : "list";
                networkPreference = settings.networkPreference !== undefined ? settings.networkPreference : "auto";
                iconTheme = settings.iconTheme !== undefined ? settings.iconTheme : "System Default";
                useOSLogo = settings.useOSLogo !== undefined ? settings.useOSLogo : false;
                osLogoColorOverride = settings.osLogoColorOverride !== undefined ? settings.osLogoColorOverride : "";
                osLogoBrightness = settings.osLogoBrightness !== undefined ? settings.osLogoBrightness : 0.5;
                osLogoContrast = settings.osLogoContrast !== undefined ? settings.osLogoContrast : 1.0;
                wallpaperPath = settings.wallpaperPath !== undefined ? settings.wallpaperPath : "";
                wallpaperDynamicTheming = settings.wallpaperDynamicTheming !== undefined ? settings.wallpaperDynamicTheming : true;
                wallpaperLastPath = settings.wallpaperLastPath !== undefined ? settings.wallpaperLastPath : "";
                profileLastPath = settings.profileLastPath !== undefined ? settings.profileLastPath : "";
                        applyStoredTheme();
                        detectAvailableIconThemes();
                        updateGtkIconTheme(iconTheme);
                        applyStoredIconTheme();
            } else {
                        applyStoredTheme();
            }
        } catch (e) {
                applyStoredTheme();
        }
    }

    function saveSettings() {
        settingsFile.setText(JSON.stringify({
            "themeIndex": themeIndex,
            "themeIsDynamic": themeIsDynamic,
            "isLightMode": isLightMode,
            "topBarTransparency": topBarTransparency,
            "popupTransparency": popupTransparency,
            "appUsageRanking": appUsageRanking,
            "use24HourClock": use24HourClock,
            "useFahrenheit": useFahrenheit,
            "nightModeEnabled": nightModeEnabled,
            "profileImage": profileImage,
            "weatherLocationOverride": weatherLocationOverride,
            "weatherLocationOverrideEnabled": weatherLocationOverrideEnabled,
            "showFocusedWindow": showFocusedWindow,
            "showWeather": showWeather,
            "showMusic": showMusic,
            "showClipboard": showClipboard,
            "showSystemResources": showSystemResources,
            "showSystemTray": showSystemTray,
            "showWorkspaceIndex": showWorkspaceIndex,
            "showWorkspacePadding": showWorkspacePadding,
            "appLauncherViewMode": appLauncherViewMode,
            "spotlightModalViewMode": spotlightModalViewMode,
            "networkPreference": networkPreference,
            "iconTheme": iconTheme,
            "useOSLogo": useOSLogo,
            "osLogoColorOverride": osLogoColorOverride,
            "osLogoBrightness": osLogoBrightness,
            "osLogoContrast": osLogoContrast,
            "wallpaperPath": wallpaperPath,
            "wallpaperDynamicTheming": wallpaperDynamicTheming,
            "wallpaperLastPath": wallpaperLastPath,
            "profileLastPath": profileLastPath
        }, null, 2));
    }

    function setShowWorkspaceIndex(enabled) {
        showWorkspaceIndex = enabled;
        saveSettings();
    }

    function setShowWorkspacePadding(enabled) {
        showWorkspacePadding = enabled;
        saveSettings();
    }

    function applyStoredTheme() {
        if (typeof Theme !== "undefined") {
            Theme.isLightMode = isLightMode;
            Theme.switchTheme(themeIndex, themeIsDynamic, false);
        } else {
            Qt.callLater(() => {
                if (typeof Theme !== "undefined") {
                    Theme.isLightMode = isLightMode;
                    Theme.switchTheme(themeIndex, themeIsDynamic, false);
                }
            });
        }
    }

    function setTheme(index, isDynamic) {
        themeIndex = index;
        themeIsDynamic = isDynamic;
        saveSettings();
    }

    function setLightMode(lightMode) {
        isLightMode = lightMode;
        saveSettings();
    }

    function setTopBarTransparency(transparency) {
        topBarTransparency = transparency;
        saveSettings();
    }

    function setPopupTransparency(transparency) {
        popupTransparency = transparency;
        saveSettings();
    }

    function addAppUsage(app) {
        if (!app)
            return;

        var appId = app.id || (app.execString || app.exec || "");
        if (!appId)
            return;

        var currentRanking = Object.assign({}, appUsageRanking);
        
        if (currentRanking[appId]) {
            currentRanking[appId].usageCount = (currentRanking[appId].usageCount || 1) + 1;
            currentRanking[appId].lastUsed = Date.now();
            currentRanking[appId].icon = app.icon || currentRanking[appId].icon || "application-x-executable";
            currentRanking[appId].name = app.name || currentRanking[appId].name || "";
        } else {
            currentRanking[appId] = {
                "name": app.name || "",
                "exec": app.execString || app.exec || "",
                "icon": app.icon || "application-x-executable",
                "comment": app.comment || "",
                "usageCount": 1,
                "lastUsed": Date.now()
            };
        }
        
        appUsageRanking = currentRanking;
        saveSettings();
    }

    function getAppUsageRanking() {
        return appUsageRanking;
    }

    function getRankedApps() {
        var apps = [];
        for (var appId in appUsageRanking) {
            var appData = appUsageRanking[appId];
            apps.push({
                id: appId,
                name: appData.name,
                exec: appData.exec,
                icon: appData.icon,
                comment: appData.comment,
                usageCount: appData.usageCount,
                lastUsed: appData.lastUsed
            });
        }
        
        return apps.sort(function(a, b) {
            if (a.usageCount !== b.usageCount)
                return b.usageCount - a.usageCount;
            return a.name.localeCompare(b.name);
        });
    }

    function cleanupAppUsageRanking(availableAppIds) {
        var currentRanking = Object.assign({}, appUsageRanking);
        var hasChanges = false;
        
        for (var appId in currentRanking) {
            if (availableAppIds.indexOf(appId) === -1) {
                delete currentRanking[appId];
                hasChanges = true;
            }
        }
        
        if (hasChanges) {
            appUsageRanking = currentRanking;
            saveSettings();
        }
    }

    // New preference setters
    function setClockFormat(use24Hour) {
        use24HourClock = use24Hour;
        saveSettings();
    }

    function setTemperatureUnit(fahrenheit) {
        useFahrenheit = fahrenheit;
        saveSettings();
    }

    function setNightModeEnabled(enabled) {
        nightModeEnabled = enabled;
        saveSettings();
    }

    function setProfileImage(imageUrl) {
        profileImage = imageUrl;
        saveSettings();
    }

    // Widget visibility setters
    function setShowFocusedWindow(enabled) {
        showFocusedWindow = enabled;
        saveSettings();
    }

    function setShowWeather(enabled) {
        showWeather = enabled;
        saveSettings();
    }

    function setShowMusic(enabled) {
        showMusic = enabled;
        saveSettings();
    }

    function setShowClipboard(enabled) {
        showClipboard = enabled;
        saveSettings();
    }

    function setShowSystemResources(enabled) {
        showSystemResources = enabled;
        saveSettings();
    }

    function setShowSystemTray(enabled) {
        showSystemTray = enabled;
        saveSettings();
    }

    // View mode setters
    function setAppLauncherViewMode(mode) {
        appLauncherViewMode = mode;
        saveSettings();
    }

    function setSpotlightModalViewMode(mode) {
        spotlightModalViewMode = mode;
        saveSettings();
    }

    // Weather location override setter
    function setWeatherLocationOverride(location) {
        weatherLocationOverride = location;
        saveSettings();
    }

    function setWeatherLocationOverrideEnabled(enabled) {
        weatherLocationOverrideEnabled = enabled;
        saveSettings();
    }

    // Network preference setter
    function setNetworkPreference(preference) {
        networkPreference = preference;
        saveSettings();
    }

    function detectAvailableIconThemes() {
        // First detect system default, then available themes
        systemDefaultDetectionProcess.running = true;
    }

    function setIconTheme(themeName) {
        iconTheme = themeName;
        
        updateGtkIconTheme(themeName);
        
        updateQuickshellIconTheme(themeName);
        
        saveSettings();
    }
    
    function updateGtkIconTheme(themeName) {
        var gtkThemeName;
        
        switch(themeName) {
            case "System Default":
                gtkThemeName = systemDefaultIconTheme;
                break;
            case "Papirus":
                gtkThemeName = "Papirus";
                break;
            case "Papirus-Dark":
                gtkThemeName = "Papirus-Dark";
                break;
            case "Papirus-Light":
                gtkThemeName = "Papirus-Light";
                break;
            case "Adwaita":
                gtkThemeName = "Adwaita";
                break;
            default:
                gtkThemeName = themeName;
        }
        
        
        envCheckProcess.command = ["sh", "-c", "echo 'QT_QPA_PLATFORMTHEME=' $QT_QPA_PLATFORMTHEME"];
        envCheckProcess.running = true;
        
        var gtk3Settings = `[Settings]
gtk-icon-theme-name=${gtkThemeName}
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=true`;
        
        gtk3Process.command = ["sh", "-c", `mkdir -p ~/.config/gtk-3.0 && echo '${gtk3Settings}' > ~/.config/gtk-3.0/settings.ini`];
        gtk3Process.running = true;
        
        gtk4Process.command = ["sh", "-c", `mkdir -p ~/.config/gtk-4.0 && echo '${gtk3Settings}' > ~/.config/gtk-4.0/settings.ini`];
        gtk4Process.running = true;
        
        reloadThemeProcess.command = ["sh", "-c", "gsettings set org.gnome.desktop.interface icon-theme '" + gtkThemeName + "' 2>/dev/null || true"];
        reloadThemeProcess.running = true;
        
        
    }
    
    function updateQuickshellIconTheme(themeName) {
        var quickshellThemeName;
        
        switch(themeName) {
            case "System Default":
                quickshellThemeName = "";
                break;
            case "Papirus":
                quickshellThemeName = "Papirus";
                break;
            case "Papirus-Dark":
                quickshellThemeName = "Papirus-Dark";
                break;
            case "Papirus-Light":
                quickshellThemeName = "Papirus-Light";
                break;
            case "Adwaita":
                quickshellThemeName = "Adwaita";
                break;
            default:
                quickshellThemeName = themeName;
        }
        
        
        
        if (quickshellThemeName) {
            envSetProcess.command = ["sh", "-c", `export QS_ICON_THEME="${quickshellThemeName}" && rm -rf ~/.cache/icon-cache ~/.cache/thumbnails 2>/dev/null || true`];
        } else {
            envSetProcess.command = ["sh", "-c", `unset QS_ICON_THEME && rm -rf ~/.cache/icon-cache ~/.cache/thumbnails 2>/dev/null || true`];
        }
        envSetProcess.running = true;
        
    }
    
    function applyStoredIconTheme() {
        if (iconTheme && iconTheme !== "System Default") {
            updateGtkIconTheme(iconTheme);
        }
    }

    function setUseOSLogo(enabled) {
        useOSLogo = enabled;
        saveSettings();
    }

    function setOSLogoColorOverride(color) {
        osLogoColorOverride = color;
        saveSettings();
    }

    function setOSLogoBrightness(brightness) {
        osLogoBrightness = brightness;
        saveSettings();
    }

    function setOSLogoContrast(contrast) {
        osLogoContrast = contrast;
        saveSettings();
    }

    function setWallpaperPath(path) {
        wallpaperPath = path;
        saveSettings();
        
        // Trigger dynamic theming if enabled
        if (wallpaperDynamicTheming && path && typeof Theme !== "undefined") {
            Theme.switchTheme(themeIndex, true, true);
        }
    }

    function setWallpaperDynamicTheming(enabled) {
        wallpaperDynamicTheming = enabled;
        saveSettings();
        
        // If enabled and we have a wallpaper, trigger dynamic theming
        if (enabled && wallpaperPath && typeof Theme !== "undefined") {
            Theme.switchTheme(themeIndex, true, true);
        }
    }

    function setWallpaper(imagePath) {
        wallpaperPath = imagePath;
        saveSettings();
        
        // Trigger color extraction if dynamic theming is enabled
        if (wallpaperDynamicTheming && typeof Colors !== "undefined") {
            Colors.extractColors();
        }
    }

    Component.onCompleted: loadSettings()
    

    FileView {
        id: settingsFile

        path: StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/DankMaterialShell/settings.json"
        blockLoading: true
        blockWrites: true
        watchChanges: true
        onLoaded: {
            parseSettings(settingsFile.text());
        }
        onLoadFailed: (error) => {
            applyStoredTheme();
        }
    }

    Process {
        id: gtk3Process
        running: false
        onExited: (exitCode) => {
            if (exitCode === 0) {
            } else {
                console.warn("Failed to update GTK 3 settings, exit code:", exitCode);
            }
        }
    }
    
    Process {
        id: gtk4Process
        running: false
        onExited: (exitCode) => {
            if (exitCode === 0) {
            } else {
                console.warn("Failed to update GTK 4 settings, exit code:", exitCode);
            }
        }
    }
    
    Process {
        id: reloadThemeProcess
        running: false
        onExited: (exitCode) => {
            if (exitCode === 0) {
            } else {
                console.log("GTK theme reload failed (this is normal if gsettings is not available), exit code:", exitCode);
            }
        }
    }
    
    Process {
        id: qtThemeProcess
        running: false
        onExited: (exitCode) => {
            // Qt theme reload signal sent
        }
    }
    
    Process {
        id: envCheckProcess
        running: false
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                console.warn("Environment check failed, exit code:", exitCode);
            }
        }
    }
    
    
    Process {
        id: envSetProcess
        running: false
        onExited: (exitCode) => {
        }
    }
    
    Process {
        id: systemDefaultDetectionProcess
        command: ["sh", "-c", "gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | sed \"s/'//g\" || echo 'Adwaita'"]
        running: false
        onExited: (exitCode) => {
            if (exitCode === 0 && stdout && stdout.length > 0) {
                systemDefaultIconTheme = stdout.trim();
            } else {
                systemDefaultIconTheme = "Adwaita";
            }
            iconThemeDetectionProcess.running = true;
        }
    }

    Process {
        id: iconThemeDetectionProcess
        command: ["sh", "-c", "find /usr/share/icons ~/.local/share/icons ~/.icons -maxdepth 1 -type d 2>/dev/null | sed 's|.*/||' | grep -v '^icons$' | sort -u"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                var detectedThemes = ["System Default"];
                if (text && text.trim()) {
                    var themes = text.trim().split('\n');
                    for (var i = 0; i < themes.length; i++) {
                        var theme = themes[i].trim();
                        if (theme && theme !== "" && theme !== "default" && theme !== "hicolor" && theme !== "locolor") {
                            detectedThemes.push(theme);
                        }
                    }
                }
                availableIconThemes = detectedThemes;
            }
        }
    }

    IpcHandler {
        target: "wallpaper"

        function get(): string {
            return root.wallpaperPath || ""
        }

        function set(path: string): string {
            if (!path) {
                return "ERROR: No path provided"
            }
            
            var absolutePath = path.startsWith("/") ? path : StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/" + path
            
            try {
                root.setWallpaper(absolutePath)
                return "SUCCESS: Wallpaper set to " + absolutePath
            } catch (e) {
                return "ERROR: Failed to set wallpaper: " + e.toString()
            }
        }

        function clear(): string {
            root.setWallpaper("")
            return "SUCCESS: Wallpaper cleared"
        }
    }
}
