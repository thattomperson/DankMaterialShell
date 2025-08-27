import QtQuick
import QtQuick.Effects
import qs.Common

Item {
    id: root

    property int screenWidth: parent.width
    property int screenHeight: parent.height

    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        color: Theme.background
    }

    Rectangle {
        x: parent.width * 0.7
        y: -parent.height * 0.3
        width: parent.width * 0.8
        height: parent.height * 1.5
        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
        rotation: 35
    }

    Rectangle {
        x: parent.width * 0.85
        y: -parent.height * 0.2
        width: parent.width * 0.4
        height: parent.height * 1.2
        color: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.12)
        rotation: 35
    }


    Item {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.spacingXL * 2
        
        readonly property real logoHeight: 6 * (Theme.fontSizeLarge * 1.2 * 1.2)
        readonly property real widgetHeight: Math.max(20, 26 + SettingsData.topBarInnerPadding * 0.6)
        readonly property real effectiveBarHeight: Math.max(widgetHeight + SettingsData.topBarInnerPadding + 4, Theme.barHeight - 4 - (8 - SettingsData.topBarInnerPadding))
        readonly property real topBarExclusiveZone: SettingsData.topBarVisible && !SettingsData.topBarAutoHide ? effectiveBarHeight + SettingsData.topBarSpacing - 2 + SettingsData.topBarBottomGap : 0
        readonly property real availableHeight: screenHeight - topBarExclusiveZone
        anchors.bottomMargin: {
            const minMargin = Theme.spacingXL * 3
            const preferredMargin = (availableHeight - logoHeight) * 0.15
            const maxSafeMargin = Math.max(0, availableHeight - logoHeight - Theme.spacingXL)
            return Math.min(Math.max(minMargin, preferredMargin), maxSafeMargin)
        }
        
        opacity: 0.25
        
        StyledText {
            text: `
██████╗  █████╗ ███╗   ██╗██╗  ██╗
██╔══██╗██╔══██╗████╗  ██║██║ ██╔╝
██║  ██║███████║██╔██╗ ██║█████╔╝
██║  ██║██╔══██║██║╚██╗██║██╔═██╗
██████╔╝██║  ██║██║ ╚████║██║  ██╗
╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝`
            isMonospace: true
            font.pixelSize: Theme.fontSizeLarge * 1.2
            color: Theme.primary
        }
    }
}