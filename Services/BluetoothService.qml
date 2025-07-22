pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: available ? adapter.enabled ?? false : false
    readonly property bool discovering: available ? adapter.discovering ?? false : false
    
    property bool operationInProgress: false
    readonly property var devices: adapter ? adapter.devices : null
    readonly property var pairedDevices: {
        if (!adapter || !adapter.devices)
            return [];

        return adapter.devices.values.filter((dev) => {
            return dev && (dev.paired || dev.trusted);
        });
    }
    readonly property var allDevicesWithBattery: {
        if (!adapter || !adapter.devices)
            return [];

        return adapter.devices.values.filter((dev) => {
            return dev && dev.batteryAvailable && dev.battery > 0;
        });
    }

    // Pairing dialog properties
    property bool pairingDialogVisible: false
    property int pairingType: BluetoothPairingRequestType.Authorization
    property string pendingDeviceAddress: ""
    property string pendingDeviceName: ""
    property int pendingPasskey: 0
    property var pendingToken: null
    property string inputText: ""

    function sortDevices(devices) {
        return devices.sort((a, b) => {
            var aName = a.name || a.deviceName || "";
            var bName = b.name || b.deviceName || "";
            
            var aHasRealName = aName.includes(" ") && aName.length > 3;
            var bHasRealName = bName.includes(" ") && bName.length > 3;
            
            if (aHasRealName && !bHasRealName) return -1;
            if (!aHasRealName && bHasRealName) return 1;
            
            var aSignal = (a.signalStrength !== undefined && a.signalStrength > 0) ? a.signalStrength : 0;
            var bSignal = (b.signalStrength !== undefined && b.signalStrength > 0) ? b.signalStrength : 0;
            return bSignal - aSignal;
        });
    }

    function getDeviceIcon(device) {
        if (!device)
            return "bluetooth";

        var name = (device.name || device.deviceName || "").toLowerCase();
        var icon = (device.icon || "").toLowerCase();
        if (icon.includes("headset") || icon.includes("audio") || name.includes("headphone") || name.includes("airpod") || name.includes("headset") || name.includes("arctis"))
            return "headset";

        if (icon.includes("mouse") || name.includes("mouse"))
            return "mouse";

        if (icon.includes("keyboard") || name.includes("keyboard"))
            return "keyboard";

        if (icon.includes("phone") || name.includes("phone") || name.includes("iphone") || name.includes("android") || name.includes("samsung"))
            return "smartphone";

        if (icon.includes("watch") || name.includes("watch"))
            return "watch";

        if (icon.includes("speaker") || name.includes("speaker"))
            return "speaker";

        if (icon.includes("display") || name.includes("tv"))
            return "tv";

        return "bluetooth";
    }

    function getDeviceType(device) {
        if (!device)
            return "bluetooth";

        var name = (device.name || device.deviceName || "").toLowerCase();
        var icon = (device.icon || "").toLowerCase();
        if (icon.includes("headset") || icon.includes("audio") || name.includes("headphone") || name.includes("airpod") || name.includes("headset") || name.includes("arctis"))
            return "headset";

        if (icon.includes("mouse") || name.includes("mouse"))
            return "mouse";

        if (icon.includes("keyboard") || name.includes("keyboard"))
            return "keyboard";

        if (icon.includes("phone") || name.includes("phone") || name.includes("iphone") || name.includes("android") || name.includes("samsung"))
            return "phone";

        if (icon.includes("watch") || name.includes("watch"))
            return "watch";

        if (icon.includes("speaker") || name.includes("speaker"))
            return "speaker";

        if (icon.includes("display") || name.includes("tv"))
            return "tv";

        return "bluetooth";
    }

    function canConnect(device) {
        if (!device)
            return false;

        return !device.paired && !device.pairing && !device.blocked;
    }

    function debugDevice(device) {
        console.log("Device:", device.name, "paired:", device.paired, "connected:", device.connected, "signalStrength:", device.signalStrength);
    }


    function getSignalStrength(device) {
        if (!device || device.signalStrength === undefined || device.signalStrength <= 0)
            return "Unknown";

        var signal = device.signalStrength;
        if (signal >= 80)
            return "Excellent";

        if (signal >= 60)
            return "Good";

        if (signal >= 40)
            return "Fair";

        if (signal >= 20)
            return "Poor";

        return "Very Poor";
    }

    function getSignalIcon(device) {
        if (!device || device.signalStrength === undefined || device.signalStrength <= 0)
            return "signal_cellular_null";

        var signal = device.signalStrength;
        if (signal >= 80)
            return "signal_cellular_4_bar";

        if (signal >= 60)
            return "signal_cellular_3_bar";

        if (signal >= 40)
            return "signal_cellular_2_bar";

        if (signal >= 20)
            return "signal_cellular_1_bar";

        return "signal_cellular_0_bar";
    }
    
    function isDeviceBusy(device) {
        if (!device) return false;
        return device.pairing || device.state === BluetoothDeviceState.Disconnecting || device.state === BluetoothDeviceState.Connecting;
    }
    
    function connectDeviceWithTrust(device) {
        if (!device) return;
        
        device.connect()
    }
    
    function toggleAdapter() {
        if (!available || operationInProgress) {
            console.warn("BluetoothService: Cannot toggle adapter - not available or operation in progress");
            return false;
        }
        
        operationInProgress = true;
        var targetState = !adapter.enabled;
        
        try {
            adapter.enabled = targetState;
            return true;
        } catch (error) {
            console.error("BluetoothService: Failed to toggle adapter:", error);
            operationInProgress = false;
            return false;
        }
    }
    
    function toggleDiscovery() {
        if (!available || !adapter.enabled || operationInProgress) {
            console.warn("BluetoothService: Cannot toggle discovery - adapter not ready or operation in progress");
            return false;
        }
        
        operationInProgress = true;
        var targetState = !adapter.discovering;
        
        try {
            adapter.discovering = targetState;
            return true;
        } catch (error) {
            console.error("BluetoothService: Failed to toggle discovery:", error);
            operationInProgress = false;
            return false;
        }
    }
    
    // Monitor adapter state changes to clear operation flags
    Connections {
        target: adapter
        ignoreUnknownSignals: true
        
        function onEnabledChanged() {
            operationInProgress = false;
        }
        
        function onDiscoveringChanged() {
            operationInProgress = false;
        }
    }

    // Pairing agent signal handler
    Connections {
        target: Bluetooth.agent
        ignoreUnknownSignals: true

        function onPairingRequested(deviceAddress, type, passkey, token) {
            console.log("BluetoothService: Pairing requested for", deviceAddress, "type:", type, "passkey:", passkey, "token:", token);
            root.pairingType = type;
            root.pendingDeviceAddress = deviceAddress;
            root.pendingPasskey = passkey;
            root.pendingToken = token;
            root.inputText = "";
            
            // Try to find and store the device name using MAC address
            var device = root.getDeviceFromAddress(deviceAddress);
            root.pendingDeviceName = device ? (device.name || device.deviceName || deviceAddress) : deviceAddress;
            console.log("BluetoothService: Device name:", root.pendingDeviceName, "for address:", deviceAddress, "token:", token);
            
            root.pairingDialogVisible = true;
        }
    }

    function acceptPairing() {
        console.log("BluetoothService: Accepting pairing for", root.pendingDeviceAddress, "type:", root.pairingType, "token:", root.pendingToken);
        if (!Bluetooth.agent || root.pendingToken === null) return;

        switch (root.pairingType) {
            case BluetoothPairingRequestType.Authorization:
            case BluetoothPairingRequestType.Confirmation:
            case BluetoothPairingRequestType.ServiceAuthorization:
                Bluetooth.agent.respondToRequest(root.pendingToken, true);
                break;

            case BluetoothPairingRequestType.PinCode:
                if (root.inputText.length > 0) {
                    Bluetooth.agent.respondWithPinCode(root.pendingToken, root.inputText);
                } else {
                    console.warn("BluetoothService: No PIN code entered");
                    return;
                }
                break;

            case BluetoothPairingRequestType.Passkey:
                var passkey = parseInt(root.inputText);
                if (passkey >= 0 && passkey <= 999999) {
                    Bluetooth.agent.respondWithPasskey(root.pendingToken, passkey);
                } else {
                    console.warn("BluetoothService: Invalid passkey:", root.inputText);
                    return;
                }
                break;
        }

        closePairingDialog();
    }

    function rejectPairing() {
        console.log("BluetoothService: Rejecting pairing for", root.pendingDeviceAddress, "token:", root.pendingToken);
        if (Bluetooth.agent && root.pendingToken !== null) {
            Bluetooth.agent.respondToRequest(root.pendingToken, false);
        }
        closePairingDialog();
    }

    function closePairingDialog() {
        root.pairingDialogVisible = false;
        root.pendingDeviceAddress = "";
        root.pendingDeviceName = "";
        root.pendingPasskey = 0;
        root.pendingToken = null;
        root.inputText = "";
        root.pairingType = BluetoothPairingRequestType.Authorization;
    }

    function getDeviceFromPath(devicePath) {
        if (!adapter || !adapter.devices || !devicePath)
            return null;
        return adapter.devices.values.find(d => d && d.path === devicePath) || null;
    }

    function getDeviceFromAddress(deviceAddress) {
        if (!adapter || !adapter.devices || !deviceAddress)
            return null;
        return adapter.devices.values.find(d => d && d.address === deviceAddress) || null;
    }



}
