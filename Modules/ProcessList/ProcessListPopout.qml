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
import qs.Modules.ProcessList

PanelWindow {
    id: processListPopout

    property bool isVisible: false
    property var parentWidget: null

    function hide() {
        isVisible = false;
    }

    function show() {
        isVisible = true;
        ProcessMonitorService.updateSystemInfo();
        ProcessMonitorService.updateProcessList();
    }

    function toggle() {
        if (isVisible)
            hide();
        else
            show();
    }

    visible: isVisible
    onIsVisibleChanged: {
        ProcessMonitorService.enableMonitoring(isVisible);
    }
    implicitWidth: 600
    implicitHeight: 600
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: processListPopout.hide()
    }

    Rectangle {
        id: dropdownContent

        readonly property real targetWidth: Math.min(600, Screen.width - Theme.spacingL * 2)
        readonly property real targetHeight: Math.min(600, Screen.height - Theme.barHeight - Theme.spacingS * 2)
        width: targetWidth
        height: targetHeight
        y: Theme.barHeight + Theme.spacingXS
        radius: Theme.cornerRadiusLarge
        color: Theme.popupBackground()
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
        border.width: 1
        clip: true
        opacity: processListPopout.isVisible ? 1 : 0
        layer.enabled: true
        property real normalX: Math.max(Theme.spacingL, Screen.width - targetWidth - Theme.spacingL)
        x: processListPopout.isVisible ? normalX : normalX + Anims.slidePx

        Behavior on x {
            NumberAnimation {
                duration: Anims.durMed
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {

            anchors.fill: parent
            onClicked: {
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            SystemOverview {
                Layout.fillWidth: true
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
            }

            ProcessListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contextMenu: processContextMenuWindow
                processContextMenuWindow: processContextMenuWindow
            }
        }

        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 8
            shadowBlur: 1
            shadowColor: Qt.rgba(0, 0, 0, 0.15)
            shadowOpacity: processListPopout.isVisible ? 0.15 : 0
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Anims.durShort
                easing.type: Easing.OutCubic
            }
        }

    }

    ProcessContextMenu {
        id: processContextMenuWindow
    }

}