import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets

PanelWindow {
    id: root

    visible: NotificationService.groupedPopups.length > 0
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
    implicitWidth: 400
    implicitHeight: notificationsList.height + 32

    anchors {
        top: true
        right: true
    }

    margins {
        top: Theme.barHeight
        right: 12
    }

    Column {
        id: notificationsList

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 16
        anchors.rightMargin: 16
        spacing: Theme.spacingM
        width: 380

        Repeater {
            model: NotificationService.groupedPopups

            delegate: Rectangle {
                required property var modelData

                width: parent.width
                height: content.height + Theme.spacingL * 2
                radius: Theme.cornerRadiusLarge
                color: Theme.popupBackground()
                border.color: modelData.latestNotification.urgency === 2 ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
                border.width: modelData.latestNotification.urgency === 2 ? 2 : 1
                clip: true

                Rectangle {
                    width: 4
                    height: parent.height - 16
                    anchors.left: parent.left
                    anchors.leftMargin: 2
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 2
                    color: Theme.primary
                    visible: modelData.latestNotification.urgency === 2
                }

                Row {
                    id: content
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM
                    height: Math.max(48, textContent.height)

                    Rectangle {
                        width: 48
                        height: 48
                        radius: 24
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3)
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter

                        readonly property bool hasNotificationImage: modelData.latestNotification.image && modelData.latestNotification.image !== ""
                        readonly property bool appIconIsImage: modelData.latestNotification.appIcon && 
                            (modelData.latestNotification.appIcon.startsWith("file://") || 
                             modelData.latestNotification.appIcon.startsWith("http://") || 
                             modelData.latestNotification.appIcon.startsWith("https://"))

                        IconImage {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: {
                                // Priority 1: Use notification image if available
                                if (parent.hasNotificationImage) {
                                    return modelData.latestNotification.cleanImage;
                                }
                                
                                // Priority 2: Use appIcon - handle URLs directly, use iconPath for icon names
                                if (modelData.latestNotification.appIcon) {
                                    const appIcon = modelData.latestNotification.appIcon;
                                    if (appIcon.startsWith("file://") || appIcon.startsWith("http://") || appIcon.startsWith("https://")) {
                                        return appIcon;
                                    }
                                    return Quickshell.iconPath(appIcon, "");
                                }
                                
                                return "";
                            }
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !parent.hasNotificationImage && (!modelData.latestNotification.appIcon || modelData.latestNotification.appIcon === "")
                            text: {
                                const appName = modelData.appName || "?";
                                return appName.charAt(0).toUpperCase();
                            }
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            color: Theme.primaryText
                        }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            color: Theme.primary
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: -2
                            anchors.rightMargin: -2
                            visible: modelData.count > 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.count > 99 ? "99+" : modelData.count.toString()
                                color: Theme.primaryText
                                font.pixelSize: 9
                                font.weight: Font.Bold
                            }
                        }
                    }

                    Column {
                        id: textContent
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        width: parent.width - 48 - Theme.spacingM - controls.width - Theme.spacingS

                        Text {
                            width: parent.width
                            text: {
                                if (modelData.latestNotification.timeStr.length > 0)
                                    return modelData.appName + " • " + modelData.latestNotification.timeStr;
                                else
                                    return modelData.appName;
                            }
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Text {
                            text: modelData.latestNotification.summary
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            width: parent.width
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            visible: text.length > 0
                        }

                        Text {
                            text: modelData.latestNotification.body
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                            width: parent.width
                            elide: Text.ElideRight
                            maximumLineCount: modelData.count > 1 ? 1 : 2
                            wrapMode: Text.WordWrap
                            visible: text.length > 0
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingS
                            visible: modelData.latestNotification.notification.hasInlineReply

                            Rectangle {
                                width: parent.width - 60
                                height: 36
                                radius: 18
                                color: Theme.surfaceContainer
                                border.color: quickReplyField.activeFocus ? Theme.primary : Theme.outline
                                border.width: 1

                                TextField {
                                    id: quickReplyField
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingS
                                    placeholderText: modelData.latestNotification.notification.inlineReplyPlaceholder || "Quick reply..."
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    onAccepted: {
                                        if (text.length > 0) {
                                            modelData.latestNotification.notification.sendInlineReply(text);
                                            text = "";
                                        }
                                    }
                                    background: Item {}
                                }
                            }

                            Rectangle {
                                width: 52
                                height: 36
                                radius: 18
                                color: quickReplyField.text.length > 0 ? Theme.primary : Theme.surfaceContainer
                                border.color: quickReplyField.text.length > 0 ? "transparent" : Theme.outline
                                border.width: quickReplyField.text.length > 0 ? 0 : 1

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: "send"
                                    size: 16
                                    color: quickReplyField.text.length > 0 ? Theme.primaryText : Theme.surfaceVariantText
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: quickReplyField.text.length > 0
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        modelData.latestNotification.notification.sendInlineReply(quickReplyField.text);
                                        quickReplyField.text = "";
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.shortDuration
                                        easing.type: Theme.standardEasing
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        id: controls
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: expandArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"
                            visible: modelData.count > 1

                            DankIcon {
                                anchors.centerIn: parent
                                name: "expand_more"
                                size: 18
                                color: Theme.surfaceText
                            }

                            MouseArea {
                                id: expandArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationService.toggleGroupExpansion(modelData.key)
                            }
                        }

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: dismissArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"

                            DankIcon {
                                anchors.centerIn: parent
                                name: "close"
                                size: 16
                                color: Theme.surfaceText
                            }

                            MouseArea {
                                id: dismissArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationService.dismissGroup(modelData.key)
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    propagateComposedEvents: true
                    onEntered: dismissTimer.stop()
                    onExited: {
                        if (modelData.latestNotification.popup)
                            dismissTimer.restart();
                    }
                }

                Timer {
                    id: dismissTimer
                    running: modelData.latestNotification.popup
                    interval: modelData.latestNotification.notification.expireTimeout > 0 ? modelData.latestNotification.notification.expireTimeout * 1000 : 5000
                    onTriggered: {
                        if (!parent.children[parent.children.length - 2].containsMouse) {
                            modelData.latestNotification.popup = false;
                        }
                    }
                }

                transform: Translate {
                    x: root.visible ? 0 : 400
                    Behavior on x {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Theme.mediumDuration
            easing.type: Theme.emphasizedEasing
        }
    }
}