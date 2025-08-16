import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root
    
    property string section: "right"
    property var popupTarget: null
    property var parentScreen: null
    
    width: 40
    height: 30
    radius: Theme.cornerRadius
    color: {
        const baseColor = mouseArea.containsMouse 
            ? Theme.primaryPressed
            : (IdleInhibitorService.idleInhibited ? Theme.primaryHover : Theme.secondaryHover)
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 
                      baseColor.a * Theme.widgetTransparency)
    }
    
    DankIcon {
        anchors.centerIn: parent
        name: IdleInhibitorService.idleInhibited ? "motion_sensor_active" : "motion_sensor_idle"
        size: Theme.iconSize - 6
        color: Theme.surfaceText
    }
    
    MouseArea {
        id: mouseArea
        
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            IdleInhibitorService.toggleIdleInhibit()
        }
    }
    
    ToolTip {
        visible: mouseArea.containsMouse
        delay: 1000
        text: IdleInhibitorService.idleInhibited 
            ? "Screen timeout disabled\nClick to enable" 
            : "Screen timeout enabled\nClick to disable"
        
        contentItem: Text {
            text: parent.text || ""
            font.family: Theme.fontFamily || "Sans"
            font.pixelSize: Theme.fontSize - 2
            color: Theme.surfaceText
        }
        
        background: Rectangle {
            color: Theme.surfaceContainer
            radius: Theme.cornerRadius
            border.color: Theme.outline
            border.width: 1
        }
    }
    
    Behavior on color {
        ColorAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing
        }
    }
}