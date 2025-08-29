import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.ControlCenter.Widgets

BasePill {
    id: root

    isActive: NetworkService.networkStatus !== "disconnected"
    
    iconName: {
        if (NetworkService.networkStatus === "ethernet") {
            return "settings_ethernet"
        }
        if (NetworkService.networkStatus === "wifi") {
            return NetworkService.wifiSignalIcon
        }
        if (NetworkService.wifiEnabled) {
            return "signal_wifi_off"
        }
        return "wifi_off"
    }

    primaryText: {
        if (NetworkService.networkStatus === "ethernet") {
            return "Ethernet"
        }
        if (NetworkService.networkStatus === "wifi" && NetworkService.currentWifiSSID) {
            return NetworkService.currentWifiSSID
        }
        if (NetworkService.wifiEnabled) {
            return "Not connected"
        }
        return "WiFi off"
    }

    secondaryText: {
        if (NetworkService.networkStatus === "ethernet") {
            return "Connected"
        }
        if (NetworkService.networkStatus === "wifi") {
            return NetworkService.wifiSignalStrength > 0 ? NetworkService.wifiSignalStrength + "%" : "Connected"
        }
        if (NetworkService.wifiEnabled) {
            return "Select network"
        }
        return "Tap to enable"
    }
}