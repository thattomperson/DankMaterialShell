import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modals.Clipboard

Item {
    id: clipboardContent

    required property var modal
    required property var filteredModel
    required property var clearConfirmDialog

    property alias searchField: searchField
    property alias clipboardListView: clipboardListView

    anchors.fill: parent

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingL
        spacing: Theme.spacingL
        focus: false

        // Header
        ClipboardHeader {
            id: header
            width: parent.width
            totalCount: modal.totalCount
            showKeyboardHints: modal.showKeyboardHints
            onKeyboardHintsToggled: modal.showKeyboardHints = !modal.showKeyboardHints
            onClearAllClicked: {
                clearConfirmDialog.show("Clear All History?", "This will permanently delete all clipboard history.", function () {
                    modal.clearAll()
                    modal.hide()
                }, function () {} // No action on cancel
                )
            }
            onCloseClicked: modal.hide()
        }

        // Search Field
        DankTextField {
            id: searchField
            width: parent.width
            placeholderText: ""
            leftIconName: "search"
            showClearButton: true
            focus: true
            ignoreLeftRightKeys: true
            keyForwardTargets: [modal.modalFocusScope]
            onTextChanged: {
                modal.searchText = text
                modal.updateFilteredModel()
            }
            Keys.onEscapePressed: function (event) {
                modal.hide()
                event.accepted = true
            }
            Component.onCompleted: {
                Qt.callLater(function () {
                    forceActiveFocus()
                })
            }

            Connections {
                target: modal
                function onOpened() {
                    Qt.callLater(function () {
                        searchField.forceActiveFocus()
                    })
                }
            }
        }

        // List Container
        Rectangle {
            width: parent.width
            height: parent.height - ClipboardConstants.headerHeight - 70
            radius: Theme.cornerRadius
            color: Theme.surfaceLight
            border.color: Theme.outlineLight
            border.width: 1
            clip: true

            ClipboardListView {
                id: clipboardListView
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                model: filteredModel
                clipboardModal: clipboardContent.modal
                selectedIndex: clipboardContent.modal ? clipboardContent.modal.selectedIndex : 0
                keyboardNavigationActive: clipboardContent.modal ? clipboardContent.modal.keyboardNavigationActive : false
            }
        }

        // Spacer for keyboard hints
        Item {
            width: parent.width
            height: modal.showKeyboardHints ? ClipboardConstants.keyboardHintsHeight + Theme.spacingL : 0

            Behavior on height {
                NumberAnimation {
                    duration: Theme.shortDuration
                    easing.type: Theme.standardEasing
                }
            }
        }
    }

    // Keyboard Hints Overlay
    ClipboardKeyboardHints {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacingL
        visible: modal.showKeyboardHints
    }
}
