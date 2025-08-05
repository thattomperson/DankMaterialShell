pragma ComponentBehavior: Bound

import Quickshell.Io
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
        if (!visible) {
            if (settingsVisible) {
                settingsVisible = false;
            }
            closingModal();
        }
    }
    
    visible: settingsVisible
    width: 750
    height: 750
    keyboardFocus: "ondemand"
    onBackgroundClicked: {
        settingsVisible = false;
    }

    content: Component {
        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingS

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

                DankActionButton {
                    circular: false
                    iconName: "close"
                    iconSize: Theme.iconSize - 4
                    iconColor: Theme.surfaceText
                    hoverColor: Theme.errorHover
                    onClicked: settingsModal.settingsVisible = false
                }

            }

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
                    
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingL
                        color: "transparent"
                        
                        Loader {
                            anchors.fill: parent
                            active: settingsTabBar.currentIndex === 0
                            visible: active
                            asynchronous: false
                            sourceComponent: Component {
                                PersonalizationTab {}
                            }
                        }
                        
                        Loader {
                            anchors.fill: parent
                            active: settingsTabBar.currentIndex === 1
                            visible: active
                            asynchronous: true
                            sourceComponent: Component {
                                TimeWeatherTab {}
                            }
                        }
                        
                        Loader {
                            anchors.fill: parent
                            active: settingsTabBar.currentIndex === 2
                            visible: active
                            asynchronous: true
                            sourceComponent: Component {
                                WidgetsTab {}
                            }
                        }
                        
                        Loader {
                            anchors.fill: parent
                            active: settingsTabBar.currentIndex === 3
                            visible: active
                            asynchronous: true
                            sourceComponent: Component {
                                LauncherTab {}
                            }
                        }
                        
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

    IpcHandler {
        function open() {
            
            settingsModal.settingsVisible = true;
            return "SETTINGS_OPEN_SUCCESS";
        }

        function close() {
            
            settingsModal.settingsVisible = false;
            return "SETTINGS_CLOSE_SUCCESS";
        }

        function toggle() {
            
            settingsModal.settingsVisible = !settingsModal.settingsVisible;
            return "SETTINGS_TOGGLE_SUCCESS";
        }

        target: "settings"
    }
}
