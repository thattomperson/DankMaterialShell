pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Minimal VPN controller backed by NetworkManager (nmcli + D-Bus monitor)
Singleton {
    id: root

    // State
    property bool available: true
    property bool isBusy: false
    property string errorMessage: ""

    // Profiles discovered on the system
    // [{ name, uuid, type }]
    property var profiles: []

    // Active VPN connection (if any)
    property string activeUuid: ""
    property string activeName: ""
    property string activeDevice: ""
    property string activeState: "" // activating, activated, deactivating
    property bool connected: activeUuid !== "" && activeState === "activated"

    // Use implicit property notify signals (profilesChanged, activeUuidChanged, etc.)

    Component.onCompleted: initialize()

    function initialize() {
        // Start monitoring NetworkManager for changes
        nmMonitor.running = true
        refreshAll()
    }

    function refreshAll() {
        listProfiles()
        refreshActive()
    }

    // Monitor NetworkManager changes and refresh on activity
    Process {
        id: nmMonitor
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.NetworkManager"]
        running: false

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (line.includes("ActiveConnection") || line.includes("PropertiesChanged") || line.includes("StateChanged")) {
                    refreshAll()
                }
            }
        }
    }

    // Query all VPN profiles
    function listProfiles() {
        getProfiles.running = true
    }

    Process {
        id: getProfiles
        command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE", "connection", "show"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().length ? text.trim().split('\n') : []
                const out = []
                for (const line of lines) {
                    const parts = line.split(':')
                    if (parts.length >= 3 && (parts[2] === "vpn" || parts[2] === "wireguard")) {
                        out.push({ name: parts[0], uuid: parts[1], type: parts[2] })
                    }
                }
                root.profiles = out
            }
        }
    }

    // Query active VPN connection
    function refreshActive() {
        getActive.running = true
    }

    Process {
        id: getActive
        command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,DEVICE,STATE", "connection", "show", "--active"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().length ? text.trim().split('\n') : []
                let found = false
                for (const line of lines) {
                    const parts = line.split(':')
                    if (parts.length >= 5 && (parts[2] === "vpn" || parts[2] === "wireguard")) {
                        root.activeName = parts[0]
                        root.activeUuid = parts[1]
                        root.activeDevice = parts[3]
                        root.activeState = parts[4]
                        found = true
                        break
                    }
                }
                if (!found) {
                    root.activeName = ""
                    root.activeUuid = ""
                    root.activeDevice = ""
                    root.activeState = ""
                }
            }
        }
    }

    function _looksLikeUuid(s) {
        // Very loose check for UUID pattern
        return s && s.indexOf('-') !== -1 && s.length >= 8
    }

    function connect(uuidOrName) {
        if (root.isBusy) return
        root.isBusy = true
        root.errorMessage = ""
        if (_looksLikeUuid(uuidOrName)) {
            vpnUp.command = ["nmcli", "connection", "up", "uuid", uuidOrName]
        } else {
            vpnUp.command = ["nmcli", "connection", "up", "id", uuidOrName]
        }
        vpnUp.running = true
    }

    function disconnect(uuidOrName) {
        if (root.isBusy) return
        root.isBusy = true
        root.errorMessage = ""
        if (_looksLikeUuid(uuidOrName)) {
            vpnDown.command = ["nmcli", "connection", "down", "uuid", uuidOrName]
        } else {
            vpnDown.command = ["nmcli", "connection", "down", "id", uuidOrName]
        }
        vpnDown.running = true
    }

    function toggle(uuid) {
        if (root.activeUuid && (uuid === undefined || uuid === root.activeUuid)) {
            disconnect(root.activeUuid)
        } else if (uuid) {
            connect(uuid)
        } else if (root.profiles.length > 0) {
            connect(root.profiles[0].uuid)
        }
    }

    Process {
        id: vpnUp
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.isBusy = false
                if (!text.toLowerCase().includes("successfully")) {
                    root.errorMessage = text.trim()
                }
                refreshAll()
            }
        }
        onExited: exitCode => {
            root.isBusy = false
            if (exitCode !== 0 && root.errorMessage === "") {
                root.errorMessage = "Failed to connect VPN"
            }
        }
    }

    Process {
        id: vpnDown
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.isBusy = false
                if (!text.toLowerCase().includes("deactivated") && !text.toLowerCase().includes("successfully")) {
                    root.errorMessage = text.trim()
                }
                refreshAll()
            }
        }
        onExited: exitCode => {
            root.isBusy = false
            if (exitCode !== 0 && root.errorMessage === "") {
                root.errorMessage = "Failed to disconnect VPN"
            }
        }
    }
}
