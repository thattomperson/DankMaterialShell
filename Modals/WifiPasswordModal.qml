import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services
import qs.Widgets

DankModal {
    id: root

    property bool wifiPasswordModalVisible: false
    property string wifiPasswordSSID: ""
    property string wifiPasswordInput: ""

    visible: wifiPasswordModalVisible
    width: 420
    height: 230
    keyboardFocus: "ondemand"
    onVisibleChanged: {
        if (!visible)
            wifiPasswordInput = "";

    }
    onBackgroundClicked: {
        wifiPasswordModalVisible = false;
        wifiPasswordInput = "";
    }

    // Auto-reopen dialog on invalid password
    Connections {
        function onPasswordDialogShouldReopenChanged() {
            if (NetworkService.passwordDialogShouldReopen && NetworkService.connectingSSID !== "") {
                wifiPasswordSSID = NetworkService.connectingSSID;
                wifiPasswordInput = "";
                wifiPasswordModalVisible = true;
                NetworkService.passwordDialogShouldReopen = false;
            }
        }

        target: NetworkService
    }

    content: Component {
        Item {
            anchors.fill: parent

            Column {
                anchors.centerIn: parent
                width: parent.width - Theme.spacingM * 2
                spacing: Theme.spacingM

                // Header
                Row {
                    width: parent.width

                    Column {
                        width: parent.width - 40
                        spacing: Theme.spacingXS

                        StyledText {
                            text: "Connect to Wi-Fi"
                            font.pixelSize: Theme.fontSizeLarge
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        StyledText {
                            text: "Enter password for \"" + wifiPasswordSSID + "\""
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceTextMedium
                            width: parent.width
                            elide: Text.ElideRight
                        }

                    }

                    DankActionButton {
                        iconName: "close"
                        iconSize: Theme.iconSize - 4
                        iconColor: Theme.surfaceText
                        hoverColor: Theme.errorHover
                        onClicked: {
                            wifiPasswordModalVisible = false;
                            wifiPasswordInput = "";
                        }
                    }

                }

                // Password input
                Rectangle {
                    width: parent.width
                    height: 50
                    radius: Theme.cornerRadius
                    color: Theme.surfaceHover
                    border.color: passwordInput.activeFocus ? Theme.primary : Theme.outlineStrong
                    border.width: passwordInput.activeFocus ? 2 : 1

                    DankTextField {
                        id: passwordInput

                        anchors.fill: parent
                        font.pixelSize: Theme.fontSizeMedium
                        textColor: Theme.surfaceText
                        text: wifiPasswordInput
                        echoMode: showPasswordCheckbox.checked ? TextInput.Normal : TextInput.Password
                        placeholderText: "Enter password"
                        backgroundColor: "transparent"
                        normalBorderColor: "transparent"
                        focusedBorderColor: "transparent"
                        onTextEdited: {
                            wifiPasswordInput = text;
                        }
                        onAccepted: {
                            NetworkService.connectToWifiWithPassword(wifiPasswordSSID, passwordInput.text);
                            wifiPasswordModalVisible = false;
                            wifiPasswordInput = "";
                            passwordInput.text = "";
                        }

                        Connections {
                            function onOpened() {
                                passwordInput.forceActiveFocus();
                            }

                            function onDialogClosed() {
                                passwordInput.clearFocus();
                            }

                            target: root
                        }

                    }

                }

                // Show password checkbox
                Row {
                    spacing: Theme.spacingS

                    Rectangle {
                        id: showPasswordCheckbox

                        property bool checked: false

                        width: 20
                        height: 20
                        radius: 4
                        color: checked ? Theme.primary : "transparent"
                        border.color: checked ? Theme.primary : Theme.outlineButton
                        border.width: 2

                        DankIcon {
                            anchors.centerIn: parent
                            name: "check"
                            size: 12
                            color: Theme.background
                            visible: parent.checked
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                showPasswordCheckbox.checked = !showPasswordCheckbox.checked;
                            }
                        }

                    }

                    StyledText {
                        text: "Show password"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                // Buttons
                Item {
                    width: parent.width
                    height: 40

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingM

                        Rectangle {
                            width: Math.max(70, cancelText.contentWidth + Theme.spacingM * 2)
                            height: 36
                            radius: Theme.cornerRadius
                            color: cancelArea.containsMouse ? Theme.surfaceTextHover : "transparent"
                            border.color: Theme.surfaceVariantAlpha
                            border.width: 1

                            StyledText {
                                id: cancelText

                                anchors.centerIn: parent
                                text: "Cancel"
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                id: cancelArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    wifiPasswordModalVisible = false;
                                    wifiPasswordInput = "";
                                }
                            }

                        }

                        Rectangle {
                            width: Math.max(80, connectText.contentWidth + Theme.spacingM * 2)
                            height: 36
                            radius: Theme.cornerRadius
                            color: connectArea.containsMouse ? Qt.darker(Theme.primary, 1.1) : Theme.primary
                            enabled: passwordInput.text.length > 0
                            opacity: enabled ? 1 : 0.5

                            StyledText {
                                id: connectText

                                anchors.centerIn: parent
                                text: "Connect"
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.background
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                id: connectArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: parent.enabled
                                onClicked: {
                                    NetworkService.connectToWifiWithPassword(wifiPasswordSSID, passwordInput.text);
                                    wifiPasswordModalVisible = false;
                                    wifiPasswordInput = "";
                                    passwordInput.text = "";
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

            }

        }

    }

}
