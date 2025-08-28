import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Common
import qs.Modules
import qs.Services
import qs.Widgets

Item {
    id: displayTab

    property var brightnessDebounceTimer

    DankFlickable {
        anchors.fill: parent
        clip: true
        contentHeight: mainColumn.height
        contentWidth: width

        Column {
            id: mainColumn

            width: parent.width
            spacing: Theme.spacingL

            Loader {
                width: parent.width
                sourceComponent: brightnessComponent
            }

            Loader {
                width: parent.width
                sourceComponent: settingsComponent
            }

        }

    }

    Component {
        id: brightnessComponent

        Column {
            width: parent.width
            spacing: Theme.spacingS
            visible: DisplayService.brightnessAvailable

            StyledText {
                text: "Brightness"
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.surfaceText
                font.weight: Font.Medium
            }

            DankDropdown {
                id: deviceDropdown

                width: parent.width
                height: 40
                visible: DisplayService.devices.length > 1
                text: "Device"
                description: {
                    const deviceInfo = DisplayService.getCurrentDeviceInfo();
                    if (deviceInfo && deviceInfo.class === "ddc")
                        return "DDC changes can be slow and unreliable";

                    return "";
                }
                currentValue: DisplayService.currentDevice
                options: DisplayService.devices.map(function(d) {
                    return d.name;
                })
                optionIcons: DisplayService.devices.map(function(d) {
                    if (d.class === "backlight")
                        return "desktop_windows";

                    if (d.class === "ddc")
                        return "tv";

                    if (d.name.includes("kbd"))
                        return "keyboard";

                    return "lightbulb";
                })
                onValueChanged: function(value) {
                    DisplayService.setCurrentDevice(value, true);
                }

                Connections {
                    function onDevicesChanged() {
                        if (DisplayService.currentDevice)
                            deviceDropdown.currentValue = DisplayService.currentDevice;

                        // Check if saved device is now available
                        const lastDevice = SessionData.lastBrightnessDevice || "";
                        if (lastDevice) {
                            const deviceExists = DisplayService.devices.some((d) => {
                                return d.name === lastDevice;
                            });
                            if (deviceExists && (!DisplayService.currentDevice || DisplayService.currentDevice !== lastDevice))
                                DisplayService.setCurrentDevice(lastDevice, false);

                        }
                    }

                    function onDeviceSwitched() {
                        // Force update the description when device switches
                        deviceDropdown.description = Qt.binding(function() {
                            const deviceInfo = DisplayService.getCurrentDeviceInfo();
                            if (deviceInfo && deviceInfo.class === "ddc")
                                return "DDC changes can be slow and unreliable";

                            return "";
                        });
                    }

                    target: DisplayService
                }

            }

            DankSlider {
                id: brightnessSlider

                width: parent.width
                value: DisplayService.brightnessLevel
                leftIcon: "brightness_low"
                rightIcon: "brightness_high"
                enabled: DisplayService.brightnessAvailable && DisplayService.isCurrentDeviceReady()
                opacity: DisplayService.isCurrentDeviceReady() ? 1 : 0.5
                onSliderValueChanged: function(newValue) {
                    brightnessDebounceTimer.pendingValue = newValue;
                    brightnessDebounceTimer.restart();
                }
                onSliderDragFinished: function(finalValue) {
                    brightnessDebounceTimer.stop();
                    DisplayService.setBrightnessInternal(finalValue, DisplayService.currentDevice);
                }

                Connections {
                    function onBrightnessChanged() {
                        brightnessSlider.value = DisplayService.brightnessLevel;
                    }

                    function onDeviceSwitched() {
                        brightnessSlider.value = DisplayService.brightnessLevel;
                    }

                    target: DisplayService
                }

            }

        }

    }

    Component {
        id: settingsComponent

        Column {
            width: parent.width
            spacing: Theme.spacingM

            StyledText {
                text: "Display Settings"
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.surfaceText
                font.weight: Font.Medium
            }

            Row {
                width: parent.width
                spacing: Theme.spacingM

                Rectangle {
                    width: (parent.width - Theme.spacingM) / 2
                    height: 80
                    radius: Theme.cornerRadius
                    color: DisplayService.nightModeActive ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : (nightModeToggle.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08))
                    border.color: DisplayService.nightModeActive ? Theme.primary : "transparent"
                    border.width: DisplayService.nightModeActive ? 1 : 0
                    opacity: SessionData.nightModeAutoEnabled ? 0.6 : 1

                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.spacingS

                        DankIcon {
                            name: DisplayService.nightModeActive ? "nightlight" : "dark_mode"
                            size: Theme.iconSizeLarge
                            color: DisplayService.nightModeActive ? Theme.primary : Theme.surfaceText
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        StyledText {
                            text: SessionData.nightModeAutoEnabled ? "Night Mode (Auto)" : "Night Mode"
                            font.pixelSize: Theme.fontSizeMedium
                            color: DisplayService.nightModeActive ? Theme.primary : Theme.surfaceText
                            font.weight: Font.Medium
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                    }

                    DankIcon {
                        name: "schedule"
                        size: 16
                        color: Theme.primary
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: Theme.spacingS
                        visible: SessionData.nightModeAutoEnabled
                    }

                    MouseArea {
                        id: nightModeToggle

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            DisplayService.toggleNightMode();
                        }
                    }

                }

                Rectangle {
                    width: (parent.width - Theme.spacingM) / 2
                    height: 80
                    radius: Theme.cornerRadius
                    color: SessionData.isLightMode ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : (lightModeToggle.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08))
                    border.color: SessionData.isLightMode ? Theme.primary : "transparent"
                    border.width: SessionData.isLightMode ? 1 : 0

                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.spacingS

                        DankIcon {
                            name: SessionData.isLightMode ? "light_mode" : "palette"
                            size: Theme.iconSizeLarge
                            color: SessionData.isLightMode ? Theme.primary : Theme.surfaceText
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        StyledText {
                            text: SessionData.isLightMode ? "Light Mode" : "Dark Mode"
                            font.pixelSize: Theme.fontSizeMedium
                            color: SessionData.isLightMode ? Theme.primary : Theme.surfaceText
                            font.weight: Font.Medium
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                    }

                    MouseArea {
                        id: lightModeToggle

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Theme.toggleLightMode();
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

        }

    }

    brightnessDebounceTimer: Timer {
        property int pendingValue: 0

        interval: {
            // Use longer interval for DDC devices since ddcutil is slow
            const deviceInfo = DisplayService.getCurrentDeviceInfo();
            return (deviceInfo && deviceInfo.class === "ddc") ? 100 : 50;
        }
        repeat: false
        onTriggered: {
            DisplayService.setBrightnessInternal(pendingValue, DisplayService.currentDevice);
        }
    }

}
