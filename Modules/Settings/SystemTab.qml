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
        
        // Top Bar Widgets
        Column {
            width: parent.width
            spacing: Theme.spacingM
            
            Row {
                spacing: Theme.spacingS
                
                DankIcon {
                    name: "widgets"
                    size: Theme.iconSize
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Text {
                    text: "Top Bar Widgets"
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
            
            WidgetsTab {
                width: parent.width
            }
        }
        
        // Workspaces
        Column {
            width: parent.width
            spacing: Theme.spacingM
            
            Row {
                spacing: Theme.spacingS
                
                DankIcon {
                    name: "tab"
                    size: Theme.iconSize
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Text {
                    text: "Workspaces"
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
            
            WorkspaceTab {
                width: parent.width
            }
        }
    }
}