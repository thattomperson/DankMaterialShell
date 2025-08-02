import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Row {
    width: parent.width
    spacing: Theme.spacingM
    Component.onCompleted: {
        SysMonitorService.addRef();
    }
    Component.onDestruction: {
        SysMonitorService.removeRef();
    }

    Rectangle {
        width: (parent.width - Theme.spacingM * 2) / 3
        height: 80
        radius: Theme.cornerRadiusLarge
        color: {
            if (SysMonitorService.sortBy === "cpu")
                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16);
            else if (cpuCardMouseArea.containsMouse)
                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12);
            else
                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08);
        }
        border.color: SysMonitorService.sortBy === "cpu" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4) : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
        border.width: SysMonitorService.sortBy === "cpu" ? 2 : 1

        MouseArea {
            id: cpuCardMouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: SysMonitorService.setSortBy("cpu")
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacingM
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            StyledText {
                text: "CPU"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: SysMonitorService.sortBy === "cpu" ? Theme.primary : Theme.secondary
                opacity: SysMonitorService.sortBy === "cpu" ? 1 : 0.8
            }

            StyledText {
                text: SysMonitorService.totalCpuUsage.toFixed(1) + "%"
                font.pixelSize: Theme.fontSizeLarge
                font.family: Prefs.monoFontFamily
                font.weight: Font.Bold
                color: Theme.surfaceText
            }

            StyledText {
                text: SysMonitorService.cpuCount + " cores"
                font.pixelSize: Theme.fontSizeSmall
                font.family: Prefs.monoFontFamily
                color: Theme.surfaceText
                opacity: 0.7
            }

        }

        Behavior on color {
            ColorAnimation {
                duration: Theme.shortDuration
            }

        }

        Behavior on border.color {
            ColorAnimation {
                duration: Theme.shortDuration
            }

        }

    }

    Rectangle {
        width: (parent.width - Theme.spacingM * 2) / 3
        height: 80
        radius: Theme.cornerRadiusLarge
        color: {
            if (SysMonitorService.sortBy === "memory")
                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16);
            else if (memoryCardMouseArea.containsMouse)
                return Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.12);
            else
                return Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.08);
        }
        border.color: SysMonitorService.sortBy === "memory" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4) : Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.2)
        border.width: SysMonitorService.sortBy === "memory" ? 2 : 1

        MouseArea {
            id: memoryCardMouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: SysMonitorService.setSortBy("memory")
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacingM
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            StyledText {
                text: "Memory"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: SysMonitorService.sortBy === "memory" ? Theme.primary : Theme.secondary
                opacity: SysMonitorService.sortBy === "memory" ? 1 : 0.8
            }

            StyledText {
                text: SysMonitorService.formatSystemMemory(SysMonitorService.usedMemoryKB)
                font.pixelSize: Theme.fontSizeLarge
                font.family: Prefs.monoFontFamily
                font.weight: Font.Bold
                color: Theme.surfaceText
            }

            StyledText {
                text: "of " + SysMonitorService.formatSystemMemory(SysMonitorService.totalMemoryKB)
                font.pixelSize: Theme.fontSizeSmall
                font.family: Prefs.monoFontFamily
                color: Theme.surfaceText
                opacity: 0.7
            }

        }

        Behavior on color {
            ColorAnimation {
                duration: Theme.shortDuration
            }

        }

        Behavior on border.color {
            ColorAnimation {
                duration: Theme.shortDuration
            }

        }

    }

    Rectangle {
        width: (parent.width - Theme.spacingM * 2) / 3
        height: 80
        radius: Theme.cornerRadiusLarge
        color: SysMonitorService.totalSwapKB > 0 ? Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.08) : Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.04)
        border.color: SysMonitorService.totalSwapKB > 0 ? Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.2) : Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.12)
        border.width: 1

        Column {
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacingM
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            StyledText {
                text: "Swap"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: SysMonitorService.totalSwapKB > 0 ? Theme.warning : Theme.surfaceText
                opacity: 0.8
            }

            StyledText {
                text: SysMonitorService.totalSwapKB > 0 ? SysMonitorService.formatSystemMemory(SysMonitorService.usedSwapKB) : "None"
                font.pixelSize: Theme.fontSizeLarge
                font.family: Prefs.monoFontFamily
                font.weight: Font.Bold
                color: Theme.surfaceText
            }

            StyledText {
                text: SysMonitorService.totalSwapKB > 0 ? "of " + SysMonitorService.formatSystemMemory(SysMonitorService.totalSwapKB) : "No swap configured"
                font.pixelSize: Theme.fontSizeSmall
                font.family: Prefs.monoFontFamily
                color: Theme.surfaceText
                opacity: 0.7
            }

        }

    }

}
