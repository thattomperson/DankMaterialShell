import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root

    // Passed in by TopBar
    property int widgetHeight: 28
    property int barHeight: 32
    property string section: "right"
    property var popupTarget: null
    property var parentScreen: null

    signal toggleVpnPopup()

    width: Math.max(24, contentRow.implicitWidth + Theme.spacingXS * 2)
    height: widgetHeight

    Row {
        id: contentRow
        anchors.fill: parent
        anchors.margins: 0
        spacing: Theme.spacingXS

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: "transparent"
        }

        DankIcon {
            id: icon
            name: VpnService.isBusy ? "sync" : (VpnService.connected ? "vpn_lock" : "vpn_key_off")
            size: Theme.iconSize - 6
            color: VpnService.connected ? Theme.primary : Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter

            RotationAnimation on rotation {
                running: VpnService.isBusy
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 900
            }
        }

        Text {
            id: label
            text: VpnService.connected ? (VpnService.activeName || "VPN") : "VPN"
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: VpnService.connected ? Theme.primary : Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter
            visible: true
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: {
            if (popupTarget && popupTarget.setTriggerPosition) {
                var globalPos = mapToGlobal(0, 0)
                var currentScreen = parentScreen || Screen
                var screenX = currentScreen.x || 0
                var relativeX = globalPos.x - screenX
                popupTarget.setTriggerPosition(relativeX, barHeight + Theme.spacingXS, width, section, currentScreen)
            }
            root.toggleVpnPopup()
        }
    }

    Rectangle {
        id: tooltip
        width: Math.max(120, tooltipText.contentWidth + Theme.spacingM * 2)
        height: tooltipText.contentHeight + Theme.spacingS * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainer
        border.color: Theme.surfaceVariantAlpha
        border.width: 1
        visible: clickArea.containsMouse && !(popupTarget && popupTarget.shouldBeVisible)
        anchors.bottom: parent.top
        anchors.bottomMargin: Theme.spacingS
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: clickArea.containsMouse ? 1 : 0

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: VpnService.connected ? ("VPN Connected • " + (VpnService.activeName || "")) : "VPN Disconnected"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceText
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.shortDuration; easing.type: Theme.standardEasing }
        }
    }
}
