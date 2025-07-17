pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: (adapter && adapter.enabled) ?? false
    readonly property bool discovering: (adapter && adapter.discovering) ?? false
    readonly property var devices: adapter ? adapter.devices : null
    readonly property var pairedDevices: {
        if (!adapter || !adapter.devices)
            return [];

        return adapter.devices.values.filter((dev) => {
            return dev && dev.paired && isValidDevice(dev);
        });
    }
    readonly property var availableDevices: {
        if (!adapter || !adapter.discovering || !Bluetooth.devices)
            return [];

        var filtered = Bluetooth.devices.values.filter((dev) => {
            return dev && !dev.paired && !dev.pairing && !dev.blocked && isValidDevice(dev) && (dev.rssi === undefined || dev.rssi !== 0);
        });
        return sortByRssi(filtered);
    }
    readonly property var allDevicesWithBattery: {
        if (!adapter || !adapter.devices)
            return [];

        return adapter.devices.values.filter((dev) => {
            return dev && dev.batteryAvailable && dev.battery > 0;
        });
    }

    function sortByRssi(devices) {
        return devices.sort((a, b) => {
            var aRssi = (a.rssi !== undefined && a.rssi !== 0) ? a.rssi : -100;
            var bRssi = (b.rssi !== undefined && b.rssi !== 0) ? b.rssi : -100;
            return bRssi - aRssi;
        });
    }

    function isValidDevice(device) {
        if (!device)
            return false;

        var displayName = device.name || device.deviceName;
        if (!displayName || displayName.length < 2)
            return false;

        if (displayName.startsWith('/org/bluez') || displayName.includes('hci0'))
            return false;

        return displayName.length >= 3;
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

    function canPair(device) {
        if (!device)
            return false;

        return !device.paired && !device.pairing && !device.blocked;
    }

    function debugDevice(device) {
        console.log("Device:", device.name, "paired:", device.paired, "connected:", device.connected, "rssi:", device.rssi);
    }

    function getPairingStatus(device) {
        if (!device)
            return "unknown";

        if (device.pairing)
            return "pairing";

        if (device.paired)
            return "paired";

        if (device.blocked)
            return "blocked";

        return "available";
    }

    function getSignalStrength(device) {
        if (!device || device.rssi === undefined || device.rssi === 0)
            return "Unknown";

        var rssi = device.rssi;
        if (rssi >= -50)
            return "Excellent";

        if (rssi >= -60)
            return "Good";

        if (rssi >= -70)
            return "Fair";

        if (rssi >= -80)
            return "Poor";

        return "Very Poor";
    }

    function getSignalIcon(device) {
        if (!device || device.rssi === undefined || device.rssi === 0)
            return "signal_cellular_null";

        var rssi = device.rssi;
        if (rssi >= -50)
            return "signal_cellular_4_bar";

        if (rssi >= -60)
            return "signal_cellular_3_bar";

        if (rssi >= -70)
            return "signal_cellular_2_bar";

        if (rssi >= -80)
            return "signal_cellular_1_bar";

        return "signal_cellular_0_bar";
    }

    function toggleAdapter() {
        if (adapter)
            adapter.enabled = !adapter.enabled;

    }

    function startScan() {
        if (adapter)
            adapter.discovering = true;

    }

    function stopScan() {
        if (adapter)
            adapter.discovering = false;

    }

    function connect(address) {
        var device = _findDevice(address);
        if (device)
            device.connect();

    }

    function disconnect(address) {
        var device = _findDevice(address);
        if (device)
            device.disconnect();

    }

    function pair(address) {
        var device = _findDevice(address);
        if (device && canPair(device))
            device.pair();

    }

    function forget(address) {
        var device = _findDevice(address);
        if (device)
            device.forget();

    }

    function toggle(address) {
        var device = _findDevice(address);
        if (device) {
            if (device.connected)
                device.disconnect();
            else
                device.connect();
        }
    }

    function _findDevice(address) {
        if (!adapter)
            return null;

        return adapter.devices.values.find((d) => {
            return d && d.address === address;
        }) || (Bluetooth.devices ? Bluetooth.devices.values.find((d) => {
            return d && d.address === address;
        }) : null);
    }

}
