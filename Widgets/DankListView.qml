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
    property real wheelMultiplier: 1.8
    property int wheelBaseStep: 160

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
    flickDeceleration: 600
    maximumFlickVelocity: 30000

    WheelHandler {
        target: null
        onWheel: (ev) => {
            let dy = ev.pixelDelta.y !== 0 ? ev.pixelDelta.y : (ev.angleDelta.y / 120) * wheelBaseStep;
            if (ev.inverted)
                dy = -dy;

            const maxY = Math.max(0, contentHeight - height);
            contentY = Math.max(0, Math.min(maxY, contentY - dy * wheelMultiplier));
            ev.accepted = true;
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
                    source: (model.icon) ? Quickshell.iconPath(model.icon, Prefs.iconTheme === "System Default" ? "" : Prefs.iconTheme) : ""
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
