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
    
    // Timer to periodically ensure selected item stays visible during active keyboard navigation
    Timer {
        id: positionPreservationTimer
        interval: 200
        running: keyboardController && keyboardController.keyboardNavigationActive
        repeat: true
        onTriggered: {
            if (keyboardController && keyboardController.keyboardNavigationActive) {
                keyboardController.ensureVisible()
            }
        }
    }
    
    NotificationEmptyState {
        visible: listView.count === 0
        anchors.centerIn: parent
    }
    
    // Override position restoration during keyboard nav
    onModelChanged: {
        if (keyboardController && keyboardController.keyboardNavigationActive) {
            // Rebuild navigation and preserve position aggressively
            keyboardController.rebuildFlatNavigation()
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
                    if (!keyboardController || !keyboardController.keyboardNavigationActive) return false
                    keyboardController.selectionVersion // Trigger re-evaluation
                    if (!listView.keyboardActive) return false
                    const selection = keyboardController.getCurrentSelection()
                    return selection.type === "group" && selection.groupIndex === index
                }
                selectedNotificationIndex: {
                    // Force re-evaluation when selection changes
                    if (!keyboardController || !keyboardController.keyboardNavigationActive) return -1
                    keyboardController.selectionVersion // Trigger re-evaluation
                    if (!listView.keyboardActive) return -1
                    const selection = keyboardController.getCurrentSelection()
                    return (selection.type === "notification" && selection.groupIndex === index) 
                           ? selection.notificationIndex : -1
                }
                keyboardNavigationActive: listView.keyboardActive
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
                
                // If keyboard navigation is active, ensure selected item stays visible
                if (keyboardController.keyboardNavigationActive) {
                    Qt.callLater(function() {
                        keyboardController.ensureVisible()
                    })
                }
            }
        }
        
        function onExpandedGroupsChanged() {
            if (keyboardController && keyboardController.keyboardNavigationActive) {
                Qt.callLater(function() {
                    keyboardController.ensureVisible()
                })
            }
        }
        
        function onExpandedMessagesChanged() {
            if (keyboardController && keyboardController.keyboardNavigationActive) {
                Qt.callLater(function() {
                    keyboardController.ensureVisible()
                })
            }
        }
        
        target: NotificationService
    }
    
}