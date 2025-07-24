pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets

ScrollView {
    id: root
    
    clip: true
    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    
    Column {
        width: root.width - 20
        spacing: Theme.spacingL
        topPadding: Theme.spacingM
        bottomPadding: Theme.spacingL
        
        // Profile Section
        Column {
            width: parent.width
            spacing: Theme.spacingM
            
            Row {
                spacing: Theme.spacingS
                
                DankIcon {
                    name: "person"
                    size: Theme.iconSize
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Text {
                    text: "Profile"
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.surfaceText
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
            }
            
            ProfileTab {
                width: parent.width
            }
        }
        
        // Wallpaper Section  
        Column {
            width: parent.width
            spacing: Theme.spacingM
            
            Row {
                spacing: Theme.spacingS
                
                DankIcon {
                    name: "wallpaper"
                    size: Theme.iconSize
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Text {
                    text: "Wallpaper"
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.surfaceText
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
            }
            
            WallpaperTab {
                width: parent.width
            }
        }
    }
}