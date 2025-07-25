import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import qs.Common

ScrollView {
    id: gridView

    property alias model: grid.model
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

    signal keyboardNavigationReset()
    signal itemClicked(int index, var modelData)
    signal itemHovered(int index)

    // Ensure the current item is visible
    function ensureVisible(index) {
        if (index < 0 || index >= grid.count)
            return ;

        var itemY = Math.floor(index / grid.actualColumns) * grid.cellHeight;
        var itemBottom = itemY + grid.cellHeight;
        if (itemY < grid.contentY)
            grid.contentY = itemY;
        else if (itemBottom > grid.contentY + grid.height)
            grid.contentY = itemBottom - grid.height;
    }

    onCurrentIndexChanged: {
        if (keyboardNavigationActive)
            ensureVisible(currentIndex);

    }
    clip: true
    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    GridView {
        id: grid

        property int baseCellWidth: adaptiveColumns ? Math.max(minCellWidth, Math.min(maxCellWidth, width / columns)) : (width - Theme.spacingS * 2) / columns
        property int baseCellHeight: baseCellWidth + 20
        property int actualColumns: adaptiveColumns ? Math.floor(width / cellWidth) : columns
        property int remainingSpace: width - (actualColumns * cellWidth)

        anchors.fill: parent
        anchors.margins: Theme.spacingS
        cellWidth: baseCellWidth
        cellHeight: baseCellHeight
        leftMargin: Math.max(Theme.spacingS, remainingSpace / 2)
        rightMargin: leftMargin
        focus: true
        interactive: true
        flickDeceleration: 300
        maximumFlickVelocity: 30000

        delegate: Rectangle {
            width: grid.cellWidth - cellPadding
            height: grid.cellHeight - cellPadding
            radius: Theme.cornerRadiusLarge
            color: currentIndex === index ? Theme.primaryPressed : mouseArea.containsMouse ? Theme.primaryHoverLight : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.03)
            border.color: currentIndex === index ? Theme.primarySelected : Theme.outlineMedium
            border.width: currentIndex === index ? 2 : 1

            Column {
                anchors.centerIn: parent
                spacing: Theme.spacingS

                Item {
                    property int iconSize: Math.min(maxIconSize, Math.max(minIconSize, grid.cellWidth * iconSizeRatio))

                    width: iconSize
                    height: iconSize
                    anchors.horizontalCenter: parent.horizontalCenter

                    IconImage {
                        id: iconImg

                        anchors.fill: parent
                        source: (model.icon) ? Quickshell.iconPath(model.icon, "") : ""
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

                        Text {
                            anchors.centerIn: parent
                            text: (model.name && model.name.length > 0) ? model.name.charAt(0).toUpperCase() : "A"
                            font.pixelSize: Math.min(28, parent.width * 0.5)
                            color: Theme.primary
                            font.weight: Font.Bold
                        }

                    }

                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: grid.cellWidth - 12
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
                z: 10
                onEntered: {
                    if (hoverUpdatesSelection && !keyboardNavigationActive)
                        currentIndex = index;

                    itemHovered(index);
                }
                onPositionChanged: {
                    // Signal parent to reset keyboard navigation flag when mouse moves
                    keyboardNavigationReset();
                }
                onClicked: {
                    itemClicked(index, model);
                }
            }

        }

    }

}
