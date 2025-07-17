import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Widgets
import qs.Common
import qs.Services

Item {
    id: bluetoothTab

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Column {
            width: parent.width
            spacing: Theme.spacingL

            Rectangle {
                width: parent.width
                height: 60
                radius: Theme.cornerRadius
                color: bluetoothToggle.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : (BluetoothService.adapter && BluetoothService.adapter.enabled ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.12))
                border.color: BluetoothService.adapter && BluetoothService.adapter.enabled ? Theme.primary : "transparent"
                border.width: 2

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingL
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingM

                    Text {
                        text: "bluetooth"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.iconSizeLarge
                        color: BluetoothService.adapter && BluetoothService.adapter.enabled ? Theme.primary : Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "Bluetooth"
                            font.pixelSize: Theme.fontSizeLarge
                            color: BluetoothService.adapter && BluetoothService.adapter.enabled ? Theme.primary : Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        Text {
                            text: BluetoothService.adapter && BluetoothService.adapter.enabled ? "Enabled" : "Disabled"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                        }

                    }

                }

                MouseArea {
                    id: bluetoothToggle

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        BluetoothService.toggleAdapter();
                    }
                }

            }

            Column {
                width: parent.width
                spacing: Theme.spacingM
                visible: BluetoothService.adapter && BluetoothService.adapter.enabled

                Text {
                    text: "Paired Devices"
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.surfaceText
                    font.weight: Font.Medium
                }

                Repeater {
                    model: BluetoothService.adapter && BluetoothService.adapter.devices ? BluetoothService.adapter.devices.values.filter((dev) => {
                        return dev && dev.paired && BluetoothService.isValidDevice(dev);
                    }) : []

                    Rectangle {
                        width: parent.width
                        height: 60
                        radius: Theme.cornerRadius
                        color: btDeviceArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : (modelData.connected ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08))
                        border.color: modelData.connected ? Theme.primary : "transparent"
                        border.width: 1

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingM

                            Text {
                                text: BluetoothService.getDeviceIcon(modelData)
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.iconSize
                                color: modelData.connected ? Theme.primary : Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                spacing: 2
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: modelData.name || modelData.deviceName
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: modelData.connected ? Theme.primary : Theme.surfaceText
                                    font.weight: modelData.connected ? Font.Medium : Font.Normal
                                }

                                Row {
                                    spacing: Theme.spacingXS

                                    Text {
                                        text: modelData.connected ? "Connected" : "Disconnected"
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                                    }

                                    Text {
                                        text: {
                                            if (modelData.batteryAvailable && modelData.battery > 0)
                                                return "• " + Math.round(modelData.battery * 100) + "%";

                                            var btBattery = BatteryService.bluetoothDevices.find((dev) => {
                                                return dev.name === (modelData.name || modelData.deviceName) || dev.name.toLowerCase().includes((modelData.name || modelData.deviceName).toLowerCase()) || (modelData.name || modelData.deviceName).toLowerCase().includes(dev.name.toLowerCase());
                                            });
                                            return btBattery ? "• " + btBattery.percentage + "%" : "";
                                        }
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                                        visible: text.length > 0
                                    }

                                }

                            }

                        }

                        Rectangle {
                            id: btMenuButton

                            width: 32
                            height: 32
                            radius: Theme.cornerRadius
                            color: btMenuButtonArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "more_vert"
                                font.family: Theme.iconFont
                                font.weight: Theme.iconFontWeight
                                font.pixelSize: Theme.iconSize
                                color: Theme.surfaceText
                                opacity: 0.6
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: btMenuButtonArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    bluetoothContextMenuWindow.deviceData = modelData;
                                    let localPos = btMenuButtonArea.mapToItem(bluetoothTab, btMenuButtonArea.width / 2, btMenuButtonArea.height);
                                    bluetoothContextMenuWindow.show(localPos.x, localPos.y);
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.shortDuration
                                }

                            }

                        }

                        MouseArea {
                            id: btDeviceArea

                            anchors.fill: parent
                            anchors.rightMargin: 40
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                BluetoothService.debugDevice(modelData);
                                BluetoothService.toggle(modelData.address);
                            }
                        }

                    }

                }

            }

            Column {
                width: parent.width
                spacing: Theme.spacingM
                visible: BluetoothService.adapter && BluetoothService.adapter.enabled

                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    Text {
                        text: "Available Devices"
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        width: 1
                        height: 1
                    }

                    Rectangle {
                        width: Math.max(140, scanText.contentWidth + Theme.spacingL * 2)
                        height: 36
                        radius: Theme.cornerRadius
                        color: scanArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
                        border.color: Theme.primary
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            Text {
                                text: BluetoothService.adapter && BluetoothService.adapter.discovering ? "stop" : "bluetooth_searching"
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.iconSize - 4
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                id: scanText

                                text: BluetoothService.adapter && BluetoothService.adapter.discovering ? "Stop Scanning" : "Start Scanning"
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.primary
                                font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                            }

                        }

                        MouseArea {
                            id: scanArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (BluetoothService.adapter && BluetoothService.adapter.discovering)
                                    BluetoothService.stopScan();
                                else
                                    BluetoothService.startScan();
                            }
                        }

                    }

                }

                Repeater {
                    model: BluetoothService.availableDevices

                    Rectangle {
                        property bool canPair: BluetoothService.canPair(modelData)
                        property string pairingStatus: BluetoothService.getPairingStatus(modelData)

                        width: parent.width
                        height: 70
                        radius: Theme.cornerRadius
                        color: {
                            if (availableDeviceArea.containsMouse)
                                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08);

                            if (modelData.pairing)
                                return Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.12);

                            if (modelData.blocked)
                                return Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.08);

                            return Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08);
                        }
                        border.color: {
                            if (modelData.pairing)
                                return Theme.warning;

                            if (modelData.blocked)
                                return Theme.error;

                            return Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2);
                        }
                        border.width: 1

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingM

                            Text {
                                text: BluetoothService.getDeviceIcon(modelData)
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.iconSize
                                color: {
                                    if (modelData.pairing)
                                        return Theme.warning;

                                    if (modelData.blocked)
                                        return Theme.error;

                                    return Theme.surfaceText;
                                }
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                spacing: 2
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: modelData.name || modelData.deviceName
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: {
                                        if (modelData.pairing)
                                            return Theme.warning;

                                        if (modelData.blocked)
                                            return Theme.error;

                                        return Theme.surfaceText;
                                    }
                                    font.weight: modelData.pairing ? Font.Medium : Font.Normal
                                }

                                Row {
                                    spacing: Theme.spacingXS

                                    Row {
                                        spacing: Theme.spacingS

                                        Text {
                                            text: {
                                                switch (pairingStatus) {
                                                case "pairing":
                                                    return "Pairing...";
                                                case "blocked":
                                                    return "Blocked";
                                                default:
                                                    return BluetoothService.getSignalStrength(modelData);
                                                }
                                            }
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: {
                                                if (modelData.pairing)
                                                    return Theme.warning;

                                                if (modelData.blocked)
                                                    return Theme.error;

                                                return Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7);
                                            }
                                        }

                                        Text {
                                            text: BluetoothService.getSignalIcon(modelData)
                                            font.family: Theme.iconFont
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                                            visible: modelData.rssi !== undefined && modelData.rssi !== 0 && pairingStatus === "available"
                                        }

                                        Text {
                                            text: (modelData.rssi !== undefined && modelData.rssi !== 0) ? modelData.rssi + "dBm" : ""
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.5)
                                            visible: modelData.rssi !== undefined && modelData.rssi !== 0 && pairingStatus === "available"
                                        }

                                    }

                                }

                            }

                        }

                        Rectangle {
                            width: 80
                            height: 28
                            radius: Theme.cornerRadiusSmall
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            color: {
                                if (!canPair && !modelData.pairing)
                                    return Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3);

                                if (actionButtonArea.containsMouse)
                                    return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12);

                                return "transparent";
                            }
                            border.color: canPair || modelData.pairing ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                            border.width: 1
                            opacity: canPair || modelData.pairing ? 1 : 0.5

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (modelData.pairing)
                                        return "Pairing...";

                                    if (modelData.blocked)
                                        return "Blocked";

                                    return "Pair";
                                }
                                font.pixelSize: Theme.fontSizeSmall
                                color: canPair || modelData.pairing ? Theme.primary : Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.5)
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                id: actionButtonArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: canPair ? Qt.PointingHandCursor : Qt.ArrowCursor
                                enabled: canPair
                                onClicked: {
                                    if (canPair)
                                        BluetoothService.pair(modelData.address);

                                }
                            }

                        }

                        MouseArea {
                            id: availableDeviceArea

                            anchors.fill: parent
                            anchors.rightMargin: 90 // Don't overlap with action button
                            hoverEnabled: true
                            cursorShape: canPair ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: canPair
                            onClicked: {
                                if (canPair)
                                    BluetoothService.pair(modelData.address);

                            }
                        }

                    }

                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingM
                    visible: BluetoothService.adapter && BluetoothService.adapter.discovering && BluetoothService.availableDevices.length === 0

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.spacingM

                        Text {
                            text: "sync"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.iconSizeLarge
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter

                            RotationAnimation on rotation {
                                running: true
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 2000
                            }

                        }

                        Text {
                            text: "Scanning for devices..."
                            font.pixelSize: Theme.fontSizeLarge
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }

                    }

                    Text {
                        text: "Make sure your device is in pairing mode"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                }

                Text {
                    text: "No devices found. Put your device in pairing mode and click Start Scanning."
                    font.pixelSize: Theme.fontSizeMedium
                    color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                    visible: BluetoothService.availableDevices.length === 0 && (!BluetoothService.adapter || !BluetoothService.adapter.discovering)
                    wrapMode: Text.WordWrap
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                }

            }

        }

    }

    Rectangle {
        id: bluetoothContextMenuWindow

        property var deviceData: null
        property bool menuVisible: false

        function show(x, y) {
            const menuWidth = 160;
            const menuHeight = menuColumn.implicitHeight + Theme.spacingS * 2;
            let finalX = x - menuWidth / 2;
            let finalY = y;
            finalX = Math.max(0, Math.min(finalX, bluetoothTab.width - menuWidth));
            finalY = Math.max(0, Math.min(finalY, bluetoothTab.height - menuHeight));
            bluetoothContextMenuWindow.x = finalX;
            bluetoothContextMenuWindow.y = finalY;
            bluetoothContextMenuWindow.visible = true;
            bluetoothContextMenuWindow.menuVisible = true;
        }

        function hide() {
            bluetoothContextMenuWindow.menuVisible = false;
            Qt.callLater(() => {
                bluetoothContextMenuWindow.visible = false;
            });
        }

        visible: false
        width: 160
        height: menuColumn.implicitHeight + Theme.spacingS * 2
        radius: Theme.cornerRadiusLarge
        color: Theme.popupBackground()
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
        border.width: 1
        z: 1000
        opacity: menuVisible ? 1 : 0
        scale: menuVisible ? 1 : 0.85

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.leftMargin: 2
            anchors.rightMargin: -2
            anchors.bottomMargin: -4
            radius: parent.radius
            color: Qt.rgba(0, 0, 0, 0.15)
            z: parent.z - 1
        }

        Column {
            id: menuColumn

            anchors.fill: parent
            anchors.margins: Theme.spacingS
            spacing: 1

            Rectangle {
                width: parent.width
                height: 32
                radius: Theme.cornerRadiusSmall
                color: connectArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingS

                    Text {
                        text: bluetoothContextMenuWindow.deviceData && bluetoothContextMenuWindow.deviceData.connected ? "link_off" : "link"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.iconSize - 2
                        color: Theme.surfaceText
                        opacity: 0.7
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: bluetoothContextMenuWindow.deviceData && bluetoothContextMenuWindow.deviceData.connected ? "Disconnect" : "Connect"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceText
                        font.weight: Font.Normal
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                MouseArea {
                    id: connectArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (bluetoothContextMenuWindow.deviceData)
                            BluetoothService.toggle(bluetoothContextMenuWindow.deviceData.address);

                        bluetoothContextMenuWindow.hide();
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }

                }

            }

            Rectangle {
                width: parent.width - Theme.spacingS * 2
                height: 5
                anchors.horizontalCenter: parent.horizontalCenter
                color: "transparent"

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: 1
                    color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                }

            }

            Rectangle {
                width: parent.width
                height: 32
                radius: Theme.cornerRadiusSmall
                color: forgetArea.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : "transparent"

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingS

                    Text {
                        text: "delete"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.iconSize - 2
                        color: forgetArea.containsMouse ? Theme.error : Theme.surfaceText
                        opacity: 0.7
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Forget Device"
                        font.pixelSize: Theme.fontSizeSmall
                        color: forgetArea.containsMouse ? Theme.error : Theme.surfaceText
                        font.weight: Font.Normal
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                MouseArea {
                    id: forgetArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (bluetoothContextMenuWindow.deviceData)
                            BluetoothService.forget(bluetoothContextMenuWindow.deviceData.address);

                        bluetoothContextMenuWindow.hide();
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

    MouseArea {
        anchors.fill: parent
        visible: bluetoothContextMenuWindow.visible
        onClicked: {
            bluetoothContextMenuWindow.hide();
        }

        MouseArea {
            x: bluetoothContextMenuWindow.x
            y: bluetoothContextMenuWindow.y
            width: bluetoothContextMenuWindow.width
            height: bluetoothContextMenuWindow.height
            onClicked: {
            }
        }

    }

}
