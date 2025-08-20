pragma Singleton

pragma ComponentBehavior

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    // Compositor detection
    property bool isHyprland: false
    property bool isNiri: false
    property string compositor: "unknown"

    readonly property string hyprlandSignature: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    readonly property string niriSocket: Quickshell.env("NIRI_SOCKET")

    property bool useNiriSorting: isNiri && NiriService

    // Unified sorted toplevels - automatically chooses sorting based on compositor
    property var sortedToplevels: {
        if (!ToplevelManager.toplevels || !ToplevelManager.toplevels.values) {
            return []
        }
                
        // Only use niri sorting when both compositor is niri AND niri service is ready
        if (useNiriSorting) {
            return NiriService.sortToplevels(ToplevelManager.toplevels.values)
        }

        // For non-niri compositors or when niri isn't ready yet, return unsorted toplevels
        return ToplevelManager.toplevels.values
    }

    Component.onCompleted: {
        console.log("CompositorService: Starting detection...")
        detectCompositor()
    }

    function detectCompositor() {
        // Check for Hyprland first
        if (hyprlandSignature && hyprlandSignature.length > 0) {
            isHyprland = true
            isNiri = false
            compositor = "hyprland"
            console.log("CompositorService: Detected Hyprland with signature:", hyprlandSignature)
            return
        }

        // Check for Niri
        if (niriSocket && niriSocket.length > 0) {
            // Verify the socket actually exists
            niriSocketCheck.running = true
        } else {
            // No compositor detected, default to Niri
            isHyprland = false
            isNiri = false
            compositor = "unknown"
            console.warn("CompositorService: No compositor detected")
        }
    }

    Process {
        id: niriSocketCheck
        command: ["test", "-S", root.niriSocket]

        onExited: exitCode => {
            if (exitCode === 0) {
                root.isNiri = true
                root.isHyprland = false
                root.compositor = "niri"
                console.log("CompositorService: Detected Niri with socket:", root.niriSocket)
            } else {
                root.isHyprland = false
                root.isNiri = true
                root.compositor = "niri"
                console.warn("CompositorService: Niri socket check failed, defaulting to Niri anyway")
            }
        }
    }
}