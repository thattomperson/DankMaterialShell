import QtQuick
import qs.Common
import qs.Services

Rectangle {
    id: root

    // Dynamic screen detection for laptop vs desktop monitor
    readonly property bool isSmallScreen: {
        // Walk up the parent chain to find the TopBar PanelWindow
        let current = root.parent
        while (current && !current.screen) {
            current = current.parent
        }
        
        if (!current || !current.screen) {
            return true  // Default to small if we can't detect
        }
        
        const s = current.screen
        
        // Multi-method detection for laptop/small screens:
        
        // Method 1: Check screen name for laptop indicators
        const screenName = (s.name || "").toLowerCase()
        if (screenName.includes("edp") || screenName.includes("lvds")) {
            return true
        }
        
        // Method 2: Check pixel density if available
        try {
            if (s.pixelDensity && s.pixelDensity > 1.5) {
                return true
            }
        } catch (e) { /* ignore */ }
        
        // Method 3: Check device pixel ratio if available
        try {
            if (s.devicePixelRatio && s.devicePixelRatio > 1.25) {
                return true
            }
        } catch (e) { /* ignore */ }
        
        // Method 4: Resolution-based fallback for smaller displays
        if (s.width <= 1920 && s.height <= 1200) {
            return true
        }
        
        // Method 5: Check for high-res laptop displays
        if ((s.width === 2400 && s.height === 1600) || 
            (s.width === 2560 && s.height === 1600) ||
            (s.width === 2880 && s.height === 1800)) {
            return true
        }
        
        return false  // Default to large screen
    }
    
    // Dynamic sizing based on screen type
    readonly property int maxWidth: isSmallScreen ? 288 : 456
    readonly property int appNameMaxWidth: isSmallScreen ? 130 : 180
    readonly property int separatorWidth: 15
    readonly property int titleMaxWidth: maxWidth - appNameMaxWidth - separatorWidth - (Theme.spacingS * 2)

    width: Math.min(contentRow.implicitWidth + Theme.spacingS * 2, maxWidth)
    height: 30
    radius: Theme.cornerRadius
    color: mouseArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)
    clip: true
    visible: FocusedWindowService.niriAvailable && (FocusedWindowService.focusedAppName || FocusedWindowService.focusedWindowTitle)

    Row {
        id: contentRow

        anchors.centerIn: parent
        spacing: Theme.spacingS

        Text {
            id: appText

            text: FocusedWindowService.focusedAppName || ""
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter
            // App name gets reasonable space - only truncate if absolutely necessary
            elide: Text.ElideRight
            maximumLineCount: 1
            width: Math.min(implicitWidth, root.appNameMaxWidth)
        }

        Text {
            text: "•"
            font.pixelSize: Theme.fontSizeMedium
            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.5)
            anchors.verticalCenter: parent.verticalCenter
            visible: appText.text && titleText.text
        }

        Text {
            id: titleText

            text: FocusedWindowService.focusedWindowTitle || ""
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter
            // Window title gets remaining space and shows ellipsis when truncated
            elide: Text.ElideRight
            maximumLineCount: 1
            width: Math.min(implicitWidth, root.titleMaxWidth)
        }

    }

    MouseArea {
        // Non-interactive widget - just provides hover state for visual feedback

        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing
        }

    }

    // Smooth width animation when the text changes
    Behavior on width {
        NumberAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing
        }

    }

}
