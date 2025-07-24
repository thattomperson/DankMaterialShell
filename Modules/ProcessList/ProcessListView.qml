import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services

Column {
    id: root
    property var contextMenu: null

    Component.onCompleted: {
        SysMonitorService.addRef();
    }

    Component.onDestruction: {
        SysMonitorService.removeRef();
    }

    Item {
        id: columnHeaders

        width: parent.width
        anchors.leftMargin: 8
        height: 24

        Rectangle {
            width: 60
            height: 20
            color: processHeaderArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"
            radius: Theme.cornerRadius
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.verticalCenter: parent.verticalCenter
            
            Text {
                text: "Process"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: SysMonitorService.sortBy === "name" ? Font.Bold : Font.Medium
                color: Theme.surfaceText
                opacity: SysMonitorService.sortBy === "name" ? 1.0 : 0.7
                anchors.centerIn: parent
            }
            
            MouseArea {
                id: processHeaderArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: SysMonitorService.setSortBy("name")
            }
            
            Behavior on color {
                ColorAnimation { duration: Theme.shortDuration }
            }
        }

        Rectangle {
            width: 80
            height: 20
            color: cpuHeaderArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"
            radius: Theme.cornerRadius
            anchors.right: parent.right
            anchors.rightMargin: 200
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: "CPU"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: SysMonitorService.sortBy === "cpu" ? Font.Bold : Font.Medium
                color: Theme.surfaceText
                opacity: SysMonitorService.sortBy === "cpu" ? 1.0 : 0.7
                anchors.centerIn: parent
            }
            
            MouseArea {
                id: cpuHeaderArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: SysMonitorService.setSortBy("cpu")
            }
            
            Behavior on color {
                ColorAnimation { duration: Theme.shortDuration }
            }
        }

        Rectangle {
            width: 80
            height: 20
            color: memoryHeaderArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"
            radius: Theme.cornerRadius
            anchors.right: parent.right
            anchors.rightMargin: 112
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: "RAM"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: SysMonitorService.sortBy === "memory" ? Font.Bold : Font.Medium
                color: Theme.surfaceText
                opacity: SysMonitorService.sortBy === "memory" ? 1.0 : 0.7
                anchors.centerIn: parent
            }
            
            MouseArea {
                id: memoryHeaderArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: SysMonitorService.setSortBy("memory")
            }
            
            Behavior on color {
                ColorAnimation { duration: Theme.shortDuration }
            }
        }

        Rectangle {
            width: 50
            height: 20
            color: pidHeaderArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"
            radius: Theme.cornerRadius
            anchors.right: parent.right
            anchors.rightMargin: 53
            anchors.verticalCenter: parent.verticalCenter
            
            Text {
                text: "PID"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: SysMonitorService.sortBy === "pid" ? Font.Bold : Font.Medium
                color: Theme.surfaceText
                opacity: SysMonitorService.sortBy === "pid" ? 1.0 : 0.7
                horizontalAlignment: Text.AlignHCenter
                anchors.centerIn: parent
            }
            
            MouseArea {
                id: pidHeaderArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: SysMonitorService.setSortBy("pid")
            }
            
            Behavior on color {
                ColorAnimation { duration: Theme.shortDuration }
            }
        }

        Rectangle {
            width: 28
            height: 28
            radius: Theme.cornerRadius
            color: sortOrderArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: SysMonitorService.sortDescending ? "↓" : "↑"
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                anchors.centerIn: parent
            }

            MouseArea {
                id: sortOrderArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: SysMonitorService.toggleSortOrder()
            }

            Behavior on color {
                ColorAnimation {
                    duration: Theme.shortDuration
                }

            }

        }

    }

    ScrollView {
        width: parent.width
        height: parent.height - 24 // Subtract header height
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ListView {
            id: processListView

            anchors.fill: parent
            model: SysMonitorService.processes
            spacing: 4

            delegate: ProcessListItem {
                process: modelData
                contextMenu: root.contextMenu
            }
        }
    }
}