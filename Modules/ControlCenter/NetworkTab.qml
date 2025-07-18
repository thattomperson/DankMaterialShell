import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets
import "../../Widgets"

Item {
    // Default to WiFi when nothing is connected

    id: networkTab

    property int networkSubTab: {
        // Default to WiFi tab if WiFi is connected, otherwise Ethernet
        if (NetworkService.networkStatus === "wifi")
            return 1;
        else if (NetworkService.networkStatus === "ethernet")
            return 0;
        else
            return 1;
    }

    Column {
        anchors.fill: parent
        spacing: Theme.spacingM

        // Network sub-tabs
        DankTabBar {
            width: parent.width
            currentIndex: networkTab.networkSubTab
            model: [
                {
                    "icon": "lan",
                    "text": "Ethernet"
                },
                {
                    "icon": NetworkService.wifiEnabled ? "wifi" : "wifi_off",
                    "text": "Wi-Fi"
                }
            ]
            onTabClicked: function(index) {
                networkTab.networkSubTab = index;
                if (index === 0) {
                    WifiService.autoRefreshEnabled = false;
                } else {
                    WifiService.autoRefreshEnabled = true;
                    if (NetworkService.wifiEnabled)
                        WifiService.scanWifi();
                }
            }
        }

        // Ethernet Tab Content
        Flickable {
            width: parent.width
            height: parent.height - 48
            visible: networkTab.networkSubTab === 0
            clip: true
            contentWidth: width
            contentHeight: ethernetContent.height
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 8000
            maximumFlickVelocity: 15000

            Column {
                id: ethernetContent

                width: parent.width
                spacing: Theme.spacingL

                // Ethernet status card
                Rectangle {
                    width: parent.width
                    height: 70
                    radius: Theme.cornerRadius
                    color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.5)
                    border.color: NetworkService.networkStatus === "ethernet" ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                    border.width: NetworkService.networkStatus === "ethernet" ? 2 : 1
                    visible: true

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingL
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "lan"
                            size: Theme.iconSizeLarge - 4
                            color: networkTab.networkStatus === "ethernet" ? Theme.primary : Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            spacing: 4
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: networkTab.networkStatus === "ethernet" ? (networkTab.ethernetInterface || "Ethernet") : "Ethernet"
                                font.pixelSize: Theme.fontSizeMedium
                                color: networkTab.networkStatus === "ethernet" ? Theme.primary : Theme.surfaceText
                                font.weight: Font.Medium
                            }

                            Text {
                                text: NetworkService.ethernetConnected ? (NetworkService.ethernetIP || "Connected") : "Disconnected"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                            }

                        }

                        // Force Ethernet preference button
                        Rectangle {
                            width: 150
                            height: 30
                            color: networkTab.networkStatus === "ethernet" ? Theme.primary : Theme.surface
                            border.color: Theme.primary
                            border.width: 1
                            radius: 6
                            anchors.verticalCenter: parent.verticalCenter
                            z: 10
                            opacity: networkTab.changingNetworkPreference ? 0.6 : 1
                            visible: NetworkService.networkStatus !== "ethernet" && NetworkService.wifiAvailable && NetworkService.wifiEnabled

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingXS

                                DankIcon {
                                    id: ethernetPreferenceIcon

                                    name: networkTab.changingNetworkPreference ? "sync" : ""
                                    size: Theme.fontSizeSmall
                                    color: networkTab.networkStatus === "ethernet" ? Theme.background : Theme.primary
                                    visible: networkTab.changingNetworkPreference
                                    anchors.verticalCenter: parent.verticalCenter
                                    rotation: networkTab.changingNetworkPreference ? ethernetPreferenceIcon.rotation : 0

                                    RotationAnimation {
                                        target: ethernetPreferenceIcon
                                        property: "rotation"
                                        running: networkTab.changingNetworkPreference
                                        from: 0
                                        to: 360
                                        duration: 1000
                                        loops: Animation.Infinite
                                    }

                                }

                                Text {
                                    text: networkTab.changingNetworkPreference ? "Switching..." : (networkTab.networkStatus === "ethernet" ? "" : "Prefer over WiFi")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: networkTab.networkStatus === "ethernet" ? Theme.background : Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                    font.weight: Font.Medium
                                }

                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                propagateComposedEvents: false
                                enabled: !networkTab.changingNetworkPreference
                                onClicked: {
                                    console.log("*** ETHERNET PREFERENCE BUTTON CLICKED ***");
                                    if (networkTab.networkStatus !== "ethernet") {
                                        console.log("Setting preference to ethernet");
                                        NetworkService.setNetworkPreference("ethernet");
                                    } else {
                                        console.log("Setting preference to auto");
                                        NetworkService.setNetworkPreference("auto");
                                    }
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Theme.shortDuration
                                    easing.type: Theme.standardEasing
                                }

                            }

                        }

                    }

                }

                // Ethernet control button
                Rectangle {
                    width: parent.width
                    height: 50
                    radius: Theme.cornerRadius
                    color: ethernetControlArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08)

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingM

                        DankIcon {
                            name: networkTab.ethernetConnected ? "link_off" : "link"
                            size: Theme.iconSize
                            color: networkTab.ethernetConnected ? Theme.error : Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: networkTab.ethernetConnected ? "Disconnect Ethernet" : "Connect Ethernet"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }

                    }

                    MouseArea {
                        id: ethernetControlArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            NetworkService.toggleNetworkConnection("ethernet");
                        }
                    }

                }

            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

        }

        // WiFi Tab Content
        Flickable {
            width: parent.width
            height: parent.height - 48
            visible: networkTab.networkSubTab === 1
            clip: true
            contentWidth: width
            contentHeight: wifiContent.height
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 8000
            maximumFlickVelocity: 15000

            Column {
                id: wifiContent

                width: parent.width
                spacing: Theme.spacingM


                // Current WiFi connection (if connected)
                Rectangle {
                    width: parent.width
                    height: 60
                    radius: Theme.cornerRadius
                    color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.5)
                    border.color: NetworkService.networkStatus === "wifi" ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                    border.width: NetworkService.networkStatus === "wifi" ? 2 : 1
                    visible: NetworkService.wifiAvailable

                    // WiFi icon
                    DankIcon {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingL
                        anchors.verticalCenter: parent.verticalCenter
                        name: {
                            if (!NetworkService.wifiEnabled) {
                                return "wifi_off";
                            } else if (NetworkService.networkStatus === "wifi") {
                                return WifiService.wifiSignalStrength === "excellent" ? "wifi" : WifiService.wifiSignalStrength === "good" ? "wifi_2_bar" : WifiService.wifiSignalStrength === "fair" ? "wifi_1_bar" : WifiService.wifiSignalStrength === "poor" ? "wifi_calling_3" : "wifi";
                            } else {
                                return "wifi";
                            }
                        }
                        size: Theme.iconSize
                        color: NetworkService.networkStatus === "wifi" ? Theme.primary : Theme.surfaceText
                    }

                    // WiFi info text
                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingL + Theme.iconSize + Theme.spacingM
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingL + 48 + Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            text: {
                                if (!NetworkService.wifiEnabled) {
                                    return "WiFi is off";
                                } else if (NetworkService.wifiEnabled && WifiService.currentWifiSSID) {
                                    return WifiService.currentWifiSSID || "Connected";
                                } else {
                                    return "Not Connected";
                                }
                            }
                            font.pixelSize: Theme.fontSizeMedium
                            color: NetworkService.networkStatus === "wifi" ? Theme.primary : Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        Text {
                            text: {
                                if (!NetworkService.wifiEnabled) {
                                    return "Turn on WiFi to see available networks";
                                } else if (NetworkService.wifiEnabled && WifiService.currentWifiSSID) {
                                    return NetworkService.wifiIP || "Connected";
                                } else {
                                    return "Select a network below";
                                }
                            }
                            font.pixelSize: Theme.fontSizeSmall
                            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                        }
                    }

                    // WiFi toggle switch
                    DankToggle {
                        checked: NetworkService.wifiEnabled
                        enabled: true
                        toggling: NetworkService.wifiToggling
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingL
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: {
                            NetworkService.toggleWifiRadio();
                            refreshTimer.triggered = true;
                        }
                    }

                    // Force WiFi preference button
                    Rectangle {
                        width: 150
                        height: 30
                        color: networkTab.networkStatus === "wifi" ? Theme.primary : Theme.surface
                        border.color: Theme.primary
                        border.width: 1
                        radius: 6
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingL + 48 + Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: networkTab.changingNetworkPreference ? 0.6 : 1
                        visible: NetworkService.networkStatus !== "wifi" && NetworkService.ethernetConnected && NetworkService.wifiEnabled

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            DankIcon {
                                id: wifiPreferenceIcon

                                name: networkTab.changingNetworkPreference ? "sync" : ""
                                size: Theme.fontSizeSmall
                                color: networkTab.networkStatus === "wifi" ? Theme.background : Theme.primary
                                visible: networkTab.changingNetworkPreference
                                anchors.verticalCenter: parent.verticalCenter
                                rotation: networkTab.changingNetworkPreference ? wifiPreferenceIcon.rotation : 0

                                RotationAnimation {
                                    target: wifiPreferenceIcon
                                    property: "rotation"
                                    running: networkTab.changingNetworkPreference
                                    from: 0
                                    to: 360
                                    duration: 1000
                                    loops: Animation.Infinite
                                }

                            }

                            Text {
                                text: NetworkService.changingNetworkPreference ? "Switching..." : "Prefer over Ethernet"
                                font.pixelSize: Theme.fontSizeSmall
                                color: NetworkService.networkStatus === "wifi" ? Theme.background : Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                                font.weight: Font.Medium
                            }

                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            propagateComposedEvents: false
                            enabled: !networkTab.changingNetworkPreference
                            onClicked: {
                                console.log("Force WiFi preference clicked");
                                if (NetworkService.networkStatus !== "wifi")
                                    NetworkService.setNetworkPreference("wifi");
                                else
                                    NetworkService.setNetworkPreference("auto");
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.shortDuration
                                easing.type: Theme.standardEasing
                            }

                        }

                    }

                }

                // Available WiFi Networks
                Column {
                    width: parent.width
                    spacing: Theme.spacingS
                    visible: NetworkService.wifiEnabled

                    Row {
                        width: parent.width

                        Text {
                            text: "Available Networks"
                            font.pixelSize: Theme.fontSizeLarge
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        Item {
                            width: parent.width - 200
                            height: 1
                        }

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: refreshArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : WifiService.isScanning ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.06) : "transparent"

                            DankIcon {
                                id: refreshIcon

                                anchors.centerIn: parent
                                name: WifiService.isScanning ? "sync" : "refresh"
                                size: Theme.iconSize - 4
                                color: Theme.surfaceText
                                rotation: WifiService.isScanning ? refreshIcon.rotation : 0

                                RotationAnimation {
                                    target: refreshIcon
                                    property: "rotation"
                                    running: WifiService.isScanning
                                    from: 0
                                    to: 360
                                    duration: 1000
                                    loops: Animation.Infinite
                                }

                                Behavior on rotation {
                                    RotationAnimation {
                                        duration: 200
                                        easing.type: Easing.OutQuad
                                    }

                                }

                            }

                            MouseArea {
                                id: refreshArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !WifiService.isScanning
                                onClicked: {
                                    if (NetworkService.wifiEnabled)
                                        WifiService.scanWifi();

                                }
                            }

                        }

                    }

                    // Connection status indicator
                    Rectangle {
                        width: parent.width
                        height: 32
                        radius: Theme.cornerRadius
                        color: {
                            if (WifiService.connectionStatus === "connecting")
                                return Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.12);
                            else if (WifiService.connectionStatus === "failed")
                                return Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12);
                            else if (WifiService.connectionStatus === "connected")
                                return Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.12);
                            return "transparent";
                        }
                        border.color: {
                            if (WifiService.connectionStatus === "connecting")
                                return Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.3);
                            else if (WifiService.connectionStatus === "failed")
                                return Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.3);
                            else if (WifiService.connectionStatus === "connected")
                                return Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.3);
                            return "transparent";
                        }
                        border.width: WifiService.connectionStatus !== "" ? 1 : 0
                        visible: WifiService.connectionStatus !== ""

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            DankIcon {
                                id: connectionIcon

                                name: {
                                    if (WifiService.connectionStatus === "connecting")
                                        return "sync";

                                    if (WifiService.connectionStatus === "failed")
                                        return "error";

                                    if (WifiService.connectionStatus === "connected")
                                        return "check_circle";

                                    return "";
                                }
                                size: Theme.iconSize - 6
                                color: {
                                    if (WifiService.connectionStatus === "connecting")
                                        return Theme.warning;

                                    if (WifiService.connectionStatus === "failed")
                                        return Theme.error;

                                    if (WifiService.connectionStatus === "connected")
                                        return Theme.success;

                                    return Theme.surfaceText;
                                }
                                anchors.verticalCenter: parent.verticalCenter
                                rotation: WifiService.connectionStatus === "connecting" ? connectionIcon.rotation : 0

                                RotationAnimation {
                                    target: connectionIcon
                                    property: "rotation"
                                    running: WifiService.connectionStatus === "connecting"
                                    from: 0
                                    to: 360
                                    duration: 1000
                                    loops: Animation.Infinite
                                }

                                Behavior on rotation {
                                    RotationAnimation {
                                        duration: 200
                                        easing.type: Easing.OutQuad
                                    }

                                }

                            }

                            Text {
                                text: {
                                    if (WifiService.connectionStatus === "connecting")
                                        return "Connecting to " + WifiService.connectingSSID;

                                    if (WifiService.connectionStatus === "failed")
                                        return "Failed to connect to " + WifiService.connectingSSID;

                                    if (WifiService.connectionStatus === "connected")
                                        return "Connected to " + WifiService.connectingSSID;

                                    return "";
                                }
                                font.pixelSize: Theme.fontSizeMedium
                                color: {
                                    if (WifiService.connectionStatus === "connecting")
                                        return Theme.warning;

                                    if (WifiService.connectionStatus === "failed")
                                        return Theme.error;

                                    if (WifiService.connectionStatus === "connected")
                                        return Theme.success;

                                    return Theme.surfaceText;
                                }
                                anchors.verticalCenter: parent.verticalCenter
                            }

                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.shortDuration
                                easing.type: Theme.standardEasing
                            }

                        }

                    }

                    // WiFi networks list (only show if WiFi is available and enabled)
                    Repeater {
                        model: NetworkService.wifiAvailable && NetworkService.wifiEnabled ? WifiService.wifiNetworks : []

                        Rectangle {
                            width: parent.width
                            height: 42
                            radius: Theme.cornerRadiusSmall
                            color: networkArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : modelData.connected ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                            border.color: modelData.connected ? Theme.primary : "transparent"
                            border.width: modelData.connected ? 1 : 0

                            Item {
                                anchors.fill: parent
                                anchors.margins: Theme.spacingS

                                // Signal strength icon
                                DankIcon {
                                    id: signalIcon

                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: modelData.signalStrength === "excellent" ? "wifi" : modelData.signalStrength === "good" ? "wifi_2_bar" : modelData.signalStrength === "fair" ? "wifi_1_bar" : modelData.signalStrength === "poor" ? "wifi_calling_3" : "wifi"
                                    size: Theme.iconSize
                                    color: modelData.connected ? Theme.primary : Theme.surfaceText
                                }

                                // Network info
                                Column {
                                    anchors.left: signalIcon.right
                                    anchors.leftMargin: Theme.spacingS
                                    anchors.right: rightIcons.left
                                    anchors.rightMargin: Theme.spacingS
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        width: parent.width
                                        text: modelData.ssid
                                        font.pixelSize: Theme.fontSizeMedium
                                        color: modelData.connected ? Theme.primary : Theme.surfaceText
                                        font.weight: modelData.connected ? Font.Medium : Font.Normal
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: {
                                            if (modelData.connected)
                                                return "Connected";

                                            if (modelData.saved)
                                                return "Saved" + (modelData.secured ? " • Secured" : " • Open");

                                            return modelData.secured ? "Secured" : "Open";
                                        }
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                                        elide: Text.ElideRight
                                    }

                                }

                                // Right side icons
                                Row {
                                    id: rightIcons

                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.spacingXS

                                    // Lock icon (if secured)
                                    DankIcon {
                                        name: "lock"
                                        size: Theme.iconSize - 6
                                        color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.6)
                                        visible: modelData.secured
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    // Forget button (for saved networks)
                                    Rectangle {
                                        width: 28
                                        height: 28
                                        radius: 14
                                        color: forgetArea.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : "transparent"
                                        visible: modelData.saved || modelData.connected

                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: "delete"
                                            size: Theme.iconSize - 6
                                            color: forgetArea.containsMouse ? Theme.error : Theme.surfaceText
                                        }

                                        MouseArea {
                                            id: forgetArea

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                WifiService.forgetWifiNetwork(modelData.ssid);
                                            }
                                        }

                                    }

                                }

                            }

                            MouseArea {
                                // Already connected, do nothing or show info

                                id: networkArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.connected)
                                        return ;

                                    if (modelData.saved) {
                                        // Saved network, connect directly
                                        WifiService.connectToWifi(modelData.ssid);
                                    } else if (modelData.secured) {
                                        // Secured network, need password - use root dialog
                                        wifiPasswordDialog.wifiPasswordSSID = modelData.ssid;
                                        wifiPasswordDialog.wifiPasswordInput = "";
                                        wifiPasswordDialog.wifiPasswordDialogVisible = true;
                                    } else {
                                        // Open network, connect directly
                                        WifiService.connectToWifi(modelData.ssid);
                                    }
                                }
                            }

                        }

                    }

                }

                // WiFi disabled message
                Column {
                    width: parent.width
                    spacing: Theme.spacingM
                    visible: !NetworkService.wifiEnabled
                    anchors.horizontalCenter: parent.horizontalCenter

                    DankIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: "wifi_off"
                        size: 48
                        color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.3)
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "WiFi is turned off"
                        font.pixelSize: Theme.fontSizeLarge
                        color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.6)
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Turn on WiFi to see available networks"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.4)
                    }

                }

            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

        }

    }

    // Timer for refreshing network status after WiFi toggle
    Timer {
        id: refreshTimer
        interval: 2000
        running: networkTab.visible && refreshTimer.triggered
        property bool triggered: false
        onTriggered: {
            NetworkService.refreshNetworkStatus();
            if (NetworkService.wifiEnabled) {
                WifiService.scanWifi();
            }
            triggered = false;
        }
    }

    // Auto-refresh when WiFi state changes
    Connections {
        target: NetworkService
        function onWifiEnabledChanged() {
            if (NetworkService.wifiEnabled && networkTab.visible) {
                // When WiFi is enabled, scan and update info (only if tab is visible)
                WifiService.scanWifi();
            }
        }
    }

}
