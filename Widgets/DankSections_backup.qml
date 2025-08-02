import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets

Column {
    id: root

    property var items: []
    property var allWidgets: []
    property string title: ""
    property string titleIcon: "widgets"
    property string sectionId: ""

    signal itemEnabledChanged(string itemId, bool enabled)
    signal itemOrderChanged(var newOrder)
    signal addWidget(string sectionId)
    signal removeLastWidget(string sectionId)

    width: parent.width
    spacing: Theme.spacingM

    // Header
    Row {
        width: parent.width
        spacing: Theme.spacingM

        DankIcon {
            name: root.titleIcon
            size: Theme.iconSize
            color: Theme.primary
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            text: root.title
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Medium
            color: Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            width: parent.width - 60
            height: 1
        }

    }

    // Widget Items
    Column {
        id: itemsList

        width: parent.width
        spacing: Theme.spacingS

        Repeater {
            model: root.items

            delegate: Item {
                id: delegateItem

                property int visualIndex: index
                property bool held: dragArea.pressed
                property string itemId: modelData.id

                width: itemsList.width
                height: 70
                z: held ? 2 : 1

                Rectangle {
                    id: itemBackground

                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Theme.cornerRadius
                    color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.8)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingM

                        // Drag handle
                        Rectangle {
                            width: 40
                            height: parent.height
                            color: "transparent"
                            anchors.verticalCenter: parent.verticalCenter

                            DankIcon {
                                name: "drag_indicator"
                                size: Theme.iconSize - 4
                                color: Theme.outline
                                anchors.centerIn: parent
                                opacity: 0.8
                            }

                        }

                        // Widget icon
                        DankIcon {
                            name: modelData.icon
                            size: Theme.iconSize
                            color: modelData.enabled ? Theme.primary : Theme.outline
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Widget info
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            width: parent.width - 200 // Leave space for toggle

                            StyledText {
                                text: modelData.text
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: modelData.enabled ? Theme.surfaceText : Theme.outline
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            StyledText {
                                text: modelData.description
                                font.pixelSize: Theme.fontSizeSmall
                                color: modelData.enabled ? Theme.outline : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.6)
                                elide: Text.ElideRight
                                width: parent.width
                                wrapMode: Text.WordWrap
                            }

                        }

                        // Spacer to push toggle to right
                        Item {
                            width: parent.width - 280 // Dynamic width
                            height: 1
                        }

                        // Toggle - positioned at right edge
                        DankToggle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 48
                            height: 24
                            hideText: true
                            checked: modelData.enabled
                            onToggled: (checked) => {
                                root.itemEnabledChanged(modelData.id, checked);
                            }
                        }

                    }

                    // Drag functionality
                    MouseArea {
                        id: dragArea

                        property bool validDragStart: false

                        anchors.fill: parent
                        hoverEnabled: true
                        drag.target: held && validDragStart ? delegateItem : undefined
                        drag.axis: Drag.YAxis
                        drag.minimumY: -delegateItem.height
                        drag.maximumY: itemsList.height
                        onPressed: (mouse) => {
                            // Only allow dragging from the drag handle area (first 60px)
                            if (mouse.x <= 60) {
                                validDragStart = true;
                                delegateItem.z = 2;
                            } else {
                                validDragStart = false;
                                mouse.accepted = false;
                            }
                        }
                        onReleased: {
                            delegateItem.z = 1;
                            if (drag.active && validDragStart) {
                                // Calculate new index based on position
                                var newIndex = Math.round(delegateItem.y / (delegateItem.height + itemsList.spacing));
                                newIndex = Math.max(0, Math.min(newIndex, root.items.length - 1));
                                if (newIndex !== index) {
                                    var newItems = root.items.slice();
                                    var draggedItem = newItems.splice(index, 1)[0];
                                    newItems.splice(newIndex, 0, draggedItem);
                                    root.itemOrderChanged(newItems.map((item) => {
                                        return item.id;
                                    }));
                                }
                            }
                            // Reset position
                            delegateItem.x = 0;
                            delegateItem.y = 0;
                            validDragStart = false;
                        }
                    }

                    // Animations for drag
                    Behavior on y {
                        enabled: !dragArea.held && !dragArea.drag.active

                        NumberAnimation {
                            duration: Theme.shortDuration
                            easing.type: Theme.standardEasing
                        }

                    }

                }

            }

        }

    }

    // Add/Remove Controls
    Rectangle {
        width: parent.width * 0.5
        height: 40
        radius: Theme.cornerRadius
        color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
        border.width: 1
        anchors.horizontalCenter: parent.horizontalCenter

        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingL

            StyledText {
                text: "Add or remove widgets"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.outline
                anchors.verticalCenter: parent.verticalCenter
            }

            Row {
                spacing: Theme.spacingS
                anchors.verticalCenter: parent.verticalCenter

                // Add button
                DankActionButton {
                    iconName: "add"
                    iconSize: Theme.iconSize - 4
                    iconColor: Theme.primary
                    hoverColor: Theme.primaryContainer
                    onClicked: {
                        root.addWidget(root.sectionId);
                    }
                }

                // Remove button
                DankActionButton {
                    iconName: "remove"
                    iconSize: Theme.iconSize - 4
                    iconColor: Theme.error
                    hoverColor: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.1)
                    enabled: root.items.length > 0
                    opacity: root.items.length > 0 ? 1 : 0.5
                    onClicked: {
                        if (root.items.length > 0)
                            root.removeLastWidget(root.sectionId);

                    }
                }

            }

        }

    }

}
