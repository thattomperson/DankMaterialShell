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

            // WiFi Header
            Text {
                text: "Wi-Fi"
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.surfaceText
                font.weight: Font.Medium
                width: parent.width
            }

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
                        width: parent.width
                        height: 80
                        radius: Theme.cornerRadius
                        color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.5)
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

                            // Force WiFi preference button
                            Rectangle {
                                width: 120
                                height: 26
                                color: NetworkService.networkStatus === "wifi" ? Theme.primary : Theme.surface
                                border.color: Theme.primary
                                border.width: 1
                                radius: 6
                                opacity: NetworkService.changingNetworkPreference ? 0.6 : 1
                                visible: NetworkService.networkStatus === "ethernet" && NetworkService.wifiEnabled

                                Row {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingXS

                                    DankIcon {
                                        id: wifiPreferenceIcon

                                        name: NetworkService.changingNetworkPreference ? "sync" : ""
                                        size: Theme.fontSizeSmall - 2
                                        color: NetworkService.networkStatus === "wifi" ? Theme.background : Theme.primary
                                        visible: NetworkService.changingNetworkPreference || false
                                        anchors.verticalCenter: parent.verticalCenter
                                        rotation: NetworkService.changingNetworkPreference ? wifiPreferenceIcon.rotation : 0

                                        RotationAnimation {
                                            target: wifiPreferenceIcon
                                            property: "rotation"
                                            running: NetworkService.changingNetworkPreference || false
                                            from: 0
                                            to: 360
                                            duration: 1000
                                            loops: Animation.Infinite
                                        }
                                    }

                                    Text {
                                        text: NetworkService.changingNetworkPreference ? "Switching..." : "Prefer over Ethernet"
                                        font.pixelSize: Theme.fontSizeSmall - 1
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
                                    enabled: !NetworkService.changingNetworkPreference
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

                    // Available Networks Section with refresh button
                    Row {
                        width: parent.width
                        spacing: Theme.spacingS
                        visible: NetworkService.wifiEnabled && (NetworkService.ethernetConnected && NetworkService.networkStatus !== "ethernet")

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

                        // WiFi refresh button
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: refreshArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : WifiService.isScanning ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.06) : "transparent"

                            DankIcon {
                                id: refreshIcon
                                anchors.centerIn: parent
                                name: "refresh"
                                size: Theme.iconSize - 6
                                color: refreshArea.containsMouse ? Theme.primary : Theme.surfaceText
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
                                onClicked: {
                                    if (!WifiService.isScanning) {
                                        console.log("Manual WiFi scan triggered");
                                        // Immediate visual feedback
                                        refreshIcon.rotation += 30;
                                        WifiService.scanWifi();
                                    }
                                }
                            }
                        }
                    }

                    // WiFi networks list (only show if WiFi is available and enabled and spanning is not needed)
                    Repeater {
                        model: (NetworkService.wifiAvailable && NetworkService.wifiEnabled && NetworkService.ethernetConnected && NetworkService.networkStatus !== "ethernet") ? WifiService.wifiNetworks : []

                        Rectangle {
                            width: parent.width
                            height: 38
                            radius: Theme.cornerRadiusSmall
                            color: networkArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : modelData.connected ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                            border.color: modelData.connected ? Theme.primary : "transparent"
                            border.width: modelData.connected ? 1 : 0

                            Item {
                                anchors.fill: parent
                                anchors.margins: Theme.spacingXS

                                // Signal strength icon
                                DankIcon {
                                    id: signalIcon

                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: modelData.signalStrength === "excellent" ? "wifi" : modelData.signalStrength === "good" ? "wifi_2_bar" : modelData.signalStrength === "fair" ? "wifi_1_bar" : modelData.signalStrength === "poor" ? "wifi_calling_3" : "wifi"
                                    size: Theme.iconSize - 2
                                    color: modelData.connected ? Theme.primary : Theme.surfaceText
                                }

                                // Network info
                                Column {
                                    anchors.left: signalIcon.right
                                    anchors.leftMargin: Theme.spacingXS
                                    anchors.right: rightIcons.left
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
                                    id: rightIcons

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
                                        color: forgetArea.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : "transparent"
                                        visible: modelData.saved || modelData.connected

                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: "delete"
                                            size: Theme.iconSize - 8
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
                                id: networkArea

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

                    // WiFi disabled message
                    Column {
                        width: parent.width
                        spacing: Theme.spacingM
                        visible: !NetworkService.wifiEnabled
                        anchors.horizontalCenter: parent.horizontalCenter

                        DankIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: "wifi_off"
                            size: 36
                            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.3)
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "WiFi is turned off"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.6)
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Turn on WiFi to see networks"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.4)
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

            // Ethernet Header
            Text {
                text: "Ethernet"
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.surfaceText
                font.weight: Font.Medium
                width: parent.width
            }

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
                        width: parent.width
                        height: 80
                        radius: Theme.cornerRadius
                        color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.5)
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
                    }

                    // Ethernet preference button (moved below the status card)
                    Rectangle {
                        width: parent.width
                        height: 30
                        color: NetworkService.networkStatus === "ethernet" ? Theme.primary : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.5)
                        border.color: Theme.primary
                        border.width: 1
                        radius: 6
                        opacity: NetworkService.changingNetworkPreference ? 0.6 : 1
                        visible: NetworkService.ethernetConnected && NetworkService.networkStatus !== "ethernet" && NetworkService.wifiAvailable && NetworkService.wifiEnabled

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            DankIcon {
                                id: ethernetPreferenceIcon

                                name: NetworkService.changingNetworkPreference ? "sync" : ""
                                size: Theme.fontSizeSmall - 2
                                color: NetworkService.networkStatus === "ethernet" ? Theme.background : Theme.primary
                                visible: NetworkService.changingNetworkPreference || false
                                anchors.verticalCenter: parent.verticalCenter
                                rotation: NetworkService.changingNetworkPreference ? ethernetPreferenceIcon.rotation : 0

                                RotationAnimation {
                                    target: ethernetPreferenceIcon
                                    property: "rotation"
                                    running: NetworkService.changingNetworkPreference || false
                                    from: 0
                                    to: 360
                                    duration: 1000
                                    loops: Animation.Infinite
                                }
                            }

                            Text {
                                text: NetworkService.changingNetworkPreference ? "Switching..." : "Prefer over WiFi"
                                font.pixelSize: Theme.fontSizeMedium
                                color: NetworkService.networkStatus === "ethernet" ? Theme.background : Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                                font.weight: Font.Medium
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            propagateComposedEvents: false
                            enabled: !NetworkService.changingNetworkPreference
                            onClicked: {
                                console.log("*** ETHERNET PREFERENCE BUTTON CLICKED ***");
                                if (NetworkService.networkStatus !== "ethernet") {
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

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }
        }
    }

    // WiFi networks spanning across both columns when Ethernet preference button is hidden
    Column {
        anchors.top: parent.top
        anchors.topMargin: 120
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: NetworkService.wifiEnabled && !(NetworkService.ethernetConnected && NetworkService.networkStatus !== "ethernet")
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
            if (NetworkService.wifiEnabled && visible) {
                // When WiFi is enabled, scan and update info (only if tab is visible)
                WifiService.scanWifi();
            }
        }
    }
}