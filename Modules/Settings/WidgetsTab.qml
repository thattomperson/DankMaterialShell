import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets

ScrollView {
    id: widgetsTab
    
    contentWidth: availableWidth
    contentHeight: column.implicitHeight + Theme.spacingXL
    clip: true
    
    Column {
        id: column
        width: parent.width
        spacing: Theme.spacingXL
        topPadding: Theme.spacingL
        bottomPadding: Theme.spacingXL
        
        // Top Bar Widgets Section
        StyledRect {
            width: parent.width
            height: topBarSection.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadiusLarge
            color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            border.width: 1
            
            Column {
                id: topBarSection
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM
                
                Row {
                    width: parent.width
                    spacing: Theme.spacingM
                    
                    DankIcon {
                        name: "widgets"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    StyledText {
                        text: "Top Bar Widgets"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                DankToggle {
                    width: parent.width
                    text: "Focused Window"
                    description: "Show the currently focused application in the top bar"
                    checked: Prefs.showFocusedWindow
                    onToggled: (checked) => {
                        return Prefs.setShowFocusedWindow(checked);
                    }
                }
                
                DankToggle {
                    width: parent.width
                    text: "Weather Widget"
                    description: "Display weather information in the top bar"
                    checked: Prefs.showWeather
                    onToggled: (checked) => {
                        return Prefs.setShowWeather(checked);
                    }
                }
                
                DankToggle {
                    width: parent.width
                    text: "Media Controls"
                    description: "Show currently playing media in the top bar"
                    checked: Prefs.showMusic
                    onToggled: (checked) => {
                        return Prefs.setShowMusic(checked);
                    }
                }
                
                DankToggle {
                    width: parent.width
                    text: "Clipboard Button"
                    description: "Show clipboard access button in the top bar"
                    checked: Prefs.showClipboard
                    onToggled: (checked) => {
                        return Prefs.setShowClipboard(checked);
                    }
                }
                
                DankToggle {
                    width: parent.width
                    text: "System Resources"
                    description: "Display CPU and RAM usage indicators"
                    checked: Prefs.showSystemResources
                    onToggled: (checked) => {
                        return Prefs.setShowSystemResources(checked);
                    }
                }
                
                DankToggle {
                    width: parent.width
                    text: "System Tray"
                    description: "Show system tray icons in the top bar"
                    checked: Prefs.showSystemTray
                    onToggled: (checked) => {
                        return Prefs.setShowSystemTray(checked);
                    }
                }
            }
        }
        
        // Workspace Section
        StyledRect {
            width: parent.width
            height: workspaceSection.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadiusLarge
            color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            border.width: 1
            
            Column {
                id: workspaceSection
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM
                
                Row {
                    width: parent.width
                    spacing: Theme.spacingM
                    
                    DankIcon {
                        name: "view_module"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    StyledText {
                        text: "Workspace Settings"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                DankToggle {
                    width: parent.width
                    text: "Workspace Index Numbers"
                    description: "Show workspace index numbers in the top bar workspace switcher"
                    checked: Prefs.showWorkspaceIndex
                    onToggled: (checked) => {
                        return Prefs.setShowWorkspaceIndex(checked);
                    }
                }
                
                DankToggle {
                    width: parent.width
                    text: "Workspace Padding"
                    description: "Always show a minimum of 3 workspaces, even if fewer are available"
                    checked: Prefs.showWorkspacePadding
                    onToggled: (checked) => {
                        return Prefs.setShowWorkspacePadding(checked);
                    }
                }
            }
        }
        
        // App Launcher Section
        StyledRect {
            width: parent.width
            height: appLauncherSection.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadiusLarge
            color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            border.width: 1
            
            Column {
                id: appLauncherSection
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM
                
                Row {
                    width: parent.width
                    spacing: Theme.spacingM
                    
                    DankIcon {
                        name: "apps"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    StyledText {
                        text: "App Launcher"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                DankToggle {
                    width: parent.width
                    text: "Use OS Logo for App Launcher"
                    description: "Display operating system logo instead of apps icon"
                    checked: Prefs.useOSLogo
                    onToggled: (checked) => {
                        return Prefs.setUseOSLogo(checked);
                    }
                }
                
                // OS Logo Customization - only visible when OS logo is enabled
                StyledRect {
                    width: parent.width
                    height: logoCustomization.implicitHeight + Theme.spacingM * 2
                    radius: Theme.cornerRadius
                    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.5)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)
                    border.width: 1
                    visible: Prefs.useOSLogo
                    opacity: visible ? 1 : 0
                    
                    Column {
                        id: logoCustomization
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingM
                        
                        StyledText {
                            text: "OS Logo Customization"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }
                        
                        Column {
                            width: parent.width
                            spacing: Theme.spacingS
                            
                            StyledText {
                                text: "Color Override"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                            }
                            
                            DankTextField {
                                width: 160
                                height: 36
                                placeholderText: "#ffffff"
                                text: Prefs.osLogoColorOverride
                                maximumLength: 7
                                font.pixelSize: Theme.fontSizeMedium
                                topPadding: Theme.spacingS
                                bottomPadding: Theme.spacingS
                                onEditingFinished: {
                                    var color = text.trim();
                                    if (color === "" || /^#[0-9A-Fa-f]{6}$/.test(color))
                                        Prefs.setOSLogoColorOverride(color);
                                    else
                                        text = Prefs.osLogoColorOverride;
                                }
                            }
                        }
                        
                        Column {
                            width: parent.width
                            spacing: Theme.spacingS
                            
                            StyledText {
                                text: "Brightness"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                            }
                            
                            DankSlider {
                                width: parent.width
                                height: 24
                                minimum: 0
                                maximum: 100
                                value: Math.round(Prefs.osLogoBrightness * 100)
                                unit: ""
                                showValue: true
                                onSliderValueChanged: (newValue) => {
                                    Prefs.setOSLogoBrightness(newValue / 100);
                                }
                            }
                        }
                        
                        Column {
                            width: parent.width
                            spacing: Theme.spacingS
                            
                            StyledText {
                                text: "Contrast"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                            }
                            
                            DankSlider {
                                width: parent.width
                                height: 24
                                minimum: 0
                                maximum: 200
                                value: Math.round(Prefs.osLogoContrast * 100)
                                unit: ""
                                showValue: true
                                onSliderValueChanged: (newValue) => {
                                    Prefs.setOSLogoContrast(newValue / 100);
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
                }
            }
        }
    }
}