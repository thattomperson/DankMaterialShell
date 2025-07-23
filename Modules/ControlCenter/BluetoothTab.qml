import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets

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

                    DankIcon {
                        name: "bluetooth"
                        size: Theme.iconSizeLarge
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
                        if (BluetoothService.adapter) {
                            BluetoothService.adapter.enabled = !BluetoothService.adapter.enabled;
                        }
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
                        return dev && (dev.paired || dev.trusted);
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

                            DankIcon {
                                name: BluetoothService.getDeviceIcon(modelData)
                                size: Theme.iconSize
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
                                        text: BluetoothDeviceState.toString(modelData.state)
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

                            DankIcon {
                                name: "more_vert"
                                size: Theme.iconSize
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
                            enabled: !BluetoothService.isDeviceBusy(modelData)
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.BusyCursor
                            onClicked: {
                                if (modelData.connected) {
                                    modelData.disconnect();
                                } else {
                                    BluetoothService.connectDeviceWithTrust(modelData);
                                }
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

                            DankIcon {
                                name: BluetoothService.adapter && BluetoothService.adapter.discovering ? "stop" : "bluetooth_searching"
                                size: Theme.iconSize - 4
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
                                if (BluetoothService.adapter) {
                                    BluetoothService.adapter.discovering = !BluetoothService.adapter.discovering;
                                }
                            }
                        }

                    }

                }

                Rectangle {
                    width: parent.width
                    height: noteColumn.implicitHeight + Theme.spacingM * 2
                    radius: Theme.cornerRadius
                    color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.08)
                    border.color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.2)
                    border.width: 1

                    Column {
                        id: noteColumn
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingS

                        Row {
                            width: parent.width
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "info"
                                size: Theme.iconSize - 2
                                color: Theme.warning
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "Pairing Limitation"
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.warning
                                font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            text: "Quickshell does not support pairing devices that require pin or confirmation."
                            font.pixelSize: Theme.fontSizeSmall
                            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.8)
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                    }
                }

                Repeater {
                    model: {
                        if (!BluetoothService.adapter || !BluetoothService.adapter.discovering || !Bluetooth.devices)
                            return [];
                        
                        var filtered = Bluetooth.devices.values.filter((dev) => {
                            return dev && !dev.paired && !dev.pairing && !dev.blocked && (dev.signalStrength === undefined || dev.signalStrength > 0);
                        });
                        return BluetoothService.sortDevices(filtered);
                    }

                    Rectangle {
                        property bool canConnect: BluetoothService.canConnect(modelData)
                        property bool isBusy: BluetoothService.isDeviceBusy(modelData)

                        width: parent.width
                        height: 70
                        radius: Theme.cornerRadius
                        color: {
                            if (availableDeviceArea.containsMouse && !isBusy)
                                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08);

                            if (modelData.pairing || modelData.state === BluetoothDeviceState.Connecting)
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

                            DankIcon {
                                name: BluetoothService.getDeviceIcon(modelData)
                                size: Theme.iconSize
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
                                                if (modelData.pairing)
                                                    return "Pairing...";
                                                if (modelData.blocked)
                                                    return "Blocked";
                                                return BluetoothService.getSignalStrength(modelData);
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

                                        DankIcon {
                                            name: BluetoothService.getSignalIcon(modelData)
                                            size: Theme.fontSizeSmall
                                            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                                            visible: modelData.signalStrength !== undefined && modelData.signalStrength > 0 && !modelData.pairing && !modelData.blocked
                                        }

                                        Text {
                                            text: (modelData.signalStrength !== undefined && modelData.signalStrength > 0) ? modelData.signalStrength + "%" : ""
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.5)
                                            visible: modelData.signalStrength !== undefined && modelData.signalStrength > 0 && !modelData.pairing && !modelData.blocked
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
                            visible: modelData.state !== BluetoothDeviceState.Connecting
                            color: {
                                if (!canConnect && !isBusy)
                                    return Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3);

                                if (actionButtonArea.containsMouse && !isBusy)
                                    return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12);

                                return "transparent";
                            }
                            border.color: canConnect || isBusy ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                            border.width: 1
                            opacity: canConnect || isBusy ? 1 : 0.5

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (modelData.pairing)
                                        return "Pairing...";

                                    if (modelData.blocked)
                                        return "Blocked";

                                    return "Connect";
                                }
                                font.pixelSize: Theme.fontSizeSmall
                                color: canConnect || isBusy ? Theme.primary : Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.5)
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                id: actionButtonArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: canConnect && !isBusy ? Qt.PointingHandCursor : (isBusy ? Qt.BusyCursor : Qt.ArrowCursor)
                                enabled: canConnect && !isBusy
                                onClicked: {
                                    if (modelData) {
                                        BluetoothService.connectDeviceWithTrust(modelData);
                                    }
                                }
                            }

                        }

                        MouseArea {
                            id: availableDeviceArea

                            anchors.fill: parent
                            anchors.rightMargin: 90 // Don't overlap with action button
                            hoverEnabled: true
                            cursorShape: canConnect && !isBusy ? Qt.PointingHandCursor : (isBusy ? Qt.BusyCursor : Qt.ArrowCursor)
                            enabled: canConnect && !isBusy
                            onClicked: {
                                if (modelData) {
                                    BluetoothService.connectDeviceWithTrust(modelData);
                                }
                            }
                        }

                    }

                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingM
                    visible: {
                        if (!BluetoothService.adapter || !BluetoothService.adapter.discovering || !Bluetooth.devices)
                            return false;
                        
                        var availableCount = Bluetooth.devices.values.filter((dev) => {
                            return dev && !dev.paired && !dev.pairing && !dev.blocked && (dev.signalStrength === undefined || dev.signalStrength > 0);
                        }).length;
                        
                        return availableCount === 0;
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "sync"
                            size: Theme.iconSizeLarge
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
                    visible: {
                        if (!BluetoothService.adapter || !Bluetooth.devices)
                            return true;
                        
                        var availableCount = Bluetooth.devices.values.filter((dev) => {
                            return dev && !dev.paired && !dev.pairing && !dev.blocked && (dev.signalStrength === undefined || dev.signalStrength > 0);
                        }).length;
                        
                        return availableCount === 0 && !BluetoothService.adapter.discovering;
                    }
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

                    DankIcon {
                        name: bluetoothContextMenuWindow.deviceData && bluetoothContextMenuWindow.deviceData.connected ? "link_off" : "link"
                        size: Theme.iconSize - 2
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
                        if (bluetoothContextMenuWindow.deviceData) {
                            if (bluetoothContextMenuWindow.deviceData.connected) {
                                bluetoothContextMenuWindow.deviceData.disconnect();
                            } else {
                                BluetoothService.connectDeviceWithTrust(bluetoothContextMenuWindow.deviceData);
                            }
                        }
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

                    DankIcon {
                        name: "delete"
                        size: Theme.iconSize - 2
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
                        if (bluetoothContextMenuWindow.deviceData) {
                            bluetoothContextMenuWindow.deviceData.forget();
                        }
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
