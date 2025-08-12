import QtQuick
import qs.Common
import qs.Services

QtObject {
    id: controller
    
    // Properties that need to be set by parent
    property var listView: null
    property bool isOpen: false
    property var onClose: null  // Function to call when closing
    
    // Property that changes to trigger binding updates
    property int selectionVersion: 0
    
    // Keyboard navigation state
    property bool keyboardNavigationActive: false
    property int selectedFlatIndex: 0
    property var flatNavigation: []
    property int flatNavigationVersion: 0  // For triggering bindings
    property bool showKeyboardHints: false
    
    // Track selection by ID for position preservation
    property string selectedNotificationId: ""
    property string selectedGroupKey: ""
    property string selectedItemType: ""
    property bool isTogglingGroup: false
    property bool isRebuilding: false
    
    // Build flat navigation array
    function rebuildFlatNavigation() {
        isRebuilding = true
        
        var nav = []
        var groups = NotificationService.groupedNotifications
        console.log("rebuildFlatNavigation: groups.length:", groups.length)
        
        for (var i = 0; i < groups.length; i++) {
            var group = groups[i]
            var isExpanded = NotificationService.expandedGroups[group.key] || false
            
            // Add the group itself
            nav.push({
                type: "group",
                groupIndex: i,
                notificationIndex: -1,
                groupKey: group.key,
                notificationId: ""
            })
            
            // If expanded, add individual notifications
            if (isExpanded) {
                var notifications = group.notifications || []
                for (var j = 0; j < notifications.length; j++) {
                    var notifId = String(notifications[j]?.notification?.id || "")
                    nav.push({
                        type: "notification",
                        groupIndex: i,
                        notificationIndex: j,
                        groupKey: group.key,
                        notificationId: notifId
                    })
                }
            }
        }
        
        flatNavigation = nav
        console.log("rebuildFlatNavigation: nav.length:", nav.length, "selectedFlatIndex:", selectedFlatIndex)
        // Highlight is now handled by NotificationCard properties
        updateSelectedIndexFromId()
        isRebuilding = false
    }
    
    function updateSelectedIndexFromId() {
        if (!keyboardNavigationActive) return
        
        // Find the index that matches our selected ID/key
        for (var i = 0; i < flatNavigation.length; i++) {
            var item = flatNavigation[i]
            
            if (selectedItemType === "group" && item.type === "group" && item.groupKey === selectedGroupKey) {
                selectedFlatIndex = i
                return
            } else if (selectedItemType === "notification" && item.type === "notification" && String(item.notificationId) === String(selectedNotificationId)) {
                selectedFlatIndex = i
                return
            }
        }
        
        // If not found, default to first item
        selectedFlatIndex = 0
        updateSelectedIdFromIndex()
    }
    
    function updateSelectedIdFromIndex() {
        if (selectedFlatIndex >= 0 && selectedFlatIndex < flatNavigation.length) {
            var item = flatNavigation[selectedFlatIndex]
            selectedItemType = item.type
            selectedGroupKey = item.groupKey
            selectedNotificationId = item.notificationId
        }
    }
    
    function reset() {
        selectedFlatIndex = 0
        keyboardNavigationActive = false
        showKeyboardHints = false
        // Reset keyboardActive when modal is reset
        if (listView) {
            listView.keyboardActive = false
        }
        rebuildFlatNavigation()
    }
    
    function selectNext() {
        keyboardNavigationActive = true
        if (flatNavigation.length === 0) return
        
        console.log("selectNext: before -", selectedFlatIndex, "flatNav.length:", flatNavigation.length)
        selectedFlatIndex = Math.min(selectedFlatIndex + 1, flatNavigation.length - 1)
        updateSelectedIdFromIndex()
        console.log("selectNext: after -", selectedFlatIndex)
        selectionVersion++
        ensureVisible()
    }
    
    function selectPrevious() {
        keyboardNavigationActive = true
        if (flatNavigation.length === 0) return
        
        selectedFlatIndex = Math.max(selectedFlatIndex - 1, 0)
        updateSelectedIdFromIndex()
        selectionVersion++
        ensureVisible()
    }
    
    function toggleGroupExpanded() {
        if (flatNavigation.length === 0 || selectedFlatIndex >= flatNavigation.length) return
        
        const currentItem = flatNavigation[selectedFlatIndex]
        const groups = NotificationService.groupedNotifications
        const group = groups[currentItem.groupIndex]
        if (!group) return
        
        // Prevent expanding groups with < 2 notifications
        const notificationCount = group.notifications ? group.notifications.length : 0
        if (notificationCount < 2) return
        
        const wasExpanded = NotificationService.expandedGroups[group.key] || false
        const groupIndex = currentItem.groupIndex
        
        isTogglingGroup = true
        NotificationService.toggleGroupExpansion(group.key)
        rebuildFlatNavigation()
        
        // Smart selection after toggle
        if (!wasExpanded) {
            // Just expanded - move to first notification in the group
            for (let i = 0; i < flatNavigation.length; i++) {
                if (flatNavigation[i].type === "notification" && flatNavigation[i].groupIndex === groupIndex) {
                    selectedFlatIndex = i
                    break
                }
            }
        } else {
            // Just collapsed - stay on the group header
            for (let i = 0; i < flatNavigation.length; i++) {
                if (flatNavigation[i].type === "group" && flatNavigation[i].groupIndex === groupIndex) {
                    selectedFlatIndex = i
                    break
                }
            }
        }
        
        isTogglingGroup = false
        ensureVisible()
    }
    
    function handleEnterKey() {
        if (flatNavigation.length === 0 || selectedFlatIndex >= flatNavigation.length) return
        
        const currentItem = flatNavigation[selectedFlatIndex]
        const groups = NotificationService.groupedNotifications
        const group = groups[currentItem.groupIndex]
        if (!group) return
        
        if (currentItem.type === "group") {
            // On group: expand/collapse the group (only if it has > 1 notification)
            const notificationCount = group.notifications ? group.notifications.length : 0
            if (notificationCount >= 2) {
                toggleGroupExpanded()
            }
        } else if (currentItem.type === "notification") {
            // On individual notification: execute first action if available
            const notification = group.notifications[currentItem.notificationIndex]
            const actions = notification?.actions || []
            if (actions.length > 0) {
                executeAction(0)
            }
        }
    }
    
    function toggleTextExpanded() {
        if (flatNavigation.length === 0 || selectedFlatIndex >= flatNavigation.length) return
        
        const currentItem = flatNavigation[selectedFlatIndex]
        const groups = NotificationService.groupedNotifications
        const group = groups[currentItem.groupIndex]
        if (!group) return
        
        var messageId = ""
        
        if (currentItem.type === "group") {
            messageId = group.latestNotification?.notification?.id + "_desc"
        } else if (currentItem.type === "notification" && currentItem.notificationIndex >= 0 && currentItem.notificationIndex < group.notifications.length) {
            messageId = group.notifications[currentItem.notificationIndex]?.notification?.id + "_desc"
        }
        
        if (messageId) {
            NotificationService.toggleMessageExpansion(messageId)
        }
    }
    
    function executeAction(actionIndex) {
        if (flatNavigation.length === 0 || selectedFlatIndex >= flatNavigation.length) return
        
        const currentItem = flatNavigation[selectedFlatIndex]
        const groups = NotificationService.groupedNotifications
        const group = groups[currentItem.groupIndex]
        if (!group) return
        
        var actions = []
        
        if (currentItem.type === "group") {
            actions = group.latestNotification?.actions || []
        } else if (currentItem.type === "notification" && currentItem.notificationIndex >= 0 && currentItem.notificationIndex < group.notifications.length) {
            actions = group.notifications[currentItem.notificationIndex]?.actions || []
        }
        
        if (actionIndex >= 0 && actionIndex < actions.length) {
            const action = actions[actionIndex]
            if (action.invoke) {
                action.invoke()
                if (onClose) onClose()
            }
        }
    }
    
    function clearSelected() {
        if (flatNavigation.length === 0 || selectedFlatIndex >= flatNavigation.length) return
        
        const currentItem = flatNavigation[selectedFlatIndex]
        const groups = NotificationService.groupedNotifications
        const group = groups[currentItem.groupIndex]
        if (!group) return
        
        // Save current state for smart navigation
        const currentGroupKey = group.key
        const isNotification = currentItem.type === "notification"
        const notificationIndex = currentItem.notificationIndex
        const totalNotificationsInGroup = group.notifications ? group.notifications.length : 0
        const isLastNotificationInGroup = isNotification && totalNotificationsInGroup === 1
        const isLastNotificationInList = isNotification && notificationIndex === totalNotificationsInGroup - 1
        
        // Store what to select next BEFORE clearing
        let nextTargetType = ""
        let nextTargetGroupKey = ""
        let nextTargetNotificationIndex = -1
        
        if (currentItem.type === "group") {
            NotificationService.dismissGroup(group.key)
            
            // Look for next group
            for (let i = currentItem.groupIndex + 1; i < groups.length; i++) {
                nextTargetType = "group"
                nextTargetGroupKey = groups[i].key
                break
            }
            
            if (!nextTargetGroupKey && currentItem.groupIndex > 0) {
                nextTargetType = "group"
                nextTargetGroupKey = groups[currentItem.groupIndex - 1].key
            }
            
        } else if (isNotification) {
            const notification = group.notifications[notificationIndex]
            NotificationService.dismissNotification(notification)
            
            if (isLastNotificationInGroup) {
                for (let i = currentItem.groupIndex + 1; i < groups.length; i++) {
                    nextTargetType = "group"
                    nextTargetGroupKey = groups[i].key
                    break
                }
                
                if (!nextTargetGroupKey && currentItem.groupIndex > 0) {
                    nextTargetType = "group"
                    nextTargetGroupKey = groups[currentItem.groupIndex - 1].key
                }
            } else if (isLastNotificationInList) {
                nextTargetType = "group"
                nextTargetGroupKey = currentGroupKey
                nextTargetNotificationIndex = -1
            } else {
                nextTargetType = "notification"
                nextTargetGroupKey = currentGroupKey
                nextTargetNotificationIndex = notificationIndex
            }
        }
        
        rebuildFlatNavigation()
        
        // Find and select the target we identified
        if (flatNavigation.length === 0) {
            selectedFlatIndex = 0
            updateSelectedIdFromIndex()
        } else if (nextTargetGroupKey) {
            let found = false
            for (let i = 0; i < flatNavigation.length; i++) {
                const item = flatNavigation[i]
                
                if (nextTargetType === "group" && item.type === "group" && item.groupKey === nextTargetGroupKey) {
                    selectedFlatIndex = i
                    found = true
                    break
                } else if (nextTargetType === "notification" && item.type === "notification" && 
                          item.groupKey === nextTargetGroupKey && item.notificationIndex === nextTargetNotificationIndex) {
                    selectedFlatIndex = i
                    found = true
                    break
                }
            }
            
            if (!found) {
                selectedFlatIndex = Math.min(selectedFlatIndex, flatNavigation.length - 1)
            }
            
            updateSelectedIdFromIndex()
        } else {
            selectedFlatIndex = Math.min(selectedFlatIndex, flatNavigation.length - 1)
            updateSelectedIdFromIndex()
        }
        
        ensureVisible()
    }
    
    function ensureVisible() {
        if (flatNavigation.length === 0 || selectedFlatIndex >= flatNavigation.length || !listView) return
        
        const currentItem = flatNavigation[selectedFlatIndex]
        
        if (keyboardNavigationActive && currentItem && currentItem.groupIndex >= 0) {
            // For individual notifications in expanded groups, we still position based on the group
            // but we need to ensure the notification is visible within that group
            if (currentItem.type === "notification") {
                // Position at the group containing the selected notification
                listView.positionViewAtIndex(currentItem.groupIndex, ListView.Contain)
            } else {
                // For group headers, center on the group
                listView.positionViewAtIndex(currentItem.groupIndex, ListView.Center)
            }
        }
    }
    
    function handleKey(event) {
        console.log("HANDLEKEY CALLED:", event.key)
        if (event.key === Qt.Key_Escape) {
            if (keyboardNavigationActive) {
                keyboardNavigationActive = false
                event.accepted = true
            } else {
                if (onClose) onClose()
                event.accepted = true
            }
        } else if (event.key === Qt.Key_Down || event.key === 16777237) {
            console.log("DOWN KEY DETECTED")
            if (!keyboardNavigationActive) {
                keyboardNavigationActive = true
                selectedFlatIndex = 0
                updateSelectedIdFromIndex()
                // Set keyboardActive on listView to show highlight
                if (listView) {
                    listView.keyboardActive = true
                }
                // Initial selection is now handled by NotificationCard properties
                selectionVersion++
                ensureVisible()
                event.accepted = true
            } else {
                selectNext()
                event.accepted = true
            }
        } else if (event.key === Qt.Key_Up || event.key === 16777235) {
            console.log("UP KEY DETECTED")
            if (!keyboardNavigationActive) {
                keyboardNavigationActive = true
                selectedFlatIndex = 0
                updateSelectedIdFromIndex()
                // Set keyboardActive on listView to show highlight
                if (listView) {
                    listView.keyboardActive = true
                }
                // Initial selection is now handled by NotificationCard properties
                selectionVersion++
                ensureVisible()
                event.accepted = true
            } else if (selectedFlatIndex === 0) {
                keyboardNavigationActive = false
                // Reset keyboardActive when navigation is disabled
                if (listView) {
                    listView.keyboardActive = false
                }
                selectionVersion++
                event.accepted = true
                return
            } else {
                selectPrevious()
                event.accepted = true
            }
        } else if (keyboardNavigationActive) {
            if (event.key === Qt.Key_Space) {
                toggleGroupExpanded()
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                handleEnterKey()
                event.accepted = true
            } else if (event.key === Qt.Key_E) {
                toggleTextExpanded()
                event.accepted = true
            } else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
                clearSelected()
                event.accepted = true
            } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                const actionIndex = event.key - Qt.Key_1
                executeAction(actionIndex)
                event.accepted = true
            }
        }
        
        if (event.key === Qt.Key_Question || event.key === Qt.Key_H) {
            showKeyboardHints = !showKeyboardHints
            event.accepted = true
        }
    }
    
    // Get current selection info for UI
    function getCurrentSelection() {
        if (!keyboardNavigationActive || selectedFlatIndex >= flatNavigation.length) {
            console.log("getCurrentSelection: inactive or out of bounds")
            return { type: "", groupIndex: -1, notificationIndex: -1 }
        }
        const result = flatNavigation[selectedFlatIndex] || { type: "", groupIndex: -1, notificationIndex: -1 }
        console.log("getCurrentSelection:", JSON.stringify(result))
        return result
    }
}