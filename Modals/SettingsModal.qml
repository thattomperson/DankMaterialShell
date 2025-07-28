pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Modules.Settings
import qs.Widgets

DankModal {
    id: settingsModal

    property bool settingsVisible: false

    signal closingModal()

    onVisibleChanged: {
        if (!visible)
            closingModal();

    }
    // DankModal configuration
    visible: settingsVisible
    width: 750
    height: 750
    keyboardFocus: "ondemand"
    onBackgroundClicked: {
        settingsVisible = false;
    }

    // Keyboard focus and shortcuts
    FocusScope {
        anchors.fill: parent
        focus: settingsModal.settingsVisible
        Keys.onEscapePressed: settingsModal.settingsVisible = false
    }

    content: Component {
        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingS

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

                StyledText {
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
                    hoverColor: Theme.errorHover
                    onClicked: settingsModal.settingsVisible = false
                }

            }

            // Tabbed Settings
            Column {
                width: parent.width
                height: parent.height - 50
                spacing: 0
                
                DankTabBar {
                    id: settingsTabBar
                    
                    width: parent.width
                    
                    model: [
                        { text: "Personalization", icon: "person" },
                        { text: "Time & Weather", icon: "schedule" },
                        { text: "Widgets", icon: "widgets" },
                        { text: "Launcher", icon: "apps" },
                        { text: "Appearance", icon: "palette" }
                    ]
                }
                
                Item {
                    width: parent.width
                    height: parent.height - settingsTabBar.height
                    
                    // Content container with proper padding
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingL
                        color: "transparent"
                        
                        // Personalization Tab
                        Loader {
                            anchors.fill: parent
                            active: settingsTabBar.currentIndex === 0
                            visible: active
                            asynchronous: true
                            sourceComponent: Component {
                                PersonalizationTab {}
                            }
                        }
                        
                        // Time & Weather Tab
                        Loader {
                            anchors.fill: parent
                            active: settingsTabBar.currentIndex === 1
                            visible: active
                            asynchronous: true
                            sourceComponent: Component {
                                TimeWeatherTab {}
                            }
                        }
                        
                        // Widgets Tab
                        Loader {
                            anchors.fill: parent
                            active: settingsTabBar.currentIndex === 2
                            visible: active
                            asynchronous: true
                            sourceComponent: Component {
                                WidgetsTab {}
                            }
                        }
                        
                        // Launcher Tab
                        Loader {
                            anchors.fill: parent
                            active: settingsTabBar.currentIndex === 3
                            visible: active
                            asynchronous: true
                            sourceComponent: Component {
                                LauncherTab {}
                            }
                        }
                        
                        // Appearance Tab
                        Loader {
                            anchors.fill: parent
                            active: settingsTabBar.currentIndex === 4
                            visible: active
                            asynchronous: false
                            sourceComponent: Component {
                                AppearanceTab {}
                            }
                        }
                    }
                }
            }

        }

    }

}
