pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Singleton {
    id: root

    // Compositor detection
    property bool isHyprland: false
    property bool isNiri: false
    property string compositor: "unknown"

    readonly property string hyprlandSignature: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    readonly property string niriSocket: Quickshell.env("NIRI_SOCKET")

    property bool useNiriSorting: isNiri && NiriService
    property bool useHyprlandSorting: false

    // Unified sorted toplevels - automatically chooses sorting based on compositor
    property var sortedToplevels: {
        if (!ToplevelManager.toplevels || !ToplevelManager.toplevels.values) {
            return []
        }
                
        // Only use niri sorting when both compositor is niri AND niri service is ready
        if (useNiriSorting) {
            return NiriService.sortToplevels(ToplevelManager.toplevels.values)
        }

        if (isHyprland) {
            const hyprlandToplevels = Array.from(Hyprland.toplevels.values)
            
            const sortedHyprland = hyprlandToplevels.sort((a, b) => {
                // Sort by monitor first
                if (a.monitor && b.monitor) {
                    const monitorCompare = a.monitor.name.localeCompare(b.monitor.name)
                    if (monitorCompare !== 0) return monitorCompare
                }
                
                // Then by workspace
                if (a.workspace && b.workspace) {
                    const workspaceCompare = a.workspace.id - b.workspace.id
                    if (workspaceCompare !== 0) return workspaceCompare
                }
                
                // Then by position on workspace (x first for columns, then y within column)
                if (a.lastIpcObject && b.lastIpcObject && a.lastIpcObject.at && b.lastIpcObject.at) {
                    const xCompare = a.lastIpcObject.at[0] - b.lastIpcObject.at[0]
                    if (xCompare !== 0) return xCompare
                    return a.lastIpcObject.at[1] - b.lastIpcObject.at[1]
                }
                
                return 0
            })
            
            // Return the wayland Toplevel objects
            return sortedHyprland.map(hyprToplevel => hyprToplevel.wayland).filter(wayland => wayland !== null)
        }

        // For other compositors or when services aren't ready yet, return unsorted toplevels
        return ToplevelManager.toplevels.values
    }

    Component.onCompleted: {
        detectCompositor()
    }

    function detectCompositor() {
        // Check for Hyprland first
        if (hyprlandSignature && hyprlandSignature.length > 0) {
            isHyprland = true
            isNiri = false
            compositor = "hyprland"
            console.log("CompositorService: Detected Hyprland")
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

    function logout() {
        if (isNiri) {
            NiriService.quit()
            return
        }
        Hyprland.dispatch("exit")
    }
}