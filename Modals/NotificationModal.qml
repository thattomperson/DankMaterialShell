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
                spacing: Theme.spacingM

                NotificationHeader {
                    id: notificationHeader
                    keyboardController: modalKeyboardController
                }
                
                NotificationSettings {
                    id: notificationSettings
                    expanded: notificationHeader.showSettings
                }

                KeyboardNavigatedNotificationList {
                    id: notificationList
                    
                    width: parent.width
                    height: parent.height - y
                    keyboardController: modalKeyboardController
                    
                    Component.onCompleted: {
                        notificationModal.notificationListRef = notificationList
                        if (modalKeyboardController) {
                            modalKeyboardController.listView = notificationList
                            modalKeyboardController.rebuildFlatNavigation()
                        }
                    }
                }

            }

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