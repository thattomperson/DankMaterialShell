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
    color: ramArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16) : Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.08)

    Component.onCompleted: {
        SysMonitorService.addRef();
    }

    Component.onDestruction: {
        SysMonitorService.removeRef();
    }

    MouseArea {
        id: ramArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            SysMonitorService.setSortBy("memory");
            if (root.toggleProcessList)
                root.toggleProcessList();
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 3

        DankIcon {
            name: "developer_board"
            size: Theme.iconSize - 8
            color: {
                if (SysMonitorService.memoryUsage > 90)
                    return Theme.error;

                if (SysMonitorService.memoryUsage > 75)
                    return Theme.warning;

                return Theme.surfaceText;
            }
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: (SysMonitorService.memoryUsage || 0).toFixed(0) + "%"
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter
        }

    }

}
