import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Common
import qs.Modules.Notifications.Center
import qs.Services
import qs.Widgets

Item {
    id: root
    
    // Keyboard controller defined outside modal to ensure proper creation order
    NotificationKeyboardController {
        id: modalKeyboardController
        listView: null
        isOpen: notificationModal.notificationModalOpen
        onClose: function() { notificationModal.hide() }
    }

    property alias notificationModal: notificationModal
    
    DankModal {
        id: notificationModal

    property bool notificationModalOpen: false
    property var notificationListRef: null



    function show() {
        notificationModalOpen = true
        modalKeyboardController.reset()
        
        // Set the listView reference when modal is shown
        if (modalKeyboardController && notificationListRef) {
            modalKeyboardController.listView = notificationListRef
            modalKeyboardController.rebuildFlatNavigation()
        }
    }

    function hide() {
        notificationModalOpen = false
        modalKeyboardController.reset()
    }

    function toggle() {
        if (notificationModalOpen)
            hide()
        else
            show()
    }

    

    visible: notificationModalOpen
    width: 500
    height: 700
    keyboardFocus: "ondemand"
    backgroundColor: Theme.popupBackground()
    cornerRadius: Theme.cornerRadius
    borderColor: Theme.outlineMedium
    borderWidth: 1
    enableShadow: true

    onVisibleChanged: {
        if (visible && !notificationModalOpen)
            show()
    }

    onBackgroundClicked: {
        notificationModalOpen = false
    }

    IpcHandler {
        function open() {
            notificationModal.show()
            return "NOTIFICATION_MODAL_OPEN_SUCCESS"
        }

        function close() {
            notificationModal.hide()
            return "NOTIFICATION_MODAL_CLOSE_SUCCESS"
        }

        function toggle() {
            notificationModal.toggle()
            return "NOTIFICATION_MODAL_TOGGLE_SUCCESS"
        }

        target: "notifications"
    }

    content: Component {
        FocusScope {
            id: notificationKeyHandler

            anchors.fill: parent
            focus: true
            
            Keys.onPressed: function(event) {
                modalKeyboardController.handleKey(event)
            }
            
            Component.onCompleted: {
                forceActiveFocus()
            }

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingL

                Rectangle {
                    width: parent.width
                    height: 48
                    color: "transparent"

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "notifications"
                            size: Theme.iconSize
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "Notification Center"
                            font.pixelSize: Theme.fontSizeXLarge
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingS

                        Rectangle {
                            width: 32
                            height: 32
                            radius: Theme.cornerRadius
                            color: helpButtonArea.containsMouse ? Theme.primaryHover : (modalKeyboardController.showKeyboardHints ? Theme.primaryPressed : "transparent")
                            border.color: Theme.primary
                            border.width: 1

                            StyledText {
                                text: "?"
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Bold
                                color: Theme.primary
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: helpButtonArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modalKeyboardController.showKeyboardHints = !modalKeyboardController.showKeyboardHints
                            }
                        }

                        Rectangle {
                            width: clearAllText.implicitWidth + Theme.spacingM
                            height: 32
                            radius: Theme.cornerRadius
                            color: clearAllArea.containsMouse ? Theme.primaryHover : "transparent"
                            border.color: Theme.primary
                            border.width: 1
                            visible: NotificationService.groupedNotifications.length > 0

                            StyledText {
                                id: clearAllText
                                text: "Clear All"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.primary
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: clearAllArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationService.clearAllNotifications()
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: parent.height - y
                    radius: Theme.cornerRadius
                    color: Theme.surfaceLight
                    border.color: Theme.outlineLight
                    border.width: 1
                    clip: false

                    KeyboardNavigatedNotificationList {
                        id: notificationList
                        
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        keyboardController: modalKeyboardController
                        enableKeyboardNavigation: true
                        
                        Component.onCompleted: {
                            notificationModal.notificationListRef = notificationList
                            if (modalKeyboardController) {
                                modalKeyboardController.listView = notificationList
                                modalKeyboardController.rebuildFlatNavigation()
                            }
                        }
                    }

                }

            }

            // Keyboard hints overlay
            NotificationKeyboardHints {
                id: keyboardHints
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Theme.spacingL
                showHints: modalKeyboardController.showKeyboardHints
            }

            Connections {
                function onNotificationModalOpenChanged() {
                    if (notificationModal.notificationModalOpen) {
                        Qt.callLater(function () {
                            notificationKeyHandler.forceActiveFocus()
                        })
                    }
                }
                target: notificationModal
            }


            Connections {
                function onOpened() {
                    Qt.callLater(function () {
                        notificationKeyHandler.forceActiveFocus()
                    })
                }
                target: notificationModal
            }

        }
    }
}
}