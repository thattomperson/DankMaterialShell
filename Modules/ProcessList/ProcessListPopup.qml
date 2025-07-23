import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets

PanelWindow {
    id: processListPopup

    property bool isVisible: false
    property int currentTab: 0
    property var tabNames: ["Processes", "Performance", "System"]

    function show() {
        processListPopup.isVisible = true;
        ProcessMonitorService.updateSystemInfo();
        ProcessMonitorService.updateProcessList();
        SystemMonitorService.enableDetailedMonitoring(true);
        SystemMonitorService.updateSystemInfo();
        UserInfoService.getUptime();
    }

    function hide() {
        processListPopup.isVisible = false;
        SystemMonitorService.enableDetailedMonitoring(false);
    }

    function toggle() {
        if (processListPopup.isVisible)
            hide();
        else
            show();
    }

    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: isVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-processlist"
    visible: isVisible
    color: "transparent"
    onIsVisibleChanged: {
        ProcessMonitorService.enableMonitoring(isVisible);
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.4)
        opacity: processListPopup.isVisible ? 1 : 0
        visible: processListPopup.isVisible

        MouseArea {
            anchors.fill: parent
            enabled: processListPopup.isVisible
            onClicked: processListPopup.hide()
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }

        }

    }

    Rectangle {
        id: mainContainer

        width: 900
        height: 680
        anchors.centerIn: parent
        color: Theme.popupBackground()
        radius: Theme.cornerRadiusXLarge
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
        border.width: 1
        layer.enabled: true
        opacity: processListPopup.isVisible ? 1 : 0
        scale: processListPopup.isVisible ? 1 : 0.96

        MouseArea {
            anchors.fill: parent
            onClicked: {
            }
        }

        Item {
            anchors.fill: parent
            focus: true
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                    processListPopup.hide();
                    event.accepted = true;
                } else if (event.key === Qt.Key_1) {
                    currentTab = 0;
                    event.accepted = true;
                } else if (event.key === Qt.Key_2) {
                    currentTab = 1;
                    event.accepted = true;
                } else if (event.key === Qt.Key_3) {
                    currentTab = 2;
                    event.accepted = true;
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingXL
                spacing: Theme.spacingL

                Row {
                    Layout.fillWidth: true
                    height: 40
                    spacing: Theme.spacingM

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "System Monitor"
                        font.pixelSize: Theme.fontSizeLarge + 4
                        font.weight: Font.Bold
                        color: Theme.surfaceText
                    }

                    Item {
                        width: parent.width - 280
                        height: 1
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ProcessMonitorService.processes.length + " processes"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceVariantText
                        width: Math.min(implicitWidth, 120)
                        elide: Text.ElideRight
                    }

                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.04)
                    radius: Theme.cornerRadiusLarge
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.06)
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 2

                        Repeater {
                            model: tabNames

                            Rectangle {
                                width: (parent.width - (tabNames.length - 1) * 2) / tabNames.length
                                height: 44
                                radius: Theme.cornerRadiusLarge
                                color: currentTab === index ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16) : (tabMouseArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : "transparent")
                                border.color: currentTab === index ? Theme.primary : "transparent"
                                border.width: currentTab === index ? 1 : 0

                                Row {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingS

                                    DankIcon {
                                        name: {
                                            switch (index) {
                                            case 0:
                                                return "list_alt";
                                            case 1:
                                                return "analytics";
                                            case 2:
                                                return "settings";
                                            default:
                                                return "tab";
                                            }
                                        }
                                        size: Theme.iconSize - 2
                                        color: currentTab === index ? Theme.primary : Theme.surfaceText
                                        opacity: currentTab === index ? 1 : 0.7

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Theme.shortDuration
                                            }

                                        }

                                    }

                                    Text {
                                        text: modelData
                                        font.pixelSize: Theme.fontSizeLarge
                                        font.weight: currentTab === index ? Font.Bold : Font.Medium
                                        color: currentTab === index ? Theme.primary : Theme.surfaceText

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Theme.shortDuration
                                            }

                                        }

                                    }

                                }

                                MouseArea {
                                    id: tabMouseArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        currentTab = index;
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

                        }

                    }

                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Loader {
                        id: processesTab

                        anchors.fill: parent
                        visible: currentTab === 0
                        opacity: currentTab === 0 ? 1 : 0
                        sourceComponent: processesTabComponent

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.mediumDuration
                                easing.type: Theme.emphasizedEasing
                            }

                        }

                    }

                    Loader {
                        id: performanceTab

                        anchors.fill: parent
                        visible: currentTab === 1
                        opacity: currentTab === 1 ? 1 : 0
                        sourceComponent: performanceTabComponent

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.mediumDuration
                                easing.type: Theme.emphasizedEasing
                            }

                        }

                    }

                    Loader {
                        id: systemTab

                        anchors.fill: parent
                        visible: currentTab === 2
                        opacity: currentTab === 2 ? 1 : 0
                        sourceComponent: systemTabComponent

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.mediumDuration
                                easing.type: Theme.emphasizedEasing
                            }

                        }

                    }

                }

            }

        }

        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 8
            shadowBlur: 1
            shadowColor: Qt.rgba(0, 0, 0, 0.3)
            shadowOpacity: 0.3
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

    Component {
        id: processesTabComponent
        ProcessesTab {
            contextMenu: processContextMenuWindow
        }
    }

    Component {
        id: performanceTabComponent
        PerformanceTab {}
    }

    Component {
        id: systemTabComponent
        SystemTab {}
    }

    

    ProcessContextMenu {
        id: processContextMenuWindow
    }

    IpcHandler {
        function open() {
            processListPopup.show();
            return "PROCESSLIST_OPEN_SUCCESS";
        }

        function close() {
            processListPopup.hide();
            return "PROCESSLIST_CLOSE_SUCCESS";
        }

        function toggle() {
            processListPopup.toggle();
            return "PROCESSLIST_TOGGLE_SUCCESS";
        }

        target: "processlist"
    }

}
