import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root
    implicitHeight: 220
    radius: Theme.cornerRadius
    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, Theme.getContentBackgroundAlpha() * 0.6)
    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
    border.width: 1

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingS

        Row {
            spacing: Theme.spacingS
            width: parent.width

            StyledText {
                text: VpnService.connected ? ("Active: " + (VpnService.activeName || "VPN")) : "Active: None"
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                font.weight: Font.Medium
            }

            Item { width: 10; height: 1 }

            Rectangle {
                height: 28
                radius: 14
                color: toggleMouse.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.5)
                // Only show quick connect when not connected
                visible: !VpnService.connected && VpnService.profiles.length > 0
                width: 100

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingXS
                    DankIcon { name: "link"; size: Theme.fontSizeSmall; color: Theme.surfaceText }
                    StyledText { text: "Connect"; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText; font.weight: Font.Medium }
                }

                MouseArea {
                    id: toggleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: VpnService.toggle()
                }
            }
        }

        Rectangle { height: 1; width: parent.width; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12) }

        DankFlickable {
            width: parent.width
            height: 160
            contentHeight: listCol.height

            Column {
                id: listCol
                width: parent.width
                spacing: Theme.spacingXS

                Item {
                    width: parent.width
                    height: VpnService.profiles.length === 0 ? 120 : 0
                    visible: height > 0
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.spacingS
                        
                        DankIcon { name: "playlist_remove"; size: 36; color: Theme.surfaceVariantText; anchors.horizontalCenter: parent.horizontalCenter }
                        StyledText { text: "No VPN profiles found"; font.pixelSize: Theme.fontSizeMedium; color: Theme.surfaceVariantText; anchors.horizontalCenter: parent.horizontalCenter }
                        StyledText { text: "Add a VPN in NetworkManager"; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }

                Repeater {
                    model: VpnService.profiles
                    delegate: Rectangle {
                        required property var modelData
                        width: parent ? parent.width : 300
                        height: 40
                        radius: Theme.cornerRadius
                        color: rowMouse.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : "transparent"
                        border.width: 1
                        border.color: modelData.uuid === VpnService.activeUuid ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingS

                            DankIcon {
                                name: modelData.uuid === VpnService.activeUuid ? "vpn_lock" : "vpn_key_off"
                                size: Theme.iconSize - 4
                                color: modelData.uuid === VpnService.activeUuid ? Theme.primary : Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: modelData.name
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Item { Layout.fillWidth: true; height: 1 }

                            Rectangle {
                                height: 28
                                radius: 14
                                color: actMouse.containsMouse
                                       ? (modelData.uuid === VpnService.activeUuid
                                          ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12)
                                          : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12))
                                       : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.5)
                                width: 100
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                                StyledText {
                                    anchors.centerIn: parent
                                    text: modelData.uuid === VpnService.activeUuid ? "Disconnect" : "Connect"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: modelData.uuid === VpnService.activeUuid ? Theme.error : Theme.surfaceText
                                    font.weight: Font.Medium
                                }

                                MouseArea {
                                    id: actMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.uuid === VpnService.activeUuid) {
                                            VpnService.disconnect(modelData.uuid)
                                        } else {
                                            VpnService.connect(modelData.uuid)
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }

                Item { height: 1; width: 1 }
            }
        }
    }
}
