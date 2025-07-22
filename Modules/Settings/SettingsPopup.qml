import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Widgets
import qs.Modules.Settings

PanelWindow {
    id: settingsPopup

    property bool settingsVisible: false

    signal closingPopup()

    onSettingsVisibleChanged: {
        if (!settingsVisible) {
            closingPopup();
            // Hide any open dropdown when settings close
            if (typeof globalDropdownWindow !== 'undefined') {
                globalDropdownWindow.hide();
            }
        }
    }
    visible: settingsVisible
    implicitWidth: 600
    implicitHeight: 700
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // Darkened background
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.5

        MouseArea {
            anchors.fill: parent
            onClicked: settingsPopup.settingsVisible = false
        }

    }

    // Main settings panel - spotlight-like centered appearance
    Rectangle {
        id: mainPanel

        width: Math.min(600, parent.width - Theme.spacingXL * 2)
        height: Math.min(700, parent.height - Theme.spacingXL * 2)
        anchors.centerIn: parent
        color: Theme.popupBackground()
        radius: Theme.cornerRadiusLarge
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
        border.width: 1
        // Simple opacity and scale control tied directly to settingsVisible
        opacity: settingsPopup.settingsVisible ? 1 : 0
        scale: settingsPopup.settingsVisible ? 1 : 0.95
        // Add shadow effect
        layer.enabled: true

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingL

            // Header
            Row {
                width: parent.width
                spacing: Theme.spacingM

                DankIcon {
                    name: "settings"
                    size: Theme.iconSize
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Settings"
                    font.pixelSize: Theme.fontSizeXLarge
                    color: Theme.surfaceText
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    width: parent.width - 175 // Spacer to push close button to the right
                    height: 1
                }

                // Close button
                DankActionButton {
                    circular: false
                    iconName: "close"
                    iconSize: Theme.iconSize - 4
                    iconColor: Theme.surfaceText
                    hoverColor: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12)
                    onClicked: settingsPopup.settingsVisible = false
                }

            }

            // Settings sections
            Flickable {
                id: settingsScrollView
                width: parent.width
                height: parent.height - 80
                clip: true
                contentHeight: settingsColumn.height
                boundsBehavior: Flickable.DragAndOvershootBounds
                flickDeceleration: 8000
                maximumFlickVelocity: 15000
                
                property real wheelStepSize: 60

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    propagateComposedEvents: true
                    z: -1
                    onWheel: (wheel) => {
                        var delta = wheel.angleDelta.y
                        var steps = delta / 120
                        settingsScrollView.contentY -= steps * settingsScrollView.wheelStepSize
                        
                        // Keep within bounds
                        if (settingsScrollView.contentY < 0)
                            settingsScrollView.contentY = 0
                        else if (settingsScrollView.contentY > settingsScrollView.contentHeight - settingsScrollView.height)
                            settingsScrollView.contentY = Math.max(0, settingsScrollView.contentHeight - settingsScrollView.height)
                    }
                }

                Column {
                    id: settingsColumn
                    width: parent.width
                    spacing: Theme.spacingL

                    // Profile Settings
                    SettingsSection {
                        title: "Profile"
                        iconName: "person"
                        content: ProfileTab {}
                    }

                    // Clock Settings
                    SettingsSection {
                        title: "Clock & Time"
                        iconName: "schedule"
                        content: ClockTab {}
                    }

                    // Weather Settings
                    SettingsSection {
                        title: "Weather"
                        iconName: "wb_sunny"
                        content: WeatherTab {}
                    }

                    // Widget Visibility Settings
                    SettingsSection {
                        title: "Top Bar Widgets"
                        iconName: "widgets"
                        content: WidgetsTab {}
                    }

                    // Workspace Settings
                    SettingsSection {
                        title: "Workspaces"
                        iconName: "tab"
                        content: WorkspaceTab {}
                    }

                    // Display Settings
                    SettingsSection {
                        title: "Display & Appearance"
                        iconName: "palette"
                        content: DisplayTab {}
                    }

                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
            }

        }

        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 8
            shadowBlur: 1
            shadowColor: Qt.rgba(0, 0, 0, 0.3)
            shadowOpacity: 0.3
        }

    }

    // Keyboard focus and shortcuts
    FocusScope {
        anchors.fill: parent
        focus: settingsPopup.settingsVisible
        Keys.onEscapePressed: settingsPopup.settingsVisible = false
    }

}