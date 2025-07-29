pragma Singleton
pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Singleton {

    id: root

    property int themeIndex: 0
    property bool themeIsDynamic: false
    property bool isLightMode: false
    property real topBarTransparency: 0.75
    property real topBarWidgetTransparency: 0.85
    property real popupTransparency: 0.92
    property var appUsageRanking: {}
    property bool use24HourClock: true
    property bool useFahrenheit: false
    property bool nightModeEnabled: false
    property string profileImage: ""
    property string weatherLocation: "New York, NY"
    property string weatherCoordinates: "40.7128,-74.0060"
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
    property string systemDefaultIconTheme: ""
    property bool qt5ctAvailable: false
    property bool qt6ctAvailable: false
    property bool useOSLogo: false
    property string osLogoColorOverride: ""
    property real osLogoBrightness: 0.5
    property real osLogoContrast: 1.0
    property string wallpaperPath: ""
    property bool wallpaperDynamicTheming: true
    property string wallpaperLastPath: ""
    property string profileLastPath: ""
    property bool doNotDisturb: false
    property string fontFamily: "Inter Variable"
    property string monoFontFamily: "Fira Code"
    property int fontWeight: Font.Normal
    property bool gtkThemingEnabled: false
    property bool qtThemingEnabled: false
    
    readonly property string defaultFontFamily: "Inter Variable"
    readonly property string defaultMonoFontFamily: "Fira Code"
    
    readonly property string _homeUrl: StandardPaths.writableLocation(StandardPaths.HomeLocation)
    
    Timer {
        id: fontCheckTimer
        interval: 3000
        repeat: false
        onTriggered: {
            var availableFonts = Qt.fontFamilies()
            var missingFonts = []
            
            if (fontFamily === defaultFontFamily && !availableFonts.includes(defaultFontFamily)) {
                missingFonts.push(defaultFontFamily)
            }
            if (monoFontFamily === defaultMonoFontFamily && !availableFonts.includes(defaultMonoFontFamily)) {
                missingFonts.push(defaultMonoFontFamily)
            }
            
            if (missingFonts.length > 0) {
                var message = "Missing fonts: " + missingFonts.join(", ") + ". Using system defaults."
                console.warn("Prefs: " + message)
                ToastService.showWarning(message)
            }
        }
    }
    
    Component.onCompleted: {
        loadSettings();
        fontCheckTimer.start()
    }

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
                topBarWidgetTransparency = settings.topBarWidgetTransparency !== undefined ? (settings.topBarWidgetTransparency > 1 ? settings.topBarWidgetTransparency / 100 : settings.topBarWidgetTransparency) : 0.85;
                popupTransparency = settings.popupTransparency !== undefined ? (settings.popupTransparency > 1 ? settings.popupTransparency / 100 : settings.popupTransparency) : 0.92;
                appUsageRanking = settings.appUsageRanking || {};
                use24HourClock = settings.use24HourClock !== undefined ? settings.use24HourClock : true;
                useFahrenheit = settings.useFahrenheit !== undefined ? settings.useFahrenheit : false;
                nightModeEnabled = settings.nightModeEnabled !== undefined ? settings.nightModeEnabled : false;
                profileImage = settings.profileImage !== undefined ? settings.profileImage : "";
                weatherLocation = settings.weatherLocation !== undefined ? settings.weatherLocation : "New York, NY";
                weatherCoordinates = settings.weatherCoordinates !== undefined ? settings.weatherCoordinates : "40.7128,-74.0060";
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
                doNotDisturb = settings.doNotDisturb !== undefined ? settings.doNotDisturb : false;
                fontFamily = settings.fontFamily !== undefined ? settings.fontFamily : defaultFontFamily;
                monoFontFamily = settings.monoFontFamily !== undefined ? settings.monoFontFamily : defaultMonoFontFamily;
                fontWeight = settings.fontWeight !== undefined ? settings.fontWeight : Font.Normal;
                gtkThemingEnabled = settings.gtkThemingEnabled !== undefined ? settings.gtkThemingEnabled : false;
                qtThemingEnabled = settings.qtThemingEnabled !== undefined ? settings.qtThemingEnabled : false;
                        applyStoredTheme();
                        detectAvailableIconThemes();
                        detectQtTools();
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
            "topBarWidgetTransparency": topBarWidgetTransparency,
            "popupTransparency": popupTransparency,
            "appUsageRanking": appUsageRanking,
            "use24HourClock": use24HourClock,
            "useFahrenheit": useFahrenheit,
            "nightModeEnabled": nightModeEnabled,
            "profileImage": profileImage,
            "weatherLocation": weatherLocation,
            "weatherCoordinates": weatherCoordinates,
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
            "profileLastPath": profileLastPath,
            "doNotDisturb": doNotDisturb,
            "fontFamily": fontFamily,
            "monoFontFamily": monoFontFamily,
            "fontWeight": fontWeight,
            "gtkThemingEnabled": gtkThemingEnabled,
            "qtThemingEnabled": qtThemingEnabled
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
        if (typeof Theme !== "undefined") {
            Theme.isLightMode = lightMode;
        }
        saveSettings();
    }

    function setTopBarTransparency(transparency) {
        topBarTransparency = transparency;
        saveSettings();
    }

    function setTopBarWidgetTransparency(transparency) {
        topBarWidgetTransparency = transparency;
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

    // Weather location setter
    function setWeatherLocation(displayName, coordinates) {
        weatherLocation = displayName;
        weatherCoordinates = coordinates;
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

    function detectQtTools() {
        qtToolsDetectionProcess.running = true;
    }

    function setIconTheme(themeName) {
        iconTheme = themeName;
        updateGtkIconTheme(themeName);
        updateQtIconTheme(themeName);
        saveSettings();
        
        // If dynamic theme is active, regenerate system themes with new icon theme
        if (typeof Theme !== "undefined" && Theme.isDynamicTheme && typeof Colors !== "undefined") {
            console.log("Icon theme changed during dynamic theming - regenerating system themes");
            Colors.generateSystemThemes();
        }
    }
    
    function updateGtkIconTheme(themeName) {
        console.log("Updating GTK icon theme to:", themeName);
        var gtkThemeName = (themeName === "System Default") ? systemDefaultIconTheme : themeName;

        // Update icon theme via dconf/gsettings AND settings.ini files
        if (gtkThemeName !== "System Default" && gtkThemeName !== "") {
            var script = 
                "# Update dconf/gsettings\n" +
                "if command -v dconf >/dev/null 2>&1; then\n" +
                "    dconf write /org/gnome/desktop/interface/icon-theme \\\"" + gtkThemeName + "\\\"\n" +
                "elif command -v gsettings >/dev/null 2>&1; then\n" +
                "    gsettings set org.gnome.desktop.interface icon-theme '" + gtkThemeName + "'\n" +
                "fi\n" +
                "\n" +
                "# Update settings.ini files (keep existing gtk-theme-name)\n" +
                "for config_dir in ~/.config/gtk-3.0 ~/.config/gtk-4.0; do\n" +
                "    if [ -f \"$config_dir/settings.ini\" ]; then\n" +
                "        sed -i 's/^gtk-icon-theme-name=.*/gtk-icon-theme-name=" + gtkThemeName + "/' \"$config_dir/settings.ini\"\n" +
                "    fi\n" +
                "done\n" +
                "\n" +
                "# Clear icon cache\n" +
                "rm -rf ~/.cache/icon-cache ~/.cache/thumbnails 2>/dev/null || true\n";

            Quickshell.execDetached(["sh", "-lc", script]);
        }
    }

    function updateQtIconTheme(themeName) {
        console.log("Updating Qt icon theme to:", themeName);
        var qtThemeName = (themeName === "System Default") ? "" : themeName;

        var home = _shq(root._homeUrl.replace("file://", ""));
        if (!qtThemeName) {
            var revertScript =
                "remove_icon_theme() {\n" +
                "  local config_file=\"$1\"\n" +
                "  if [ -f \"$config_file\" ]; then\n" +
                "    awk '\n" +
                "      BEGIN { in_appearance = 0 }\n" +
                "      /^\\[Appearance\\]/ { in_appearance = 1; print; next }\n" +
                "      /^\\[/ && in_appearance { in_appearance = 0 }\n" +
                "      in_appearance && /^icon_theme=/ { next }\n" +
                "      { print }\n" +
                "    ' \"$config_file\" > \"$config_file.tmp\" && mv \"$config_file.tmp\" \"$config_file\"\n" +
                "  fi\n" +
                "}\n" +
                "remove_icon_theme " + home + "/.config/qt5ct/qt5ct.conf\n" +
                "remove_icon_theme " + home + "/.config/qt6ct/qt6ct.conf\n" +
                "rm -f " + home + "/.config/environment.d/95-qtct.conf 2>/dev/null || true\n" +
                "systemctl --user import-environment --unset=QT_QPA_PLATFORMTHEME --unset=QT_QPA_PLATFORMTHEME_QT6 2>/dev/null || true\n" +
                "dbus-update-activation-environment --systemd QT_QPA_PLATFORMTHEME= QT_QPA_PLATFORMTHEME_QT6= 2>/dev/null || true\n" +
                "rm -rf " + home + "/.cache/icon-cache " + home + "/.cache/thumbnails 2>/dev/null || true\n";

            Quickshell.execDetached(["sh", "-lc", revertScript]);
            return;
        }

        var script =
            "mkdir -p " + home + "/.config/qt5ct " + home + "/.config/qt6ct " + home + "/.config/environment.d 2>/dev/null || true\n" +
            "update_qt_config() {\n" +
            "  local config_file=\"$1\"\n" +
            "  local theme_name=\"$2\"\n" +
            "  if [ -f \"$config_file\" ]; then\n" +
            "    if grep -q '^\\[Appearance\\]' \"$config_file\"; then\n" +
            "      awk -v theme=\"$theme_name\" '\n" +
            "        BEGIN { in_appearance = 0; icon_theme_added = 0 }\n" +
            "        /^\\[Appearance\\]/ { in_appearance = 1; print; next }\n" +
            "        /^\\[/ && !/^\\[Appearance\\]/ { \n" +
            "          if (in_appearance && !icon_theme_added) { \n" +
            "            print \"icon_theme=\" theme; icon_theme_added = 1 \n" +
            "          } \n" +
            "          in_appearance = 0; print; next \n" +
            "        }\n" +
            "        in_appearance && /^icon_theme=/ { \n" +
            "          if (!icon_theme_added) { \n" +
            "            print \"icon_theme=\" theme; icon_theme_added = 1 \n" +
            "          } \n" +
            "          next \n" +
            "        }\n" +
            "        { print }\n" +
            "        END { if (in_appearance && !icon_theme_added) print \"icon_theme=\" theme }\n" +
            "      ' \"$config_file\" > \"$config_file.tmp\" && mv \"$config_file.tmp\" \"$config_file\"\n" +
            "    else\n" +
            "      printf '\\n[Appearance]\\nicon_theme=%s\\n' \"$theme_name\" >> \"$config_file\"\n" +
            "    fi\n" +
            "  else\n" +
            "    printf '[Appearance]\\nicon_theme=%s\\n' \"$theme_name\" > \"$config_file\"\n" +
            "  fi\n" +
            "}\n" +
            "update_qt_config " + home + "/.config/qt5ct/qt5ct.conf " + _shq(qtThemeName) + "\n" +
            "update_qt_config " + home + "/.config/qt6ct/qt6ct.conf " + _shq(qtThemeName) + "\n" +
            "if command -v qt5ct >/dev/null 2>&1; then\n" +
            "  printf 'QT_QPA_PLATFORMTHEME=qt5ct\\n' > " + home + "/.config/environment.d/95-qtct.conf\n" +
            "  if command -v qt6ct >/dev/null 2>&1; then\n" +
            "    printf 'QT_QPA_PLATFORMTHEME_QT6=qt6ct\\n' >> " + home + "/.config/environment.d/95-qtct.conf\n" +
            "  fi\n" +
            "else\n" +
            "  rm -f " + home + "/.config/environment.d/95-qtct.conf 2>/dev/null || true\n" +
            "fi\n" +
            "systemctl --user import-environment QT_QPA_PLATFORMTHEME QT_QPA_PLATFORMTHEME_QT6 2>/dev/null || true\n" +
            "dbus-update-activation-environment --systemd QT_QPA_PLATFORMTHEME QT_QPA_PLATFORMTHEME_QT6 2>/dev/null || true\n" +
            "rm -rf " + home + "/.cache/icon-cache " + home + "/.cache/thumbnails 2>/dev/null || true\n";

        Quickshell.execDetached(["sh", "-lc", script]);
    }

    function applyStoredIconTheme() {
        updateGtkIconTheme(iconTheme);
        updateQtIconTheme(iconTheme);
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

    function setDoNotDisturb(enabled) {
        doNotDisturb = enabled;
        saveSettings();
    }

    function setFontFamily(family) {
        fontFamily = family;
        saveSettings();
    }

    function setFontWeight(weight) {
        fontWeight = weight;
        saveSettings();
    }

    function setMonoFontFamily(family) {
        monoFontFamily = family;
        saveSettings();
    }

    function setGtkThemingEnabled(enabled) {
        gtkThemingEnabled = enabled;
        saveSettings();
    }

    function setQtThemingEnabled(enabled) {
        qtThemingEnabled = enabled;
        saveSettings();
    }

    // Helper to safely single-quote shell strings
    function _shq(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

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
        command: ["sh", "-c", "gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | sed \"s/'//g\" || echo ''"]
        running: false
        onExited: (exitCode) => {
            if (exitCode === 0 && stdout && stdout.length > 0) {
                systemDefaultIconTheme = stdout.trim();
            } else {
                systemDefaultIconTheme = "";
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

    Process {
        id: qtToolsDetectionProcess
        command: ["sh", "-c", "echo -n 'qt5ct:'; command -v qt5ct >/dev/null && echo 'true' || echo 'false'; echo -n 'qt6ct:'; command -v qt6ct >/dev/null && echo 'true' || echo 'false'"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    var lines = text.trim().split('\n');
                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i];
                        if (line.startsWith('qt5ct:')) {
                            qt5ctAvailable = line.split(':')[1] === 'true';
                        } else if (line.startsWith('qt6ct:')) {
                            qt6ctAvailable = line.split(':')[1] === 'true';
                        }
                    }
                }
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

    IpcHandler {
        target: "theme"

        function toggle(): string {
            root.setLightMode(!root.isLightMode)
            return root.isLightMode ? "light" : "dark"
        }

        function light(): string {
            root.setLightMode(true)
            return "light"
        }

        function dark(): string {
            root.setLightMode(false)
            return "dark"  
        }

        function get(): string {
            return root.isLightMode ? "light" : "dark"
        }
    }
}
