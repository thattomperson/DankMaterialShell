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
    id: networkTab

    // Auto-enable WiFi auto-refresh when network tab is visible
    Component.onCompleted: {
        WifiService.autoRefreshEnabled = true;
        if (NetworkService.wifiEnabled)
            WifiService.scanWifi();
    }

    // Two-column layout for WiFi and Ethernet (WiFi on left, Ethernet on right)
    Row {
        anchors.fill: parent
        spacing: Theme.spacingM

        // WiFi Column (left side)
        Column {
            width: (parent.width - Theme.spacingM) / 2
            height: parent.height
            spacing: Theme.spacingS


            // WiFi Content in Flickable
            Flickable {
                width: parent.width
                height: parent.height - 30
                clip: true
                contentWidth: width
                contentHeight: wifiContent.height
                boundsBehavior: Flickable.DragAndOvershootBounds
                flickDeceleration: 8000
                maximumFlickVelocity: 15000

                Column {
                    id: wifiContent

                    width: parent.width
                    spacing: Theme.spacingM

                    // Current WiFi connection status card
                    Rectangle {
                        id: wifiCard
                        width: parent.width
                        height: 80
                        radius: Theme.cornerRadius
                        color: {
                            if (wifiPreferenceArea.containsMouse && NetworkService.ethernetConnected && NetworkService.wifiEnabled && NetworkService.networkStatus !== "wifi")
                                return Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.8);
                            return Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.5);
                        }
                        border.color: NetworkService.networkStatus === "wifi" ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                        border.width: NetworkService.networkStatus === "wifi" ? 2 : 1
                        visible: NetworkService.wifiAvailable

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: wifiToggle.left
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingS

                            Row {
                                spacing: Theme.spacingM

                                DankIcon {
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
                                    anchors.verticalCenter: parent.verticalCenter
                                }

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
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                text: {
                                    if (!NetworkService.wifiEnabled) {
                                        return "Turn on WiFi to see networks";
                                    } else if (NetworkService.wifiEnabled && WifiService.currentWifiSSID) {
                                        return NetworkService.wifiIP || "Connected";
                                    } else {
                                        return "Select a network below";
                                    }
                                }
                                font.pixelSize: Theme.fontSizeSmall
                                color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                                leftPadding: Theme.iconSize + Theme.spacingM
                                elide: Text.ElideRight
                            }

                        }

                        // WiFi toggle switch
                        DankToggle {
                            id: wifiToggle
                            checked: NetworkService.wifiEnabled
                            enabled: true
                            toggling: NetworkService.wifiToggling
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: {
                                NetworkService.toggleWifiRadio();
                                refreshTimer.triggered = true;
                            }
                        }

                        // MouseArea for network preference (excluding toggle area)
                        MouseArea {
                            id: wifiPreferenceArea
                            anchors.fill: parent
                            anchors.rightMargin: 60 // Exclude toggle area
                            hoverEnabled: true
                            cursorShape: (NetworkService.ethernetConnected && NetworkService.wifiEnabled && NetworkService.networkStatus !== "wifi") ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: NetworkService.ethernetConnected && NetworkService.wifiEnabled && NetworkService.networkStatus !== "wifi" && !NetworkService.changingNetworkPreference
                            onClicked: {
                                if (NetworkService.ethernetConnected && NetworkService.wifiEnabled) {
                                    console.log("WiFi card clicked for preference");
                                    if (NetworkService.networkStatus !== "wifi")
                                        NetworkService.setNetworkPreference("wifi");
                                    else
                                        NetworkService.setNetworkPreference("auto");
                                }
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.shortDuration
                                easing.type: Theme.standardEasing
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
                                font.pixelSize: Theme.fontSizeSmall
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
                                elide: Text.ElideRight
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.shortDuration
                                easing.type: Theme.standardEasing
                            }
                        }
                    }


                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }
        }

        // Ethernet Column (right side)
        Column {
            width: (parent.width - Theme.spacingM) / 2
            height: parent.height
            spacing: Theme.spacingS

            // Ethernet Header removed

            // Ethernet Content in Flickable
            Flickable {
                width: parent.width
                height: parent.height - 30
                clip: true
                contentWidth: width
                contentHeight: ethernetContent.height
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 8000
                maximumFlickVelocity: 15000

                Column {
                    id: ethernetContent

                    width: parent.width
                    spacing: Theme.spacingM

                    // Ethernet connection status card (matching WiFi height)
                    Rectangle {
                        id: ethernetCard
                        width: parent.width
                        height: 80
                        radius: Theme.cornerRadius
                        color: {
                            if (ethernetPreferenceArea.containsMouse && NetworkService.ethernetConnected && NetworkService.wifiEnabled && NetworkService.networkStatus !== "ethernet")
                                return Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.8);
                            return Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.5);
                        }
                        border.color: NetworkService.networkStatus === "ethernet" ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                        border.width: NetworkService.networkStatus === "ethernet" ? 2 : 1

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: ethernetToggle.left
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingS

                            Row {
                                spacing: Theme.spacingM

                                DankIcon {
                                    name: "lan"
                                    size: Theme.iconSize
                                    color: NetworkService.networkStatus === "ethernet" ? Theme.primary : Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "Ethernet"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: NetworkService.networkStatus === "ethernet" ? Theme.primary : Theme.surfaceText
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                text: NetworkService.ethernetConnected ? (NetworkService.ethernetIP || "Connected") : "Disconnected"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                                leftPadding: Theme.iconSize + Theme.spacingM
                                elide: Text.ElideRight
                            }
                        }

                        // Ethernet toggle switch (matching WiFi style)
                        DankToggle {
                            id: ethernetToggle
                            checked: NetworkService.ethernetConnected
                            enabled: true
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: {
                                NetworkService.toggleNetworkConnection("ethernet");
                            }
                        }

                        // MouseArea for network preference (excluding toggle area)
                        MouseArea {
                            id: ethernetPreferenceArea
                            anchors.fill: parent
                            anchors.rightMargin: 60 // Exclude toggle area
                            hoverEnabled: true
                            cursorShape: (NetworkService.ethernetConnected && NetworkService.wifiEnabled && NetworkService.networkStatus !== "ethernet") ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: NetworkService.ethernetConnected && NetworkService.wifiEnabled && NetworkService.networkStatus !== "ethernet" && !NetworkService.changingNetworkPreference
                            onClicked: {
                                if (NetworkService.ethernetConnected && NetworkService.wifiEnabled) {
                                    console.log("Ethernet card clicked for preference");
                                    if (NetworkService.networkStatus !== "ethernet")
                                        NetworkService.setNetworkPreference("ethernet");
                                    else
                                        NetworkService.setNetworkPreference("auto");
                                }
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.shortDuration
                                easing.type: Theme.standardEasing
                            }
                        }
                    }

                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }
        }
    }

    // WiFi disabled message spanning across both columns
    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 100
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "transparent"
        visible: !NetworkService.wifiEnabled

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacingM

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
                font.weight: Font.Medium
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Turn on WiFi to see networks"
                font.pixelSize: Theme.fontSizeMedium
                color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.4)
            }
        }
    }

    // WiFi networks spanning across both columns when Ethernet preference button is hidden
    Column {
        anchors.top: parent.top
        anchors.topMargin: 100
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: NetworkService.wifiEnabled
        spacing: Theme.spacingS
        
        // Available Networks Section with refresh button (spanning version)
        Row {
            width: parent.width
            spacing: Theme.spacingS

            Text {
                text: "Available Networks"
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                width: parent.width - 170
                height: 1
            }

            // WiFi refresh button (spanning version)
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: refreshAreaSpan.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : WifiService.isScanning ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.06) : "transparent"

                DankIcon {
                    id: refreshIconSpan
                    anchors.centerIn: parent
                    name: "refresh"
                    size: Theme.iconSize - 6
                    color: refreshAreaSpan.containsMouse ? Theme.primary : Theme.surfaceText
                    rotation: WifiService.isScanning ? refreshIconSpan.rotation : 0

                    RotationAnimation {
                        target: refreshIconSpan
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
                    id: refreshAreaSpan
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!WifiService.isScanning) {
                            console.log("Manual WiFi scan triggered (spanning)");
                            // Immediate visual feedback
                            refreshIconSpan.rotation += 30;
                            WifiService.scanWifi();
                        }
                    }
                }
            }
        }
        
        // Scrollable networks container
        Flickable {
            width: parent.width
            height: parent.height - 40
            clip: true
            contentWidth: width
            contentHeight: spanningNetworksColumn.height
            boundsBehavior: Flickable.DragAndOvershootBounds
            flickDeceleration: 8000
            maximumFlickVelocity: 15000
            
            Column {
                id: spanningNetworksColumn
                width: parent.width
                spacing: Theme.spacingXS
                
                Repeater {
                    model: NetworkService.wifiAvailable && NetworkService.wifiEnabled ? WifiService.wifiNetworks : []

                    Rectangle {
                        width: parent.width
                        height: 38
                        radius: Theme.cornerRadiusSmall
                        color: networkArea2.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : modelData.connected ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                        border.color: modelData.connected ? Theme.primary : "transparent"
                        border.width: modelData.connected ? 1 : 0

                        Item {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingXS

                            // Signal strength icon
                            DankIcon {
                                id: signalIcon2
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                name: modelData.signalStrength === "excellent" ? "wifi" : modelData.signalStrength === "good" ? "wifi_2_bar" : modelData.signalStrength === "fair" ? "wifi_1_bar" : modelData.signalStrength === "poor" ? "wifi_calling_3" : "wifi"
                                size: Theme.iconSize - 2
                                color: modelData.connected ? Theme.primary : Theme.surfaceText
                            }

                            // Network info
                            Column {
                                anchors.left: signalIcon2.right
                                anchors.leftMargin: Theme.spacingXS
                                anchors.right: rightIcons2.left
                                anchors.rightMargin: Theme.spacingXS
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: modelData.ssid
                                    font.pixelSize: Theme.fontSizeSmall
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
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                                    elide: Text.ElideRight
                                }
                            }

                            // Right side icons
                            Row {
                                id: rightIcons2
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacingXS

                                // Lock icon (if secured)
                                DankIcon {
                                    name: "lock"
                                    size: Theme.iconSize - 8
                                    color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.6)
                                    visible: modelData.secured
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                // Forget button (for saved networks)
                                Rectangle {
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: forgetArea2.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : "transparent"
                                    visible: modelData.saved || modelData.connected

                                    DankIcon {
                                        anchors.centerIn: parent
                                        name: "delete"
                                        size: Theme.iconSize - 8
                                        color: forgetArea2.containsMouse ? Theme.error : Theme.surfaceText
                                    }

                                    MouseArea {
                                        id: forgetArea2
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
                            id: networkArea2
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.connected)
                                    return;

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
            
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }
    }

    // Timer for refreshing network status after WiFi toggle
    Timer {
        id: refreshTimer
        interval: 2000
        running: visible && refreshTimer.triggered
        property bool triggered: false
        onTriggered: {
            NetworkService.refreshNetworkStatus();
            if (NetworkService.wifiEnabled && !WifiService.isScanning) {
                console.log("RefreshTimer: Scanning WiFi after toggle");
                WifiService.scanWifi();
            }
            triggered = false;
        }
    }

    // Auto-refresh when WiFi state changes
    Connections {
        target: NetworkService
        function onWifiEnabledChanged() {
            if (NetworkService.wifiEnabled && visible) {
                // When WiFi is enabled, scan and update info (only if tab is visible)
                // Add a small delay to ensure WiFi service is ready
                wifiScanDelayTimer.start();
            }
        }
    }

    // Delayed WiFi scan timer to ensure service is ready
    Timer {
        id: wifiScanDelayTimer
        interval: 1500
        running: false
        repeat: false
        onTriggered: {
            if (NetworkService.wifiEnabled && visible) {
                console.log("Delayed WiFi scan triggered after enabling WiFi");
                if (!WifiService.isScanning) {
                    WifiService.scanWifi();
                } else {
                    // If still scanning, try again in a bit
                    wifiRetryTimer.start();
                }
            }
        }
    }

    // Retry timer for when WiFi is still scanning
    Timer {
        id: wifiRetryTimer
        interval: 2000
        running: false
        repeat: false
        onTriggered: {
            if (NetworkService.wifiEnabled && visible && WifiService.wifiNetworks.length === 0) {
                console.log("Retry WiFi scan - no networks found yet");
                if (!WifiService.isScanning) {
                    WifiService.scanWifi();
                }
            }
        }
    }
}