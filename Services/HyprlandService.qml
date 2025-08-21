pragma Singleton

pragma ComponentBehavior

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property bool hyprlandAvailable: {
        const signature = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
        return signature && signature.length > 0
    }

    property var allWorkspaces: hyprlandAvailable && Hyprland.workspaces ? Hyprland.workspaces.values : []
    property var focusedWorkspace: hyprlandAvailable ? Hyprland.focusedWorkspace : null
    property var monitors: hyprlandAvailable ? Hyprland.monitors : []
    property var focusedMonitor: hyprlandAvailable ? Hyprland.focusedMonitor : null

    function getWorkspacesForMonitor(monitorName) {
        if (!hyprlandAvailable) return []
        
        const workspaces = Hyprland.workspaces ? Hyprland.workspaces.values : []
        if (!workspaces || workspaces.length === 0) return []
        
        // If no monitor name specified, return all workspaces
        if (!monitorName) {
            const allWorkspacesCopy = []
            for (let i = 0; i < workspaces.length; i++) {
                const workspace = workspaces[i]
                if (workspace) {
                    allWorkspacesCopy.push(workspace)
                }
            }
            allWorkspacesCopy.sort((a, b) => a.id - b.id)
            return allWorkspacesCopy
        }
        
        const filtered = []
        for (let i = 0; i < workspaces.length; i++) {
            const workspace = workspaces[i]
            if (workspace && workspace.monitor && workspace.monitor.name === monitorName) {
                filtered.push(workspace)
            }
        }
        
        // Sort by workspace ID
        filtered.sort((a, b) => a.id - b.id)
        return filtered
    }

    function getCurrentWorkspaceForMonitor(monitorName) {
        if (!hyprlandAvailable) return null
        
        // If no monitor name specified, return the globally focused workspace
        if (!monitorName) {
            return focusedWorkspace
        }
        
        if (focusedMonitor && focusedMonitor.name === monitorName) {
            return focusedWorkspace
        }
        
        const monitorWorkspaces = getWorkspacesForMonitor(monitorName)
        for (let i = 0; i < monitorWorkspaces.length; i++) {
            const ws = monitorWorkspaces[i]
            if (ws && ws.active) {
                return ws
            }
        }
        return null
    }

    function switchToWorkspace(workspaceId) {
        if (!hyprlandAvailable) return
        
        Hyprland.dispatch(`workspace ${workspaceId}`)
    }

    function switchToWorkspaceByName(workspaceName) {
        if (!hyprlandAvailable) return
        
        Hyprland.dispatch(`workspace name:${workspaceName}`)
    }

    function moveToWorkspace(workspaceId) {
        if (!hyprlandAvailable) return
        
        Hyprland.dispatch(`movetoworkspace ${workspaceId}`)
    }

    function createWorkspace(workspaceId) {
        if (!hyprlandAvailable) return
        
        Hyprland.dispatch(`workspace ${workspaceId}`)
    }

    function getWorkspaceDisplayNumbers() {
        if (!hyprlandAvailable) return [1, 2, 3, 4]
        
        // Get all existing workspaces from Hyprland.workspaces.values
        const workspaces = Hyprland.workspaces ? Hyprland.workspaces.values : []
        if (!workspaces || workspaces.length === 0) {
            // If no workspaces detected, show at least current + a few more
            const current = getCurrentWorkspaceNumber()
            return [Math.max(1, current - 1), current, current + 1, current + 2].filter((ws, i, arr) => arr.indexOf(ws) === i && ws > 0)
        }
        
        // Get workspace IDs and ensure we show a reasonable range
        const numbers = []
        let maxId = 0
        
        for (let i = 0; i < workspaces.length; i++) {
            const ws = workspaces[i]
            if (ws && ws.id > 0) {
                numbers.push(ws.id)
                maxId = Math.max(maxId, ws.id)
            }
        }
        
        // Always ensure we have at least one workspace beyond the highest
        // to allow easy navigation to new workspaces
        if (maxId > 0 && numbers.indexOf(maxId + 1) === -1) {
            numbers.push(maxId + 1)
        }
        
        return numbers.sort((a, b) => a - b)
    }

    function getCurrentWorkspaceNumber() {
        if (!hyprlandAvailable) return 1
        
        // Use the focused workspace directly
        const focused = Hyprland.focusedWorkspace
        return focused ? focused.id : 1
    }

    function sortToplevels(toplevels) {
        if (!hyprlandAvailable || !toplevels) return []
        
        // Create a copy of the array since the original might be readonly
        const sortedArray = Array.from(toplevels)
        
        return sortedArray.sort((a, b) => {
            if (a.workspace && b.workspace) {
                if (a.workspace.monitor && b.workspace.monitor) {
                    const monitorCompare = a.workspace.monitor.name.localeCompare(b.workspace.monitor.name)
                    if (monitorCompare !== 0) return monitorCompare
                }
                
                const workspaceCompare = a.workspace.id - b.workspace.id
                if (workspaceCompare !== 0) return workspaceCompare
            }
            
            return 0
        })
    }

    // Signals for workspace changes that WorkspaceSwitcher can connect to
    signal workspacesUpdated()
    signal focusedWorkspaceUpdated() 
    signal focusedMonitorUpdated()

    // Monitor changes to properties and emit our signals
    onAllWorkspacesChanged: workspacesUpdated()
    onFocusedWorkspaceChanged: focusedWorkspaceUpdated()
    onFocusedMonitorChanged: focusedMonitorUpdated()

    Component.onCompleted: {
        if (hyprlandAvailable) {
            console.log("HyprlandService: Initialized with Hyprland support")
        }
    }
}