import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root
    
    property var contextMenu: null
    property var windowsMenu: null
    property bool requestDockShow: false
    property int pinnedAppCount: 0
    
    implicitWidth: row.width
    implicitHeight: row.height
    
    function movePinnedApp(fromIndex, toIndex) {
        if (fromIndex === toIndex) return
        
        var currentPinned = [...Prefs.pinnedApps]
        if (fromIndex < 0 || fromIndex >= currentPinned.length || toIndex < 0 || toIndex >= currentPinned.length) return
        
        var movedApp = currentPinned.splice(fromIndex, 1)[0]
        currentPinned.splice(toIndex, 0, movedApp)
        
        Prefs.setPinnedApps(currentPinned)
    }
    
    Row {
        id: row
        spacing: 2
        anchors.centerIn: parent
        height: 40
    
        Repeater {
            id: repeater
            model: ListModel {
                id: dockModel
                
                Component.onCompleted: updateModel()
                
                function updateModel() {
                    clear()
                    
                    var items = []
                    var runningApps = NiriService.getRunningAppIds()
                    var pinnedApps = [...Prefs.pinnedApps]
                    var addedApps = new Set()
                    
                    pinnedApps.forEach(appId => {
                        var lowerAppId = appId.toLowerCase()
                        if (!addedApps.has(lowerAppId)) {
                            var windows = NiriService.getWindowsByAppId(appId)
                            items.push({
                                appId: appId,
                                windows: windows,
                                isPinned: true,
                                isRunning: windows.length > 0
                            })
                            addedApps.add(lowerAppId)
                        }
                    })
                    root.pinnedAppCount = pinnedApps.length
                    var appUsageRanking = Prefs.appUsageRanking || {}
                    var allUnpinnedApps = []
                    
                    for (var appId in appUsageRanking) {
                        var lowerAppId = appId.toLowerCase()
                        if (!addedApps.has(lowerAppId)) {
                            allUnpinnedApps.push({
                                appId: appId,
                                lastUsed: appUsageRanking[appId].lastUsed || 0,
                                usageCount: appUsageRanking[appId].usageCount || 0
                            })
                        }
                    }
                    
                    allUnpinnedApps.sort((a, b) => b.lastUsed - a.lastUsed)
                    
                    var unpinnedApps = []
                    var recentToAdd = Math.min(3, allUnpinnedApps.length)
                    for (var i = 0; i < recentToAdd; i++) {
                        var appId = allUnpinnedApps[i].appId
                        var lowerAppId = appId.toLowerCase()
                        unpinnedApps.push(appId)
                        addedApps.add(lowerAppId)
                    }
                    if (pinnedApps.length > 0 && unpinnedApps.length > 0) {
                        items.push({
                            appId: "__SEPARATOR__",
                            windows: [],
                            isPinned: false,
                            isRunning: false
                        })
                    }
                    unpinnedApps.forEach(appId => {
                        var windows = NiriService.getWindowsByAppId(appId)
                        items.push({
                            appId: appId,
                            windows: windows,
                            isPinned: false,
                            isRunning: windows.length > 0
                        })
                    })
                    items.forEach(item => {
                        append(item)
                    })
                }
            }
            
            delegate: Item {
                id: delegateItem
                property alias dockButton: button
                
                width: model.appId === "__SEPARATOR__" ? 16 : 40
                height: 40
                
                Rectangle {
                    visible: model.appId === "__SEPARATOR__"
                    width: 2
                    height: 20
                    color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)
                    radius: 1
                    anchors.centerIn: parent
                }
                
                DockAppButton {
                    id: button
                    visible: model.appId !== "__SEPARATOR__"
                    anchors.centerIn: parent
                    
                    width: 40
                    height: 40
                    
                    appData: model
                    contextMenu: root.contextMenu
                    windowsMenu: root.windowsMenu
                    dockApps: root
                    index: model.index
                }
            }
        }
    }
    
    Connections {
        target: NiriService
        function onWindowsChanged() { dockModel.updateModel() }
        function onWindowOpenedOrChanged() { dockModel.updateModel() }
    }
    
    Connections {
        target: Prefs
        function onPinnedAppsChanged() { dockModel.updateModel() }
    }
}