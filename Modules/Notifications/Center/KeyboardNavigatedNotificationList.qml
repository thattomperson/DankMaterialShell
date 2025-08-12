import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

DankListView {
    id: listView
    
    property var keyboardController: null
    property bool enableKeyboardNavigation: false
    property int currentSelectedGroupIndex: -1
    property bool keyboardActive: false
    
    
    // Compatibility aliases for NotificationList
    property alias count: listView.count
    property alias listContentHeight: listView.contentHeight
    
    clip: true
    model: NotificationService.groupedNotifications
    spacing: Theme.spacingL
    
    NotificationEmptyState {
        visible: listView.count === 0
        anchors.centerIn: parent
    }
    
    // Override position restoration during keyboard nav
    onModelChanged: {
        if (keyboardController && keyboardController.keyboardNavigationActive) {
            // Preserve scroll position during model updates
            Qt.callLater(function() {
                if (keyboardController && keyboardController.keyboardNavigationActive) {
                    keyboardController.ensureVisible()
                }
            })
        }
    }
    
    delegate: Item {
        required property var modelData
        required property int index
        
        readonly property bool isExpanded: NotificationService.expandedGroups[modelData?.key] || false
        readonly property bool isHighlighted: {
            if (!keyboardController) return false
            keyboardController.selectionVersion // Trigger re-evaluation
            if (!listView.keyboardActive) return false
            const selection = keyboardController.getCurrentSelection()
            return selection.type === "group" && selection.groupIndex === index
        }
        
        width: ListView.view.width
        height: notificationCardWrapper.height
        
        Item {
            id: notificationCardWrapper
            width: parent.width
            height: notificationCard.height
            
            NotificationCard {
                id: notificationCard
                width: parent.width
                notificationGroup: modelData
                
                isGroupSelected: {
                    // Force re-evaluation when selection changes
                    if (!keyboardController) return false
                    keyboardController.selectionVersion // Trigger re-evaluation
                    if (!listView.keyboardActive) return false
                    const selection = keyboardController.getCurrentSelection()
                    console.log("isGroupSelected check for index", index, "selection:", JSON.stringify(selection))
                    return selection.type === "group" && selection.groupIndex === index
                }
                selectedNotificationIndex: {
                    // Force re-evaluation when selection changes
                    if (!keyboardController) return -1
                    keyboardController.selectionVersion // Trigger re-evaluation
                    if (!listView.keyboardActive) return -1
                    const selection = keyboardController.getCurrentSelection()
                    return (selection.type === "notification" && selection.groupIndex === index) 
                           ? selection.notificationIndex : -1
                }
                keyboardNavigationActive: listView.keyboardActive
            }
            
            // Group-level overlay only for collapsed groups when selected
            Rectangle {
                anchors.fill: parent
                visible: {
                    if (!isHighlighted) return false
                    if (!keyboardController) return false
                    const selection = keyboardController.getCurrentSelection()
                    // Only show group overlay when selecting collapsed groups
                    return selection.type === "group" && (!modelData || !NotificationService.expandedGroups[modelData.key])
                }
                
                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                border.color: Theme.primary
                border.width: 2
                radius: Theme.cornerRadius
                z: 10
            }
        }
        
    }
    

    // Connect to notification changes and rebuild navigation
    Connections {
        function onGroupedNotificationsChanged() {
            if (keyboardController) {
                if (keyboardController.isTogglingGroup) {
                    keyboardController.rebuildFlatNavigation()
                    return
                }
                
                keyboardController.rebuildFlatNavigation()
            }
        }
        target: NotificationService
    }
    
}