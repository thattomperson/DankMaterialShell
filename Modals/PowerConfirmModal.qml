import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets

DankModal {
    id: root

    property string powerConfirmAction: ""
    property string powerConfirmTitle: ""
    property string powerConfirmMessage: ""
    property int selectedButton: -1 // -1 = none, 0 = Cancel, 1 = Confirm
    property bool keyboardNavigation: false

    function show(action, title, message) {
        powerConfirmAction = action
        powerConfirmTitle = title
        powerConfirmMessage = message
        selectedButton = -1 // No button selected initially
        keyboardNavigation = false
        open()
    }

    function selectButton() {
        if (selectedButton === 0) {
            close()
        } else {
            close()
            executePowerAction(powerConfirmAction)
        }
    }

    function executePowerAction(action) {
        switch (action) {
        case "logout":
            CompositorService.logout()
            break
        case "suspend":
            SessionService.suspend()
            break
        case "reboot":
            SessionService.reboot()
            break
        case "poweroff":
            SessionService.poweroff()
            break
        }
    }

    shouldBeVisible: false
    width: 350
    height: 160
    enableShadow: false
    onBackgroundClicked: {
        close()
    }
    onOpened: {
        modalFocusScope.forceActiveFocus()
    }
    modalFocusScope.Keys.onPressed: function(event) {
        switch (event.key) {
        case Qt.Key_Left:
        case Qt.Key_Up:
            keyboardNavigation = true
            selectedButton = 0
            event.accepted = true
            break
        case Qt.Key_Right:
        case Qt.Key_Down:
            keyboardNavigation = true
            selectedButton = 1
            event.accepted = true
            break
        case Qt.Key_Tab:
            keyboardNavigation = true
            selectedButton = selectedButton === -1 ? 0 : (selectedButton + 1) % 2
            event.accepted = true
            break
        case Qt.Key_Return:
        case Qt.Key_Enter:
            selectButton()
            event.accepted = true
            break
        }
    }

    content: Component {
        Item {
            anchors.fill: parent

            Column {
                anchors.centerIn: parent
                width: parent.width - Theme.spacingM * 2
                spacing: Theme.spacingM

                StyledText {
                    text: powerConfirmTitle
                    font.pixelSize: Theme.fontSizeLarge
                    color: {
                        switch (powerConfirmAction) {
                        case "poweroff":
                            return Theme.error
                        case "reboot":
                            return Theme.warning
                        default:
                            return Theme.surfaceText
                        }
                    }
                    font.weight: Font.Medium
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                }

                StyledText {
                    text: powerConfirmMessage
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                Item {
                    height: Theme.spacingS
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacingM

                    Rectangle {
                        width: 120
                        height: 40
                        radius: Theme.cornerRadius
                        color: {
                            if (keyboardNavigation && selectedButton === 0)
                                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                            else if (cancelButton.containsMouse)
                                return Theme.surfacePressed
                            else
                                return Theme.surfaceVariantAlpha
                        }
                        border.color: (keyboardNavigation && selectedButton === 0) ? Theme.primary : "transparent"
                        border.width: (keyboardNavigation && selectedButton === 0) ? 1 : 0

                        StyledText {
                            text: "Cancel"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: cancelButton

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                selectedButton = 0
                                selectButton()
                            }
                        }

                    }

                    Rectangle {
                        width: 120
                        height: 40
                        radius: Theme.cornerRadius
                        color: {
                            let baseColor
                            switch (powerConfirmAction) {
                            case "poweroff":
                                baseColor = Theme.error
                                break
                            case "reboot":
                                baseColor = Theme.warning
                                break
                            default:
                                baseColor = Theme.primary
                                break
                            }
                            if (keyboardNavigation && selectedButton === 1)
                                return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 1)
                            else if (confirmButton.containsMouse)
                                return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 0.9)
                            else
                                return baseColor
                        }
                        border.color: (keyboardNavigation && selectedButton === 1) ? "white" : "transparent"
                        border.width: (keyboardNavigation && selectedButton === 1) ? 1 : 0

                        StyledText {
                            text: "Confirm"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.primaryText
                            font.weight: Font.Medium
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: confirmButton

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                selectedButton = 1
                                selectButton()
                            }
                        }

                    }

                }

            }

        }

    }

}
