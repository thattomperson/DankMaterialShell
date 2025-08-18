import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root
    
    property string section: "left"
    property var parentScreen
    
    readonly property int windowCount: NiriService.windows.length
    readonly property int calculatedWidth: windowCount > 0 ? windowCount * 24 + (windowCount - 1) * Theme.spacingXS + Theme.spacingS * 2 : 0
    
    width: calculatedWidth
    height: 30
    radius: Theme.cornerRadius
    visible: windowCount > 0
    color: {
        if (windowCount === 0)
            return "transparent"
            
        const baseColor = Theme.secondaryHover
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b,
                       baseColor.a * Theme.widgetTransparency)
    }
    
    Row {
        id: windowRow
        anchors.centerIn: parent
        spacing: Theme.spacingXS
        
        Repeater {
            id: windowRepeater
            model: NiriService.windows
            
            delegate: Item {
                property bool isFocused: String(modelData.id) === String(FocusedWindowService.focusedWindowId)
                property string appId: modelData.app_id || ""
                property string windowTitle: modelData.title || "(Unnamed)"
                property int windowId: modelData.id
                property string tooltipText: {
                    var appName = "Unknown"
                    if (appId) {
                        var desktopEntry = DesktopEntries.byId(appId)
                        appName = desktopEntry && desktopEntry.name ? desktopEntry.name : appId
                    }
                    return appName + (windowTitle ? " • " + windowTitle : "")
                }
                
                width: 24
                height: 24
                
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.cornerRadius
                    color: {
                        if (isFocused) {
                            return mouseArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                        } else {
                            return mouseArea.containsMouse ? Qt.rgba(Theme.primaryHover.r, Theme.primaryHover.g, Theme.primaryHover.b, 0.1) : "transparent"
                        }
                    }
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.shortDuration
                            easing.type: Theme.standardEasing
                        }
                    }
                }
                
                // App icon
                IconImage {
                    id: iconImg
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: {
                        if (!appId) return ""
                        var desktopEntry = DesktopEntries.byId(appId)
                        if (desktopEntry && desktopEntry.icon) {
                            var iconPath = Quickshell.iconPath(
                                desktopEntry.icon,
                                SettingsData.iconTheme === "System Default" ? "" : SettingsData.iconTheme)
                            return iconPath
                        }
                        return ""
                    }
                    smooth: true
                    mipmap: true
                    asynchronous: true
                    visible: status === Image.Ready
                }
                
                // Fallback text if no icon found
                Text {
                    anchors.centerIn: parent
                    visible: !iconImg.visible
                    text: {
                        if (!appId) return "?"
                        var desktopEntry = DesktopEntries.byId(appId)
                        if (desktopEntry && desktopEntry.name) {
                            return desktopEntry.name.charAt(0).toUpperCase()
                        }
                        return appId.charAt(0).toUpperCase()
                    }
                    font.pixelSize: 10
                    color: Theme.surfaceText
                    font.weight: Font.Medium
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: {
                        NiriService.focusWindow(windowId)
                    }
                }
            }
        }
    }
}