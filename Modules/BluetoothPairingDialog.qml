import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Bluetooth
import qs.Common
import qs.Services
import qs.Widgets

PanelWindow {
    id: root

    property bool bluetoothPairingDialogVisible: BluetoothService.pairingDialogVisible
    property int pairingType: BluetoothService.pairingType
    property int passkey: BluetoothService.pendingPasskey
    property string deviceAddress: BluetoothService.pendingDeviceAddress
    property alias inputText: pairingInput.text

    visible: bluetoothPairingDialogVisible
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: bluetoothPairingDialogVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    onVisibleChanged: {
        if (visible) {
            console.log("BluetoothPairingDialog: Showing dialog for device:", deviceAddress, "name:", BluetoothService.pendingDeviceName, "type:", pairingType);
            pairingInput.enabled = true;
            BluetoothService.inputText = "";
            Qt.callLater(function() {
                if (pairingType === BluetoothPairingRequestType.PinCode || pairingType === BluetoothPairingRequestType.Passkey)
                    pairingInput.forceActiveFocus();

            });
        } else {
            pairingInput.enabled = false;
        }
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        opacity: bluetoothPairingDialogVisible ? 1 : 0

        MouseArea {
            anchors.fill: parent
            onClicked: {
                pairingInput.enabled = false;
                BluetoothService.rejectPairing();
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.standardEasing
            }

        }

    }

    Rectangle {
        width: Math.min(400, parent.width - Theme.spacingL * 2)
        height: Math.min(contentColumn.implicitHeight + Theme.spacingL * 2, parent.height - Theme.spacingL * 2)
        anchors.centerIn: parent
        color: Theme.surfaceContainer
        radius: Theme.cornerRadiusLarge
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
        border.width: 1
        opacity: bluetoothPairingDialogVisible ? 1 : 0
        scale: bluetoothPairingDialogVisible ? 1 : 0.9

        MouseArea {
            // Prevent propagation to background

            anchors.fill: parent
            onClicked: {
            }
        }

        Column {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingL

            // Header
            Row {
                width: parent.width
                spacing: Theme.spacingM

                DankIcon {
                    name: "bluetooth"
                    size: Theme.iconSize
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    width: parent.width - 40 - Theme.spacingM - Theme.iconSize
                    spacing: Theme.spacingXS
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "Bluetooth Pairing"
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                    }

                    Text {
                        text: BluetoothService.pendingDeviceName || deviceAddress || "Unknown Device"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                        width: parent.width
                        elide: Text.ElideRight
                    }

                    Text {
                        text: deviceAddress || ""
                        font.pixelSize: Theme.fontSizeSmall
                        color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.5)
                        font.family: "monospace"
                        visible: deviceAddress && deviceAddress !== BluetoothService.pendingDeviceName
                    }

                }

                DankActionButton {
                    iconName: "close"
                    iconSize: Theme.iconSize - 4
                    iconColor: Theme.surfaceText
                    hoverColor: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12)
                    onClicked: {
                        pairingInput.enabled = false;
                        BluetoothService.rejectPairing();
                    }
                }

            }

            // Dynamic content based on pairing type
            Column {
                width: parent.width
                spacing: Theme.spacingM

                // Authorization
                Text {
                    text: "Allow pairing with this device?"
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.surfaceText
                    font.weight: Font.Medium
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: pairingType === BluetoothPairingRequestType.Authorization
                }

                // Service Authorization
                Text {
                    text: "Allow service connection from this device?"
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.surfaceText
                    font.weight: Font.Medium
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: pairingType === BluetoothPairingRequestType.ServiceAuthorization
                }

                // Confirmation
                Rectangle {
                    width: parent.width
                    height: 80
                    radius: Theme.cornerRadius
                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
                    border.color: Theme.primary
                    border.width: 1
                    visible: pairingType === BluetoothPairingRequestType.Confirmation

                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.spacingS

                        Text {
                            text: "Confirm this passkey matches on both devices:"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: passkey.toString().padStart(6, '0')
                            font.pixelSize: Theme.fontSizeXXLarge
                            color: Theme.primary
                            font.weight: Font.Bold
                            font.family: "monospace"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                    }

                }

                // PIN Code or Passkey Input
                Column {
                    width: parent.width
                    spacing: Theme.spacingS
                    visible: pairingType === BluetoothPairingRequestType.PinCode || pairingType === BluetoothPairingRequestType.Passkey

                    Text {
                        text: pairingType === BluetoothPairingRequestType.PinCode ? "Enter PIN code for this device:" : "Enter 6-digit passkey shown on other device:"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Rectangle {
                        width: parent.width
                        height: 50
                        radius: Theme.cornerRadius
                        color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08)
                        border.color: pairingInput.activeFocus ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                        border.width: pairingInput.activeFocus ? 2 : 1

                        DankTextField {
                            id: pairingInput

                            anchors.fill: parent
                            font.pixelSize: Theme.fontSizeLarge
                            textColor: Theme.surfaceText
                            text: BluetoothService.inputText
                            enabled: bluetoothPairingDialogVisible
                            placeholderText: pairingType === BluetoothPairingRequestType.PinCode ? "e.g., 0000 or 1234" : "123456"
                            backgroundColor: "transparent"
                            normalBorderColor: "transparent"
                            focusedBorderColor: "transparent"
                            inputMethodHints: pairingType === BluetoothPairingRequestType.Passkey ? Qt.ImhDigitsOnly : Qt.ImhNone
                            onTextEdited: {
                                // For passkey, limit to 6 digits only
                                if (pairingType === BluetoothPairingRequestType.Passkey) {
                                    var filtered = text.replace(/[^0-9]/g, '').substring(0, 6);
                                    if (text !== filtered) {
                                        text = filtered;
                                        return ;
                                    }
                                }
                                BluetoothService.inputText = text;
                            }
                            onAccepted: {
                                if (text.length > 0)
                                    BluetoothService.acceptPairing();

                            }
                        }

                    }

                }

            }

            // Buttons
            Row {
                width: parent.width
                spacing: Theme.spacingM

                Rectangle {
                    width: (parent.width - Theme.spacingM) / 2
                    height: 40
                    radius: Theme.cornerRadius
                    color: rejectArea.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08)
                    border.color: Theme.error
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.error
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: rejectArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothService.rejectPairing()
                    }

                }

                Rectangle {
                    width: (parent.width - Theme.spacingM) / 2
                    height: 40
                    radius: Theme.cornerRadius
                    color: acceptArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16) : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                    border.color: Theme.primary
                    border.width: 1
                    opacity: {
                        // Authorization/Confirmation/ServiceAuthorization always enabled
                        if (pairingType <= BluetoothPairingRequestType.Confirmation || pairingType === BluetoothPairingRequestType.ServiceAuthorization)
                            return 1;

                        // PIN/Passkey need input
                        return BluetoothService.inputText.length > 0 ? 1 : 0.5;
                    }

                    Text {
                        anchors.centerIn: parent
                        text: {
                            switch (pairingType) {
                            case BluetoothPairingRequestType.Authorization:
                                return "Accept";
                            case BluetoothPairingRequestType.Confirmation:
                                return "Confirm";
                            case BluetoothPairingRequestType.ServiceAuthorization:
                                return "Allow";
                            case BluetoothPairingRequestType.PinCode:
                                return "Pair";
                            case BluetoothPairingRequestType.Passkey:
                                return "Enter";
                            default:
                                return "OK";
                            }
                        }
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.primary
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: acceptArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: pairingType <= BluetoothPairingRequestType.Confirmation || pairingType === BluetoothPairingRequestType.ServiceAuthorization || BluetoothService.inputText.length > 0
                        onClicked: BluetoothService.acceptPairing()
                    }

                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
            }

        }

    }

}
