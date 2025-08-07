import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import qs.Common

ListView {
    id: listView

    property int itemHeight: 72
    property int iconSize: 56
    property bool showDescription: true
    property int itemSpacing: Theme.spacingS
    property bool hoverUpdatesSelection: true
    property bool keyboardNavigationActive: false

    signal keyboardNavigationReset()
    signal itemClicked(int index, var modelData)
    signal itemHovered(int index)
    signal itemRightClicked(int index, var modelData, real mouseX, real mouseY)

    function ensureVisible(index) {
        if (index < 0 || index >= count)
            return ;

        var itemY = index * (itemHeight + itemSpacing);
        var itemBottom = itemY + itemHeight;
        if (itemY < contentY)
            contentY = itemY;
        else if (itemBottom > contentY + height)
            contentY = itemBottom - height;
    }

    onCurrentIndexChanged: {
        if (keyboardNavigationActive)
            ensureVisible(currentIndex);
    }
    
    clip: true
    anchors.margins: itemSpacing
    spacing: itemSpacing
    focus: true
    interactive: true
    
    // Qt 6.9+ scrolling: flickDeceleration/maximumFlickVelocity only affect touch now
    flickDeceleration: 1500
    maximumFlickVelocity: 2000
    boundsBehavior: Flickable.StopAtBounds
    boundsMovement: Flickable.FollowBoundsBehavior
    pressDelay: 0
    flickableDirection: Flickable.VerticalFlick
    
    // Performance optimizations
    cacheBuffer: Math.min(height * 2, 1000)
    reuseItems: true
    
    // Custom wheel handler for Qt 6.9+ responsive mouse wheel scrolling
    WheelHandler {
        id: wheelHandler
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        
        // Tunable parameters for responsive scrolling
        property real mouseWheelSpeed: 20    // Higher = faster mouse wheel
        property real touchpadSpeed: 1.8     // Touchpad sensitivity
        property real momentumRetention: 0.92
        property real lastWheelTime: 0
        property real momentum: 0
        
        onWheel: (event) => {
            let currentTime = Date.now()
            let timeDelta = currentTime - lastWheelTime
            lastWheelTime = currentTime
            
            // Calculate scroll delta based on input type
            let delta = 0
            if (event.pixelDelta.y !== 0) {
                // Touchpad with pixel precision
                delta = event.pixelDelta.y * touchpadSpeed
            } else {
                // Mouse wheel - larger steps for faster scrolling
                delta = event.angleDelta.y / 120 * itemHeight * 2.5 // 2.5 items per wheel step
            }
            
            // Apply momentum for touchpad (smooth continuous scrolling)
            if (event.pixelDelta.y !== 0 && timeDelta < 50) {
                momentum = momentum * momentumRetention + delta * 0.15
                delta += momentum
            } else {
                momentum = 0
            }
            
            // Apply scrolling with proper bounds checking
            let newY = listView.contentY - delta
            newY = Math.max(0, Math.min(
                listView.contentHeight - listView.height, newY))
            
            // Cancel any conflicting flicks and apply new position
            if (listView.flicking) {
                listView.cancelFlick()
            }
            
            listView.contentY = newY
            event.accepted = true
        }
    }

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AlwaysOn
    }

    ScrollBar.horizontal: ScrollBar {
        policy: ScrollBar.AlwaysOff
    }

    delegate: Rectangle {
        width: ListView.view.width
        height: itemHeight
        radius: Theme.cornerRadiusLarge
        color: ListView.isCurrentItem ? Theme.primaryPressed : mouseArea.containsMouse ? Theme.primaryHoverLight : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.03)
        border.color: ListView.isCurrentItem ? Theme.primarySelected : Theme.outlineMedium
        border.width: ListView.isCurrentItem ? 2 : 1

        Row {
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingL

            Item {
                width: iconSize
                height: iconSize
                anchors.verticalCenter: parent.verticalCenter

                IconImage {
                    id: iconImg

                    anchors.fill: parent
                    source: (model.icon) ? Quickshell.iconPath(model.icon, SettingsData.iconTheme === "System Default" ? "" : SettingsData.iconTheme) : ""
                    smooth: true
                    asynchronous: true
                    visible: status === Image.Ready
                }

                Rectangle {
                    anchors.fill: parent
                    visible: !iconImg.visible
                    color: Theme.surfaceLight
                    radius: Theme.cornerRadiusLarge
                    border.width: 1
                    border.color: Theme.primarySelected

                    StyledText {
                        anchors.centerIn: parent
                        text: (model.name && model.name.length > 0) ? model.name.charAt(0).toUpperCase() : "A"
                        font.pixelSize: iconSize * 0.4
                        color: Theme.primary
                        font.weight: Font.Bold
                    }

                }

            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - iconSize - Theme.spacingL
                spacing: Theme.spacingXS

                StyledText {
                    width: parent.width
                    text: model.name || ""
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.surfaceText
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width
                    text: model.comment || "Application"
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceVariantText
                    elide: Text.ElideRight
                    visible: showDescription && model.comment && model.comment.length > 0
                }

            }

        }

        MouseArea {
            id: mouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            z: 10
            onEntered: {
                if (hoverUpdatesSelection && !keyboardNavigationActive)
                    currentIndex = index;

                itemHovered(index);
            }
            onPositionChanged: {
                keyboardNavigationReset();
            }
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    itemClicked(index, model);
                } else if (mouse.button === Qt.RightButton) {
                    var globalPos = mapToGlobal(mouse.x, mouse.y);
                    itemRightClicked(index, model, globalPos.x, globalPos.y);
                }
            }
        }

    }

}
