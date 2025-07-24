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
        
        // Display Settings
        Column {
            width: parent.width
            spacing: Theme.spacingM
            
            Row {
                spacing: Theme.spacingS
                
                DankIcon {
                    name: "monitor"
                    size: Theme.iconSize
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Text {
                    text: "Display"
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
            
            DisplayTab {
                width: parent.width
            }
        }
    }
}