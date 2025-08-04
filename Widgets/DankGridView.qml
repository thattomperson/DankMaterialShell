import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import qs.Common

GridView {
    id: gridView

    property int currentIndex: 0
    property int columns: 4
    property bool adaptiveColumns: false
    property int minCellWidth: 120
    property int maxCellWidth: 160
    property int cellPadding: 8
    property real iconSizeRatio: 0.6
    property int maxIconSize: 56
    property int minIconSize: 32
    property bool hoverUpdatesSelection: true
    property bool keyboardNavigationActive: false
    property real wheelMultiplier: 1.8
    property int wheelBaseStep: 160
    property int baseCellWidth: adaptiveColumns ? Math.max(minCellWidth, Math.min(maxCellWidth, width / columns)) : (width - Theme.spacingS * 2) / columns
    property int baseCellHeight: baseCellWidth + 20
    property int actualColumns: adaptiveColumns ? Math.floor(width / cellWidth) : columns
    property int remainingSpace: width - (actualColumns * cellWidth)

    signal keyboardNavigationReset()
    signal itemClicked(int index, var modelData)
    signal itemHovered(int index)
    signal itemRightClicked(int index, var modelData, real mouseX, real mouseY)

    function ensureVisible(index) {
        if (index < 0 || index >= gridView.count)
            return ;

        var itemY = Math.floor(index / gridView.actualColumns) * gridView.cellHeight;
        var itemBottom = itemY + gridView.cellHeight;
        if (itemY < gridView.contentY)
            gridView.contentY = itemY;
        else if (itemBottom > gridView.contentY + gridView.height)
            gridView.contentY = itemBottom - gridView.height;
    }

    onCurrentIndexChanged: {
        if (keyboardNavigationActive)
            ensureVisible(currentIndex);

    }
    clip: true
    anchors.margins: Theme.spacingS
    cellWidth: baseCellWidth
    cellHeight: baseCellHeight
    leftMargin: Math.max(Theme.spacingS, remainingSpace / 2)
    rightMargin: leftMargin
    focus: true
    interactive: true
    flickDeceleration: 300
    maximumFlickVelocity: 30000

    WheelHandler {
        target: null
        onWheel: (ev) => {
            let dy = ev.pixelDelta.y !== 0 ? ev.pixelDelta.y : (ev.angleDelta.y / 120) * gridView.wheelBaseStep;
            if (ev.inverted)
                dy = -dy;

            const maxY = Math.max(0, gridView.contentHeight - gridView.height);
            gridView.contentY = Math.max(0, Math.min(maxY, gridView.contentY - dy * gridView.wheelMultiplier));
            ev.accepted = true;
        }
    }

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }

    ScrollBar.horizontal: ScrollBar {
        policy: ScrollBar.AlwaysOff
    }

    delegate: Rectangle {
        width: gridView.cellWidth - cellPadding
        height: gridView.cellHeight - cellPadding
        radius: Theme.cornerRadiusLarge
        color: currentIndex === index ? Theme.primaryPressed : mouseArea.containsMouse ? Theme.primaryHoverLight : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.03)
        border.color: currentIndex === index ? Theme.primarySelected : Theme.outlineMedium
        border.width: currentIndex === index ? 2 : 1

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacingS

            Item {
                property int iconSize: Math.min(maxIconSize, Math.max(minIconSize, gridView.cellWidth * iconSizeRatio))

                width: iconSize
                height: iconSize
                anchors.horizontalCenter: parent.horizontalCenter

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
                        font.pixelSize: Math.min(28, parent.width * 0.5)
                        color: Theme.primary
                        font.weight: Font.Bold
                    }

                }

            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                width: gridView.cellWidth - 12
                text: model.name || ""
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                font.weight: Font.Medium
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 2
                wrapMode: Text.WordWrap
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
