import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modals

Rectangle {
    implicitHeight: NetworkService.wifiEnabled ? headerRow.height + wifiContent.height + Theme.spacingM : headerRow.height
    radius: Theme.cornerRadius
    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, Theme.getContentBackgroundAlpha() * 0.6)
    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
    border.width: 1
    
    Component.onCompleted: {
        NetworkService.addRef()
        if (NetworkService.wifiEnabled) {
            NetworkService.scanWifi()
        }
    }
    
    Component.onDestruction: {
        NetworkService.removeRef()
    }
    
    property var wifiPasswordModalRef: {
        wifiPasswordModalLoader.active = true
        return wifiPasswordModalLoader.item
    }
    property var networkInfoModalRef: {
        networkInfoModalLoader.active = true
        return networkInfoModalLoader.item
    }
    
    Row {
        id: headerRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingM
        anchors.topMargin: Theme.spacingS
        height: 40
        
        StyledText {
            id: headerText
            text: "Network Settings"
            font.pixelSize: Theme.fontSizeLarge
            color: Theme.surfaceText
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Item {
            width: Math.max(0, parent.width - headerText.implicitWidth - preferenceControls.width - Theme.spacingM)
            height: parent.height
        }
        
        Row {
            id: preferenceControls
            spacing: Theme.spacingS
            anchors.verticalCenter: parent.verticalCenter
            visible: NetworkService.ethernetConnected && NetworkService.wifiConnected
            
            Rectangle {
                property bool isActive: NetworkService.userPreference === "ethernet"
                
                width: 90
                height: 36
                radius: 18
                color: isActive ? Theme.surfaceContainerHigh : ethernetMouseArea.containsMouse ? Theme.surfaceHover : "transparent"
                
                StyledText {
                    anchors.centerIn: parent
                    text: "Ethernet"
                    color: parent.isActive ? Theme.primary : Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: parent.isActive ? Font.Medium : Font.Normal
                }
                
                MouseArea {
                    id: ethernetMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: NetworkService.setNetworkPreference("ethernet")
                    cursorShape: Qt.PointingHandCursor
                }
                
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }
                }
            }
            
            Rectangle {
                property bool isActive: NetworkService.userPreference === "wifi"
                
                width: 70
                height: 36
                radius: 18
                color: isActive ? Theme.surfaceContainerHigh : wifiMouseArea.containsMouse ? Theme.surfaceHover : "transparent"
                
                StyledText {
                    anchors.centerIn: parent
                    text: "WiFi"
                    color: parent.isActive ? Theme.primary : Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: parent.isActive ? Font.Medium : Font.Normal
                }
                
                MouseArea {
                    id: wifiMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: NetworkService.setNetworkPreference("wifi")
                    cursorShape: Qt.PointingHandCursor
                }
                
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }
                }
            }
        }
    }
    
    DankFlickable {
        id: wifiContent
        anchors.top: headerRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacingM
        anchors.topMargin: Theme.spacingM
        visible: NetworkService.wifiInterface
        contentHeight: wifiColumn.height
        clip: true
        
        Column {
            id: wifiColumn
            width: parent.width
            spacing: Theme.spacingS
            
            Item {
                width: parent.width
                height: 200
                visible: NetworkService.wifiInterface && NetworkService.wifiNetworks?.length < 1
                
                DankIcon {
                    anchors.centerIn: parent
                    name: "refresh"
                    size: 48
                    color: Qt.rgba(Theme.surfaceText.r || 0.8, Theme.surfaceText.g || 0.8, Theme.surfaceText.b || 0.8, 0.3)
                    
                    RotationAnimation on rotation {
                        running: true
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 1000
                    }
                }
            }
            
            Repeater {
                model: {
                    let networks = [...NetworkService.wifiNetworks]
                    networks.sort((a, b) => {
                        if (a.ssid === NetworkService.currentWifiSSID) return -1
                        if (b.ssid === NetworkService.currentWifiSSID) return 1
                        return b.signal - a.signal
                    })
                    return networks
                }
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    
                    width: parent.width
                    height: 50
                    radius: Theme.cornerRadius
                    color: networkMouseArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, index % 2 === 0 ? 0.3 : 0.2)
                    border.color: modelData.ssid === NetworkService.currentWifiSSID ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                    border.width: modelData.ssid === NetworkService.currentWifiSSID ? 2 : 1
                    
                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Theme.spacingM
                        spacing: Theme.spacingS
                        
                        DankIcon {
                            name: {
                                let strength = modelData.signal || 0
                                if (strength >= 70) return "signal_wifi_4_bar"
                                if (strength >= 50) return "network_wifi_3_bar"
                                if (strength >= 25) return "network_wifi_2_bar"
                                if (strength >= 10) return "network_wifi_1_bar"
                                return "signal_wifi_bad"
                            }
                            size: Theme.iconSize - 4
                            color: modelData.ssid === NetworkService.currentWifiSSID ? Theme.primary : Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 200
                            
                            StyledText {
                                text: modelData.ssid || "Unknown Network"
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                font.weight: modelData.ssid === NetworkService.currentWifiSSID ? Font.Medium : Font.Normal
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            
                            Row {
                                spacing: Theme.spacingXS
                                
                                StyledText {
                                    text: modelData.ssid === NetworkService.currentWifiSSID ? "Connected" : (modelData.secured ? "Secured" : "Open")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                }
                                
                                StyledText {
                                    text: modelData.saved ? "• Saved" : ""
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.primary
                                    visible: text.length > 0
                                }
                                
                                StyledText {
                                    text: "• " + modelData.signal + "%"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                }
                            }
                        }
                    }
                    
                    DankActionButton {
                        id: optionsButton
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        iconName: "more_horiz"
                        buttonSize: 28
                        onClicked: {
                            if (networkContextMenu.visible) {
                                networkContextMenu.close()
                            } else {
                                networkContextMenu.currentSSID = modelData.ssid
                                networkContextMenu.currentSecured = modelData.secured
                                networkContextMenu.currentConnected = modelData.ssid === NetworkService.currentWifiSSID
                                networkContextMenu.currentSaved = modelData.saved
                                networkContextMenu.currentSignal = modelData.signal
                                networkContextMenu.popup(optionsButton, -networkContextMenu.width + optionsButton.width, optionsButton.height + Theme.spacingXS)
                            }
                        }
                    }
                    
                    MouseArea {
                        id: networkMouseArea
                        anchors.fill: parent
                        anchors.rightMargin: optionsButton.width + Theme.spacingS
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(event) {
                            if (modelData.ssid !== NetworkService.currentWifiSSID) {
                                if (modelData.secured && !modelData.saved) {
                                    if (wifiPasswordModalRef) {
                                        wifiPasswordModalRef.show(modelData.ssid)
                                    }
                                } else {
                                    NetworkService.connectToWifi(modelData.ssid)
                                }
                            }
                            event.accepted = true
                        }
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: Theme.shortDuration }
                    }
                    
                    Behavior on border.color {
                        ColorAnimation { duration: Theme.shortDuration }
                    }
                }
            }
        }
    }
    
    Menu {
        id: networkContextMenu
        width: 150
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        
        property string currentSSID: ""
        property bool currentSecured: false
        property bool currentConnected: false
        property bool currentSaved: false
        property int currentSignal: 0
        
        background: Rectangle {
            color: Theme.popupBackground()
            radius: Theme.cornerRadius
            border.width: 1
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
        }
        
        MenuItem {
            text: networkContextMenu.currentConnected ? "Disconnect" : "Connect"
            height: 32
            
            contentItem: StyledText {
                text: parent.text
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                leftPadding: Theme.spacingS
                verticalAlignment: Text.AlignVCenter
            }
            
            background: Rectangle {
                color: parent.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : "transparent"
                radius: Theme.cornerRadius / 2
            }
            
            onTriggered: {
                if (networkContextMenu.currentConnected) {
                    NetworkService.disconnectWifi()
                } else {
                    if (networkContextMenu.currentSecured && !networkContextMenu.currentSaved) {
                        if (wifiPasswordModalRef) {
                            wifiPasswordModalRef.show(networkContextMenu.currentSSID)
                        }
                    } else {
                        NetworkService.connectToWifi(networkContextMenu.currentSSID)
                    }
                }
            }
        }
        
        MenuItem {
            text: "Network Info"
            height: 32
            
            contentItem: StyledText {
                text: parent.text
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                leftPadding: Theme.spacingS
                verticalAlignment: Text.AlignVCenter
            }
            
            background: Rectangle {
                color: parent.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : "transparent"
                radius: Theme.cornerRadius / 2
            }
            
            onTriggered: {
                if (networkInfoModalRef) {
                    let networkData = NetworkService.getNetworkInfo(networkContextMenu.currentSSID)
                    networkInfoModalRef.showNetworkInfo(networkContextMenu.currentSSID, networkData)
                }
            }
        }
        
        MenuItem {
            text: "Forget Network"
            height: networkContextMenu.currentSaved || networkContextMenu.currentConnected ? 32 : 0
            visible: networkContextMenu.currentSaved || networkContextMenu.currentConnected
            
            contentItem: StyledText {
                text: parent.text
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.error
                leftPadding: Theme.spacingS
                verticalAlignment: Text.AlignVCenter
            }
            
            background: Rectangle {
                color: parent.hovered ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.08) : "transparent"
                radius: Theme.cornerRadius / 2
            }
            
            onTriggered: {
                NetworkService.forgetWifiNetwork(networkContextMenu.currentSSID)
            }
        }
    }
    
    LazyLoader {
        id: wifiPasswordModalLoader
        active: false
        
        WifiPasswordModal {
            id: wifiPasswordModal
        }
    }
    
    LazyLoader {
        id: networkInfoModalLoader
        active: false
        
        NetworkInfoModal {
            id: networkInfoModal
        }
    }


}