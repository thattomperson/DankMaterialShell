import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets

Column {
    id: root
    
    property var wifiContextMenuWindow
    property var sortedWifiNetworks
    property var wifiPasswordModalRef
    
    function getWiFiSignalIcon(signalStrength) {
        switch (signalStrength) {
            case "excellent": return "wifi";
            case "good": return "wifi_2_bar";
            case "fair": return "wifi_1_bar";
            case "poor": return "signal_wifi_0_bar";
            default: return "wifi";
        }
    }
    
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

        StyledText {
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
            color: refreshAreaSpan.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : NetworkService.isScanning ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.06) : "transparent"

            DankIcon {
                id: refreshIconSpan
                anchors.centerIn: parent
                name: "refresh"
                size: Theme.iconSize - 6
                color: refreshAreaSpan.containsMouse ? Theme.primary : Theme.surfaceText
                rotation: NetworkService.isScanning ? refreshIconSpan.rotation : 0

                RotationAnimation {
                    target: refreshIconSpan
                    property: "rotation"
                    running: NetworkService.isScanning
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
                    if (!NetworkService.isScanning) {
                        // Immediate visual feedback
                        refreshIconSpan.rotation += 30;
                        NetworkService.scanWifi();
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
                model: NetworkService.wifiAvailable && NetworkService.wifiEnabled ? sortedWifiNetworks : []

                Rectangle {
                    width: spanningNetworksColumn.width
                    height: 38
                    radius: Theme.cornerRadiusSmall
                    color: networkArea2.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : modelData.connected ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                    border.color: modelData.connected ? Theme.primary : "transparent"
                    border.width: modelData.connected ? 1 : 0

                    Item {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingXS
                        anchors.rightMargin: Theme.spacingM  // Extra right margin for scrollbar

                        // Signal strength icon
                        DankIcon {
                            id: signalIcon2
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            name: getWiFiSignalIcon(modelData.signalStrength)
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

                            StyledText {
                                width: parent.width
                                text: modelData.ssid
                                font.pixelSize: Theme.fontSizeSmall
                                color: modelData.connected ? Theme.primary : Theme.surfaceText
                                font.weight: modelData.connected ? Font.Medium : Font.Normal
                                elide: Text.ElideRight
                            }

                            StyledText {
                                width: parent.width
                                text: {
                                    if (modelData.connected)
                                        return "Connected";
                                    if (NetworkService.connectionStatus === "connecting" && NetworkService.connectingSSID === modelData.ssid)
                                        return "Connecting...";
                                    if (NetworkService.connectionStatus === "invalid_password" && NetworkService.connectingSSID === modelData.ssid)
                                        return "Invalid password";
                                    if (modelData.saved)
                                        return "Saved" + (modelData.secured ? " • Secured" : " • Open");
                                    return modelData.secured ? "Secured" : "Open";
                                }
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: {
                                    if (NetworkService.connectionStatus === "connecting" && NetworkService.connectingSSID === modelData.ssid)
                                        return Theme.primary;
                                    if (NetworkService.connectionStatus === "invalid_password" && NetworkService.connectingSSID === modelData.ssid)
                                        return Theme.error;
                                    return Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7);
                                }
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

                            // Context menu button
                            Rectangle {
                                id: wifiMenuButton
                                width: 24
                                height: 24
                                radius: 12
                                color: wifiMenuButtonArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"

                                DankIcon {
                                    name: "more_vert"
                                    size: Theme.iconSize - 8
                                    color: Theme.surfaceText
                                    opacity: 0.6
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: wifiMenuButtonArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        wifiContextMenuWindow.networkData = modelData;
                                        let buttonCenter = wifiMenuButtonArea.width / 2;
                                        let buttonBottom = wifiMenuButtonArea.height;
                                        let globalPos = wifiMenuButtonArea.mapToItem(wifiContextMenuWindow.parentItem, buttonCenter, buttonBottom);
                                        
                                        Qt.callLater(() => {
                                            wifiContextMenuWindow.show(globalPos.x, globalPos.y);
                                        });
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.shortDuration
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: networkArea2
                        anchors.fill: parent
                        anchors.rightMargin: 32  // Exclude menu button area
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.connected)
                                return;

                            if (modelData.saved) {
                                NetworkService.connectToWifi(modelData.ssid);
                            } else if (modelData.secured) {
                                if (wifiPasswordModalRef) {
                                    wifiPasswordModalRef.wifiPasswordSSID = modelData.ssid;
                                    wifiPasswordModalRef.wifiPasswordInput = "";
                                    wifiPasswordModalRef.wifiPasswordModalVisible = true;
                                }
                            } else {
                                NetworkService.connectToWifi(modelData.ssid);
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