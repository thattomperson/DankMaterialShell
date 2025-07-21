import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Widgets

PanelWindow {
    id: globalDropdownWindow
    
    property var sourceComponent: null
    property var options: []
    property string currentValue: ""
    property int targetX: 0
    property int targetY: 0
    signal valueSelected(string value)
    
    visible: sourceComponent !== null
    implicitWidth: 180
    implicitHeight: Math.min(200, options.length * 36 + 16)
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.margins {
        top: targetY
        left: targetX
    }
    anchors {
        top: true
        left: true
    }
    color: "transparent"
    
    function showAt(component, globalX, globalY, opts, current) {
        sourceComponent = component;
        options = opts;
        currentValue = current;
        
        // Set the target position using margins
        targetX = globalX;
        targetY = globalY;
        
        visible = true;
    }
    
    function hide() {
        sourceComponent = null;
        visible = false;
    }
    
    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadiusSmall
        color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 1.0)
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)
        border.width: 1
        
        ScrollView {
            anchors.fill: parent
            anchors.margins: Theme.spacingS
            clip: true
            
            ListView {
                model: globalDropdownWindow.options
                spacing: 2
                
                delegate: Rectangle {
                    width: ListView.view.width
                    height: 32
                    radius: Theme.cornerRadiusSmall
                    color: optionArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : "transparent"
                    
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData
                        font.pixelSize: Theme.fontSizeMedium
                        color: globalDropdownWindow.currentValue === modelData ? Theme.primary : Theme.surfaceText
                        font.weight: globalDropdownWindow.currentValue === modelData ? Font.Medium : Font.Normal
                    }
                    
                    MouseArea {
                        id: optionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            globalDropdownWindow.valueSelected(modelData);
                            globalDropdownWindow.hide();
                        }
                    }
                }
            }
        }
    }
    
    // Close on click outside
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: globalDropdownWindow.hide()
    }
}