import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.ControlCenter

PanelWindow {
    id: root

    property bool controlCenterVisible: false
    property string currentTab: "network" // "network", "audio", "bluetooth", "display"
    property bool powerOptionsExpanded: false

    signal powerActionRequested(string action, string title, string message)
    signal lockRequested()

    visible: controlCenterVisible
    onVisibleChanged: {
        // Enable/disable WiFi auto-refresh based on control center visibility
        NetworkService.autoRefreshEnabled = visible && NetworkService.wifiEnabled;
        // Stop bluetooth scanning when control center is closed
        if (!visible && BluetoothService.adapter && BluetoothService.adapter.discovering)
            BluetoothService.adapter.discovering = false;

        // Refresh uptime when opened
        if (visible && UserInfoService)
            UserInfoService.getUptime();

    }
    implicitWidth: 600
    implicitHeight: 500
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Loader {
        id: contentLoader
        asynchronous: true
        active: controlCenterVisible
        
        readonly property real targetWidth: Math.min(600, Screen.width - Theme.spacingL * 2)
        width: targetWidth
        height: root.powerOptionsExpanded ? 570 : 500
        y: Theme.barHeight + Theme.spacingXS
        x: Math.max(Theme.spacingL, Screen.width - targetWidth - Theme.spacingL)
        
        // GPU-accelerated scale + opacity animation
        opacity: controlCenterVisible ? 1 : 0
        scale: controlCenterVisible ? 1 : 0.9
        
        Behavior on opacity {
            NumberAnimation {
                duration: Anims.durMed
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anims.emphasized
            }
        }
        
        Behavior on scale {
            NumberAnimation {
                duration: Anims.durMed
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anims.emphasized
            }
        }
        
        sourceComponent: Rectangle {
            color: Theme.popupBackground()
            radius: Theme.cornerRadiusLarge
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
            border.width: 1
            
            // Remove layer rendering for better performance
            antialiasing: true
            smooth: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            // Elegant User Header
            Column {
                width: parent.width
                spacing: Theme.spacingL

                Rectangle {
                    width: parent.width
                    height: 90
                    radius: Theme.cornerRadiusLarge
                    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, Theme.getContentBackgroundAlpha() * 0.4)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
                    border.width: 1

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Theme.spacingL
                        anchors.rightMargin: Theme.spacingL
                        spacing: Theme.spacingL

                        // Profile Picture Container
                        Item {
                            id: avatarContainer

                            property bool hasImage: profileImageLoader.status === Image.Ready

                            width: 64
                            height: 64

                            // This rectangle provides the themed ring via its border.
                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: "transparent"
                                border.color: Theme.primary
                                border.width: 1 // The ring is 1px thick.
                                visible: parent.hasImage
                            }

                            // Hidden Image loader. Its only purpose is to load the texture.
                            Image {
                                id: profileImageLoader

                                source: {
                                    if (Prefs.profileImage === "")
                                        return "";

                                    if (Prefs.profileImage.startsWith("/"))
                                        return "file://" + Prefs.profileImage;

                                    return Prefs.profileImage;
                                }
                                smooth: true
                                asynchronous: true
                                mipmap: true
                                cache: true
                                visible: false // This item is never shown directly.
                            }

                            MultiEffect {
                                anchors.fill: parent
                                anchors.margins: 5
                                source: profileImageLoader
                                maskEnabled: true
                                maskSource: circularMask
                                visible: avatarContainer.hasImage
                                maskThresholdMin: 0.5
                                maskSpreadAtMin: 1
                            }

                            Item {
                                id: circularMask

                                width: 64 - 10
                                height: 64 - 10
                                layer.enabled: true
                                layer.smooth: true
                                visible: false

                                Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: "black"
                                    antialiasing: true
                                }

                            }

                            // Fallback for when there is no image.
                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: Theme.primary
                                visible: !parent.hasImage

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: "person"
                                    size: Theme.iconSize + 8
                                    color: Theme.primaryText
                                }

                            }

                            // Error icon for when the image fails to load.
                            DankIcon {
                                anchors.centerIn: parent
                                name: "warning"
                                size: Theme.iconSize + 8
                                color: Theme.primaryText
                                visible: Prefs.profileImage !== "" && profileImageLoader.status === Image.Error
                            }

                        }

                        // User Info Text
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingXS

                            StyledText {
                                text: UserInfoService.fullName || UserInfoService.username || "User"
                                font.pixelSize: Theme.fontSizeLarge
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                            }

                            StyledText {
                                text: "Uptime: " + (UserInfoService.uptime || "Unknown")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                font.weight: Font.Normal
                            }

                        }

                    }

                    // Action Buttons - Lock, Power and Settings
                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: Theme.spacingL
                        spacing: Theme.spacingS

                        // Lock Button
                        DankActionButton {
                            buttonSize: 40
                            iconName: "lock"
                            iconSize: Theme.iconSize - 2
                            iconColor: Theme.surfaceText
                            backgroundColor: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.5)
                            hoverColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                            onClicked: {
                                controlCenterVisible = false;
                                root.lockRequested();
                            }
                        }

                        // Power Button
                        Rectangle {
                            width: 40
                            height: 40
                            radius: 20
                            color: powerButton.containsMouse || root.powerOptionsExpanded ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.5)

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width
                                height: parent.height
                                radius: parent.radius
                                color: "transparent"
                                clip: true

                                DankIcon {
                                    id: dankIcon

                                    anchors.centerIn: parent
                                    name: root.powerOptionsExpanded ? "expand_less" : "power_settings_new"
                                    size: Theme.iconSize - 2
                                    color: powerButton.containsMouse || root.powerOptionsExpanded ? Theme.error : Theme.surfaceText

                                    Behavior on name {
                                        // Smooth icon transition
                                        SequentialAnimation {
                                            NumberAnimation {
                                                target: dankIcon
                                                property: "opacity"
                                                to: 0
                                                duration: Theme.shortDuration / 2
                                                easing.type: Theme.standardEasing
                                            }

                                            PropertyAction {
                                                target: dankIcon
                                                property: "name"
                                            }

                                            NumberAnimation {
                                                target: dankIcon
                                                property: "opacity"
                                                to: 1
                                                duration: Theme.shortDuration / 2
                                                easing.type: Theme.standardEasing
                                            }

                                        }

                                    }

                                }

                            }

                            MouseArea {
                                id: powerButton

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.powerOptionsExpanded = !root.powerOptionsExpanded;
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.shortDuration
                                    easing.type: Theme.standardEasing
                                }

                            }

                        }

                        // Settings Button
                        DankActionButton {
                            buttonSize: 40
                            iconName: "settings"
                            iconSize: Theme.iconSize - 2
                            iconColor: Theme.surfaceText
                            backgroundColor: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.5)
                            hoverColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                            onClicked: {
                                controlCenterVisible = false;
                                settingsModal.settingsVisible = true;
                            }
                        }

                    }

                }

                // Animated Collapsible Power Options (optimized)
                Rectangle {
                    width: parent.width
                    height: root.powerOptionsExpanded ? 60 : 0
                    radius: Theme.cornerRadius
                    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, Theme.getContentBackgroundAlpha() * 0.4)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
                    border.width: root.powerOptionsExpanded ? 1 : 0
                    opacity: root.powerOptionsExpanded ? 1 : 0
                    clip: true

                    Row {
                        anchors.centerIn: parent
                        spacing: Theme.spacingL
                        visible: root.powerOptionsExpanded

                        // Logout
                        Rectangle {
                            width: 100
                            height: 34
                            radius: Theme.cornerRadius
                            color: logoutButton.containsMouse ? Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.5)

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingXS

                                DankIcon {
                                    name: "logout"
                                    size: Theme.fontSizeSmall
                                    color: logoutButton.containsMouse ? Theme.warning : Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: "Logout"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: logoutButton.containsMouse ? Theme.warning : Theme.surfaceText
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                            }

                            MouseArea {
                                id: logoutButton

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.powerOptionsExpanded = false;
                                    root.powerActionRequested("logout", "Logout", "Are you sure you want to logout?");
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.shortDuration
                                    easing.type: Theme.standardEasing
                                }

                            }

                        }

                        // Reboot
                        Rectangle {
                            width: 100
                            height: 34
                            radius: Theme.cornerRadius
                            color: rebootButton.containsMouse ? Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.5)

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingXS

                                DankIcon {
                                    name: "restart_alt"
                                    size: Theme.fontSizeSmall
                                    color: rebootButton.containsMouse ? Theme.warning : Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: "Restart"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: rebootButton.containsMouse ? Theme.warning : Theme.surfaceText
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                            }

                            MouseArea {
                                id: rebootButton

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.powerOptionsExpanded = false;
                                    root.powerActionRequested("reboot", "Restart", "Are you sure you want to restart?");
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.shortDuration
                                    easing.type: Theme.standardEasing
                                }

                            }

                        }

                        // Suspend
                        Rectangle {
                            width: 100
                            height: 34
                            radius: Theme.cornerRadius
                            color: suspendButton.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.5)

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingXS

                                DankIcon {
                                    name: "bedtime"
                                    size: Theme.fontSizeSmall
                                    color: suspendButton.containsMouse ? Theme.primary : Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: "Suspend"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: suspendButton.containsMouse ? Theme.primary : Theme.surfaceText
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                            }

                            MouseArea {
                                id: suspendButton

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.powerOptionsExpanded = false;
                                    root.powerActionRequested("suspend", "Suspend", "Are you sure you want to suspend?");
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.shortDuration
                                    easing.type: Theme.standardEasing
                                }

                            }

                        }

                        // Shutdown
                        Rectangle {
                            width: 100
                            height: 34
                            radius: Theme.cornerRadius
                            color: shutdownButton.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.5)

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingXS

                                DankIcon {
                                    name: "power_settings_new"
                                    size: Theme.fontSizeSmall
                                    color: shutdownButton.containsMouse ? Theme.error : Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: "Shutdown"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: shutdownButton.containsMouse ? Theme.error : Theme.surfaceText
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                            }

                            MouseArea {
                                id: shutdownButton

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.powerOptionsExpanded = false;
                                    root.powerActionRequested("poweroff", "Shutdown", "Are you sure you want to shutdown?");
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

                    // Single coordinated animation for power options
                    Behavior on height {
                        NumberAnimation {
                            duration: Theme.shortDuration
                            easing.type: Theme.standardEasing
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.shortDuration
                            easing.type: Theme.standardEasing
                        }

                    }

                }

                Rectangle {
                    width: parent.width
                    height: tabBar.height + Theme.spacingM * 2
                    radius: Theme.cornerRadiusLarge
                    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.15)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.06)
                    border.width: 1

                    DankTabBar {
                        id: tabBar
                        anchors.centerIn: parent
                        width: parent.width - Theme.spacingM * 2
                        tabHeight: 40
                        currentIndex: {
                            let tabs = ["network", "audio"];
                            if (BluetoothService.available)
                                tabs.push("bluetooth");

                            tabs.push("display");
                            return tabs.indexOf(root.currentTab);
                        }
                        model: {
                            let tabs = [{
                                "text": "Network",
                                "icon": "wifi",
                                "id": "network"
                            }];
                            tabs.push({
                                "text": "Audio",
                                "icon": "volume_up",
                                "id": "audio"
                            });
                            if (BluetoothService.available)
                                tabs.push({
                                "text": "Bluetooth",
                                "icon": "bluetooth",
                                "id": "bluetooth"
                            });

                            tabs.push({
                                "text": "Display",
                                "icon": "brightness_6",
                                "id": "display"
                            });
                            return tabs;
                        }
                        onTabClicked: function(index) {
                            let tabs = ["network", "audio"];
                            if (BluetoothService.available)
                                tabs.push("bluetooth");

                            tabs.push("display");
                            root.currentTab = tabs[index];
                        }
                    }
                }

            }

            Rectangle {
                width: parent.width
                Layout.fillHeight: true
                radius: Theme.cornerRadiusLarge
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.1)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.05)
                border.width: 1

                NetworkTab {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    visible: root.currentTab === "network"
                }

                AudioTab {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    visible: root.currentTab === "audio"
                }

                BluetoothTab {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    visible: BluetoothService.available && root.currentTab === "bluetooth"
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    visible: root.currentTab === "display"
                    spacing: Theme.spacingL
                    
                    property var brightnessDebounceTimer: Timer {
                        interval: BrightnessService.ddcAvailable ? 500 : 50
                        repeat: false
                        property int pendingValue: 0
                        onTriggered: {
                            BrightnessService.setBrightness(pendingValue);
                        }
                    }
                    
                    // Brightness Control
                    Column {
                        width: parent.width
                        spacing: Theme.spacingS
                        visible: BrightnessService.brightnessAvailable
                        
                        StyledText {
                            text: "Brightness"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }
                        
                        DankSlider {
                            width: parent.width
                            height: 24
                            value: BrightnessService.brightnessLevel
                            leftIcon: "brightness_low"
                            rightIcon: "brightness_high"
                            enabled: BrightnessService.brightnessAvailable
                            showValue: true
                            onSliderValueChanged: function(newValue) {
                                parent.parent.brightnessDebounceTimer.pendingValue = newValue;
                                parent.parent.brightnessDebounceTimer.restart();
                            }
                            onSliderDragFinished: function(finalValue) {
                                parent.parent.brightnessDebounceTimer.stop();
                                BrightnessService.setBrightness(finalValue);
                            }
                        }
                        
                        StyledText {
                            text: "ddc changes can be slow to respond"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            visible: BrightnessService.ddcAvailable && !BrightnessService.laptopBacklightAvailable
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                    
                    DankToggle {
                        width: parent.width
                        text: "Night Mode"
                        description: "Apply warm color temperature to reduce eye strain"
                        checked: Prefs.nightModeEnabled
                        onToggled: (checked) => {
                            Prefs.setNightModeEnabled(checked);
                        }
                    }
                    
                    DankToggle {
                        width: parent.width
                        text: "Light Mode"
                        description: "Use light theme instead of dark theme"
                        checked: Prefs.isLightMode
                        onToggled: (checked) => {
                            Prefs.setLightMode(checked);
                            Theme.isLightMode = checked;
                        }
                    }
                }

                Behavior on height {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }

                }

            }

        }

            // Power menu height animation
            Behavior on height {
                NumberAnimation {
                    duration: Theme.shortDuration // Faster for height changes
                    easing.type: Theme.standardEasing
                }
            }
        }
    }

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: function(mouse) {
            // Only close if click is outside the content loader
            var localPos = mapToItem(contentLoader, mouse.x, mouse.y);
            if (localPos.x < 0 || localPos.x > contentLoader.width || 
                localPos.y < 0 || localPos.y > contentLoader.height) {
                controlCenterVisible = false;
            }
        }
    }

}
