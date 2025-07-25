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
        // Close any open context menus
        if (processContextMenu.visible) {
            processContextMenu.close();
        }
    }

    function show() {
        isVisible = true;
    }

    function toggle() {
        if (isVisible)
            hide();
        else
            show();
    }

    visible: isVisible
    
    Ref {
        service: SysMonitorService
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
        onClicked: function(mouse) {
            // Only close if click is outside the content loader
            var localPos = mapToItem(contentLoader, mouse.x, mouse.y);
            if (localPos.x < 0 || localPos.x > contentLoader.width || 
                localPos.y < 0 || localPos.y > contentLoader.height) {
                processListPopout.hide();
            }
        }
    }

    Loader {
        id: contentLoader
        asynchronous: true
        active: processListPopout.isVisible
        
        readonly property real targetWidth: Math.min(600, Screen.width - Theme.spacingL * 2)
        readonly property real targetHeight: Math.min(600, Screen.height - Theme.barHeight - Theme.spacingS * 2)
        width: targetWidth
        height: targetHeight
        y: Theme.barHeight + Theme.spacingXS
        x: Math.max(Theme.spacingL, Screen.width - targetWidth - Theme.spacingL)
        
        // GPU-accelerated scale + opacity animation
        opacity: processListPopout.isVisible ? 1 : 0
        scale: processListPopout.isVisible ? 1 : 0.9
        
        Behavior on opacity {
            NumberAnimation {
                duration: Anims.durMed
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anims.emphasized
            }
        }
        
        Behavior on scale {
            NumberAnimation {
                duration: Anims.durMed
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anims.emphasized
            }
        }
        
        sourceComponent: Rectangle {
            id: dropdownContent
            radius: Theme.cornerRadiusLarge
            color: Theme.popupBackground()
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
            border.width: 1
            clip: true
            
            // Remove layer rendering for better performance
            antialiasing: true
            smooth: true


            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingL

                Rectangle {
                    Layout.fillWidth: true
                    height: systemOverview.height + Theme.spacingM * 2
                    radius: Theme.cornerRadiusLarge
                    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.2)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
                    border.width: 1

                    SystemOverview {
                        id: systemOverview
                        anchors.centerIn: parent
                        width: parent.width - Theme.spacingM * 2
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.cornerRadiusLarge
                    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.1)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.05)
                    border.width: 1

                    ProcessListView {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        contextMenu: processContextMenu
                    }
                }
            }
        }
    }

    ProcessContextMenu {
        id: processContextMenu
    }
}