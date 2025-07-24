import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services
import qs.Widgets

ScrollView {
    anchors.fill: parent
    clip: true
    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    Component.onCompleted: {
        SysMonitorService.addRef();
    }

    Component.onDestruction: {
        SysMonitorService.removeRef();
    }

    Column {
        width: parent.width
        spacing: Theme.spacingM

        Rectangle {
            width: parent.width
            height: systemInfoColumn.implicitHeight + 2 * Theme.spacingL
            radius: Theme.cornerRadiusLarge
            color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.6)
            border.width: 0

            Column {
                id: systemInfoColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingL

                Row {
                    width: parent.width
                    spacing: Theme.spacingL

                    SystemLogo {
                        width: 80
                        height: 80
                    }

                    Column {
                        width: parent.width - 80 - Theme.spacingL
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingS

                        Text {
                            text: SysMonitorService.hostname
                            font.pixelSize: Theme.fontSizeXLarge
                            font.weight: Font.Light
                            color: Theme.surfaceText
                        }

                        Text {
                            text: SysMonitorService.distribution + " • " + SysMonitorService.architecture + " • " + SysMonitorService.kernelVersion
                            font.pixelSize: Theme.fontSizeMedium
                            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                        }

                        Text {
                            text: "Up " + UserInfoService.uptime + " • Boot: " + SysMonitorService.bootTime
                            font.pixelSize: Theme.fontSizeSmall
                            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.6)
                        }

                        Text {
                            text: "Load: " + SysMonitorService.loadAverage + " • " + SysMonitorService.processCount + " processes, " + SysMonitorService.threadCount + " threads"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.6)
                        }

                    }

                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingXL

                    Column {
                        width: (parent.width - Theme.spacingXL) / 2
                        spacing: Theme.spacingS

                        Text {
                            text: SysMonitorService.cpuModel
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            width: parent.width
                            elide: Text.ElideRight
                        }

                        Text {
                            text: SysMonitorService.motherboard
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            width: parent.width
                            elide: Text.ElideRight
                        }

                    }

                    Column {
                        width: (parent.width - Theme.spacingXL) / 2
                        spacing: Theme.spacingS

                        Text {
                            text: SysMonitorService.formatMemory(SysMonitorService.totalMemoryMB) + " Memory"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            width: parent.width
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "BIOS " + SysMonitorService.biosVersion
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            width: parent.width
                            elide: Text.ElideRight
                        }

                    }

                }

            }

        }


        Rectangle {
            width: parent.width
            height: storageColumn.implicitHeight + 2 * Theme.spacingL
            radius: Theme.cornerRadiusLarge
            color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.6)
            border.width: 0

            Column {
                id: storageColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingS

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    DankIcon {
                        name: "storage"
                        size: Theme.iconSize
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Storage & Disks"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Bold
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }


                Column {
                    width: parent.width
                    spacing: 2

                        Row {
                            width: parent.width
                            height: 24
                            spacing: Theme.spacingS

                            Text {
                                text: "Device"
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                                width: parent.width * 0.25
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "Mount"
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                                width: parent.width * 0.2
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "Size"
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                                width: parent.width * 0.15
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "Used"
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                                width: parent.width * 0.15
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "Available"
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                                width: parent.width * 0.15
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "Use%"
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                                width: parent.width * 0.1
                                elide: Text.ElideRight
                            }

                        }

                        Repeater {
                            id: diskMountRepeater

                            model: SysMonitorService.diskMounts

                            Rectangle {
                                width: parent.width
                                height: 24
                                radius: Theme.cornerRadiusSmall
                                color: diskMouseArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.04) : "transparent"

                                MouseArea {
                                    id: diskMouseArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                }

                                Row {
                                    anchors.fill: parent
                                    spacing: Theme.spacingS

                                    Text {
                                        text: modelData.device
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceText
                                        width: parent.width * 0.25
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: modelData.mount
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceText
                                        width: parent.width * 0.2
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: modelData.size
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceText
                                        width: parent.width * 0.15
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: modelData.used
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceText
                                        width: parent.width * 0.15
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: modelData.avail
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceText
                                        width: parent.width * 0.15
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: modelData.percent
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: {
                                            const percent = parseInt(modelData.percent);
                                            if (percent > 90)
                                                return Theme.error;

                                            if (percent > 75)
                                                return Theme.warning;

                                            return Theme.surfaceText;
                                        }
                                        width: parent.width * 0.1
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                }

                            }

                        }

                    }

            }

        }

    }

}
