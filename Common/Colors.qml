pragma Singleton
pragma ComponentBehavior: Bound

import Qt.labs.platform
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import qs.Common

Singleton {

    id: root

    readonly property string _homeUrl: StandardPaths.writableLocation(StandardPaths.HomeLocation)
    readonly property string homeDir: _homeUrl.startsWith("file://") ? _homeUrl.substring(7) : _homeUrl
    readonly property string wallpaperPath: Prefs.wallpaperPath
    property bool matugenAvailable: false
    property string matugenJson: ""
    property var matugenColors: ({
    })
    property bool extractionRequested: false
    property int colorUpdateTrigger: 0
    property string lastWallpaperTimestamp: ""
    property color primary: getMatugenColor("primary", "#42a5f5")
    property color secondary: getMatugenColor("secondary", "#8ab4f8")
    property color tertiary: getMatugenColor("tertiary", "#bb86fc")
    property color tertiaryContainer: getMatugenColor("tertiary_container", "#3700b3")
    property color error: getMatugenColor("error", "#cf6679")
    property color inversePrimary: getMatugenColor("inverse_primary", "#6200ea")
    property color bg: getMatugenColor("background", "#1a1c1e")
    property color surface: getMatugenColor("surface", "#1a1c1e")
    property color surfaceContainer: getMatugenColor("surface_container", "#1e2023")
    property color surfaceContainerHigh: getMatugenColor("surface_container_high", "#292b2f")
    property color surfaceVariant: getMatugenColor("surface_variant", "#44464f")
    property color surfaceText: getMatugenColor("on_background", "#e3e8ef")
    property color primaryText: getMatugenColor("on_primary", "#ffffff")
    property color surfaceVariantText: getMatugenColor("on_surface_variant", "#c4c7c5")
    property color primaryContainer: getMatugenColor("primary_container", "#1976d2")
    property color surfaceTint: getMatugenColor("surface_tint", "#8ab4f8")
    property color outline: getMatugenColor("outline", "#8e918f")
    property color accentHi: primary
    property color accentLo: secondary

    signal colorsUpdated()

    function onLightModeChanged() {
        if (matugenColors && Object.keys(matugenColors).length > 0) {
            console.log("Light mode changed - updating dynamic colors");
            colorUpdateTrigger++;
            colorsUpdated();
        }
    }

    function extractColors() {
        console.log("Colors.extractColors() called, matugenAvailable:", matugenAvailable);
        extractionRequested = true;
        if (matugenAvailable)
            fileChecker.running = true;
        else
            matugenCheck.running = true;
    }

    function getMatugenColor(path, fallback) {
        colorUpdateTrigger;
        const colorMode = (typeof Theme !== "undefined" && Theme.isLightMode) ? "light" : "dark";
        let cur = matugenColors && matugenColors.colors && matugenColors.colors[colorMode];
        for (const part of path.split(".")) {
            if (!cur || typeof cur !== "object" || !(part in cur))
                return fallback;

            cur = cur[part];
        }
        return cur || fallback;
    }

    function isColorDark(c) {
        return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) < 0.5;
    }

    Component.onCompleted: {
        console.log("Colors.qml → home =", homeDir);
        matugenCheck.running = true;
        if (typeof Theme !== "undefined")
            Theme.isLightModeChanged.connect(root.onLightModeChanged);
    }

    Process {
        id: matugenCheck

        command: ["which", "matugen"]
        onExited: (code) => {
            matugenAvailable = (code === 0);
            console.log("Matugen in PATH:", matugenAvailable);
            if (!matugenAvailable) {
                console.warn("Matugen missing → dynamic theme disabled");
                ToastService.wallpaperErrorStatus = "matugen_missing";
                ToastService.showWarning("matugen not found - dynamic theming disabled");
                return ;
            }
            if (extractionRequested) {
                console.log("Continuing with color extraction");
                fileChecker.running = true;
            }
        }
    }

    Process {
        id: fileChecker

        command: ["test", "-r", wallpaperPath]
        onExited: (code) => {
            if (code === 0) {
                matugenProcess.running = true;
            } else {
                console.error("code", code);
                console.error("Wallpaper not found:", wallpaperPath);
                ToastService.wallpaperErrorStatus = "error";
                ToastService.showError("Wallpaper processing failed");
            }
        }
    }

    Process {
        id: matugenProcess

        command: ["matugen", "-v", "image", wallpaperPath, "--json", "hex"]

        stdout: StdioCollector {
            id: matugenCollector

            onStreamFinished: {
                const out = matugenCollector.text;
                if (!out.length) {
                    console.error("matugen produced zero bytes\nstderr:", matugenProcess.stderr);
                    ToastService.wallpaperErrorStatus = "error";
                    ToastService.showError("Wallpaper Processing Failed");
                    return ;
                }
                try {
                    root.matugenJson = out;
                    root.matugenColors = JSON.parse(out);
                    root.colorsUpdated();
                    generateAppConfigs();
                    ToastService.clearWallpaperError();
                } catch (e) {
                    console.error("JSON parse failed:", e);
                    ToastService.wallpaperErrorStatus = "error";
                    ToastService.showError("Wallpaper Processing Failed");
                }
            }
        }

        stderr: StdioCollector {
            id: matugenErr
        }

    }

    function generateAppConfigs() {
        if (!matugenColors || !matugenColors.colors) {
            console.warn("No matugen colors available for app config generation");
            return;
        }

        generateNiriConfig();
        generateGhosttyConfig();
    }

    function generateNiriConfig() {
        var dark = matugenColors.colors.dark;
        if (!dark) return;

        var bg = dark.background || "#1a1c1e";
        var primary = dark.primary || "#42a5f5";
        var secondary = dark.secondary || "#8ab4f8";
        var inverse = dark.inverse_primary || "#6200ea";

        var content = `// AUTO-GENERATED on ${new Date().toISOString()}
layout {
    border {
        active-color   "${primary}"
        inactive-color "${secondary}"
    }
    focus-ring {
        active-color   "${inverse}"
    }
    background-color "${bg}"
}`;

        niriConfigWriter.command = ["bash", "-c", `echo '${content}' > niri-colors.generated.kdl`];
        niriConfigWriter.running = true;
    }

    function generateGhosttyConfig() {
        var dark = matugenColors.colors.dark;
        var light = matugenColors.colors.light;
        if (!dark || !light) return;

        var bg = dark.background || "#1a1c1e";
        var fg = dark.on_background || "#e3e8ef";
        var primary = dark.primary || "#42a5f5";
        var secondary = dark.secondary || "#8ab4f8";
        var tertiary = dark.tertiary || "#bb86fc";
        var tertiary_ctr = dark.tertiary_container || "#3700b3";
        var error = dark.error || "#cf6679";
        var inverse = dark.inverse_primary || "#6200ea";

        var bg_b = light.background || "#fef7ff";
        var fg_b = light.on_background || "#1d1b20";
        var primary_b = light.primary || "#1976d2";
        var secondary_b = light.secondary || "#1565c0";
        var tertiary_b = light.tertiary || "#7b1fa2";
        var tertiary_ctr_b = light.tertiary_container || "#e1bee7";
        var error_b = light.error || "#b00020";
        var inverse_b = light.inverse_primary || "#bb86fc";

        var content = `# AUTO-GENERATED on ${new Date().toISOString()}
background = ${bg}
foreground = ${fg}
cursor-color = ${inverse}
selection-background = ${secondary}
selection-foreground = #ffffff
palette = 0=${bg}
palette = 1=${error}
palette = 2=${tertiary}
palette = 3=${secondary}
palette = 4=${primary}
palette = 5=${tertiary_ctr}
palette = 6=${inverse}
palette = 7=${fg}
palette = 8=${bg_b}
palette = 9=${error_b}
palette = 10=${tertiary_b}
palette = 11=${secondary_b}
palette = 12=${primary_b}
palette = 13=${tertiary_ctr_b}
palette = 14=${inverse_b}
palette = 15=${fg_b}`;

        ghosttyConfigWriter.command = ["bash", "-c", `echo '${content}' > ghostty-colors.generated.conf`];
        ghosttyConfigWriter.running = true;
    }

    Process {
        id: niriConfigWriter
        running: false
        onExited: (exitCode) => {
            if (exitCode === 0) {
                console.log("Generated niri-colors.generated.kdl");
            } else {
                console.warn("Failed to generate niri config, exit code:", exitCode);
            }
        }
    }

    Process {
        id: ghosttyConfigWriter
        running: false
        onExited: (exitCode) => {
            if (exitCode === 0) {
                console.log("Generated ghostty-colors.generated.conf");
            } else {
                console.warn("Failed to generate ghostty config, exit code:", exitCode);
            }
        }
    }

}
