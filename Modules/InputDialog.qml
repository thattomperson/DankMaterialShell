import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets

DankModal {
    id: inputDialog

    property bool dialogVisible: false
    property string dialogTitle: "Input Required"
    property string dialogSubtitle: "Please enter the required information"
    property string inputPlaceholder: "Enter text"
    property string inputValue: ""
    property bool isPassword: false
    property string confirmButtonText: "Confirm"
    property string cancelButtonText: "Cancel"

    signal confirmed(string value)
    signal cancelled()

    function showDialog(title, subtitle, placeholder, isPass, confirmText, cancelText) {
        dialogTitle = title || "Input Required";
        dialogSubtitle = subtitle || "Please enter the required information";
        inputPlaceholder = placeholder || "Enter text";
        isPassword = isPass || false;
        confirmButtonText = confirmText || "Confirm";
        cancelButtonText = cancelText || "Cancel";
        inputValue = "";
        dialogVisible = true;
    }

    function hideDialog() {
        textInput.enabled = false; // Disable before hiding to prevent Wayland warnings
        dialogVisible = false;
        inputValue = "";
    }

    visible: dialogVisible
    width: 380
    height: 190
    keyboardFocus: "ondemand"

    onOpened: {
        textInput.forceActiveFocus()
    }

    onVisibleChanged: {
        if (visible) {
            textInput.enabled = true;
        } else {
            textInput.enabled = false;
        }
    }

    onBackgroundClicked: {
        hideDialog();
        cancelled();
    }

    content: Component {
        Column {
            anchors.centerIn: parent
            width: parent.width - Theme.spacingM * 2
            spacing: Theme.spacingM

            Text {
                text: dialogTitle
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.surfaceText
                font.weight: Font.Medium
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: dialogSubtitle
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
                wrapMode: Text.WordWrap
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }

            DankTextField {
                id: textInput
                width: parent.width
                placeholderText: inputPlaceholder
                text: inputValue
                echoMode: isPassword ? TextInput.Password : TextInput.Normal
                onTextChanged: inputValue = text
                onAccepted: {
                    hideDialog();
                    confirmed(text);
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingM

                Rectangle {
                    width: 120
                    height: 40
                    radius: Theme.cornerRadius
                    color: cancelButton.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)

                    Text {
                        text: cancelButtonText
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
                            hideDialog();
                            cancelled();
                        }
                    }
                }

                Rectangle {
                    width: 120
                    height: 40
                    radius: Theme.cornerRadius
                    color: confirmButton.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.9) : Theme.primary

                    Text {
                        text: confirmButtonText
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
                            hideDialog();
                            confirmed(textInput.text);
                        }
                    }
                }
            }
        }
    }
}