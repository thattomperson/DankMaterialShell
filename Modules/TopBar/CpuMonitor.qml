import "."
import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    property bool showPercentage: true
    property bool showIcon: true
    property var toggleProcessList

    width: 55
    height: 30
    radius: Theme.cornerRadius
    color: cpuArea.containsMouse ? Theme.primaryPressed : Theme.secondaryHover
    Component.onCompleted: {
        SysMonitorService.addRef();
    }
    Component.onDestruction: {
        SysMonitorService.removeRef();
    }

    MouseArea {
        id: cpuArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            SysMonitorService.setSortBy("cpu");
            if (root.toggleProcessList)
                root.toggleProcessList();

        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 3

        DankIcon {
            name: "memory"
            size: Theme.iconSize - 8
            color: {
                if (SysMonitorService.cpuUsage > 80)
                    return Theme.error;

                if (SysMonitorService.cpuUsage > 60)
                    return Theme.warning;

                return Theme.surfaceText;
            }
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: (SysMonitorService.cpuUsage || 0).toFixed(0) + "%"
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter
        }

    }

}
