import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets
import qs.Modals.Clipboard

DankListView {
    id: clipboardListView

    required property var clipboardModal
    required property int selectedIndex
    required property bool keyboardNavigationActive

    function ensureVisible(index) {
        if (index < 0 || index >= count) {
            return
        }
        const itemHeight = ClipboardConstants.itemHeight + spacing
        const itemY = index * itemHeight
        const itemBottom = itemY + itemHeight
        if (itemY < contentY) {
            contentY = itemY
        } else if (itemBottom > contentY + height) {
            contentY = itemBottom - height
        }
    }

    clip: true
    currentIndex: selectedIndex
    spacing: Theme.spacingXS
    interactive: true
    flickDeceleration: 1500
    maximumFlickVelocity: 2000
    boundsBehavior: Flickable.DragAndOvershootBounds
    boundsMovement: Flickable.FollowBoundsBehavior
    pressDelay: 0
    flickableDirection: Flickable.VerticalFlick

    onCurrentIndexChanged: {
        if (keyboardNavigationActive && currentIndex >= 0) {
            ensureVisible(currentIndex)
        }
    }

    StyledText {
        text: "No clipboard entries found"
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.surfaceVariantText
        visible: model.count === 0
    }

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }

    ScrollBar.horizontal: ScrollBar {
        policy: ScrollBar.AlwaysOff
    }

    delegate: ClipboardEntry {
        required property int index
        required property var model

        width: clipboardListView.width
        height: ClipboardConstants.itemHeight
        entryData: model.entry
        entryIndex: index + 1
        itemIndex: index
        isSelected: clipboardListView.keyboardNavigationActive && index === clipboardListView.selectedIndex
        modal: clipboardListView.clipboardModal
        listView: clipboardListView
        onCopyRequested: clipboardListView.clipboardModal.copyEntry(model.entry)
        onDeleteRequested: clipboardListView.clipboardModal.deleteEntry(model.entry)
    }
}
