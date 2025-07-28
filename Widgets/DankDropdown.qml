import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string text: ""
    property string description: ""
    property string currentValue: ""
    property var options: []
    property var optionIcons: [] // Array of icon names corresponding to options
    property bool forceRecreate: false

    signal valueChanged(string value)

    width: parent.width
    height: 60
    radius: Theme.cornerRadius
    color: Theme.surfaceHover
    
    Component.onCompleted: {
        // Force a small delay to ensure proper initialization
        forceRecreateTimer.start();
    }
    
    Timer {
        id: forceRecreateTimer
        interval: 50
        repeat: false
        onTriggered: {
            root.forceRecreate = !root.forceRecreate;
        }
    }
    
    Component.onDestruction: {
        var popup = popupLoader.item;
        if (popup && popup.visible) {
            popup.close();
        }
    }
    
    onVisibleChanged: {
        var popup = popupLoader.item;
        if (!visible && popup && popup.visible)
            popup.close();
        else if (visible) {
            // Force recreate popup when component becomes visible
            forceRecreateTimer.start();
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: dropdown.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingM
        spacing: Theme.spacingXS

        Text {
            text: root.text
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceText
            font.weight: Font.Medium
        }

        Text {
            text: root.description
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            visible: description.length > 0
            wrapMode: Text.WordWrap
            width: parent.width
        }

    }

    Rectangle {
        id: dropdown

        width: 180
        height: 36
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingM
        anchors.verticalCenter: parent.verticalCenter
        radius: Theme.cornerRadiusSmall
        color: dropdownArea.containsMouse ? Theme.primaryHover : Theme.contentBackground()
        border.color: Theme.surfaceVariantAlpha
        border.width: 1

        MouseArea {
            id: dropdownArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                var popup = popupLoader.item;
                if (popup && popup.visible) {
                    popup.close();
                } else if (popup) {
                    var pos = dropdown.mapToItem(Overlay.overlay, 0, dropdown.height + 4);
                    popup.x = pos.x;
                    popup.y = pos.y;
                    popup.open();
                }
            }
        }

        // Use a Row for the left-aligned content (icon + text)
        Row {
            id: contentRow

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.spacingM
            spacing: Theme.spacingS

            DankIcon {
                name: {
                    var currentIndex = root.options.indexOf(root.currentValue);
                    return root.optionIcons.length > currentIndex && currentIndex >= 0 ? root.optionIcons[currentIndex] : "";
                }
                size: 18
                color: Theme.surfaceVariantText
                visible: name !== ""
            }

            Text {
                text: root.currentValue
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                // Constrain width for proper eliding
                width: dropdown.width - contentRow.x - expandIcon.width - Theme.spacingM - Theme.spacingS
                elide: Text.ElideRight
            }

        }

        // Anchor the expand icon to the right, outside of the Row
        DankIcon {
            id: expandIcon

            name: "expand_more"
            size: 20
            color: Theme.surfaceVariantText
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: Theme.spacingS
        }

    }

    Loader {
        id: popupLoader
        active: true
        property bool recreateFlag: root.forceRecreate
        onRecreateFlagChanged: {
            // Force recreation by toggling active
            active = false;
            active = true;
        }
        
        sourceComponent: Component {
            Popup {
                id: dropdownMenu

                parent: Overlay.overlay
                width: 180
                height: Math.min(200, root.options.length * 36 + 16)
                padding: 0
                modal: true
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "transparent"
        }

        contentItem: Rectangle {
            color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 1)
            border.color: Theme.primarySelected
            border.width: 1
            radius: Theme.cornerRadiusSmall

            ListView {
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                clip: true
                model: root.options
                spacing: 2

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                property real wheelMultiplier: 1.8
                property int wheelBaseStep: 160

                WheelHandler {
                    target: null
                    onWheel: (ev) => {
                        let dy = ev.pixelDelta.y !== 0
                                 ? ev.pixelDelta.y
                                 : (ev.angleDelta.y / 120) * parent.wheelBaseStep;
                        if (ev.inverted) dy = -dy;

                        const maxY = Math.max(0, parent.contentHeight - parent.height);
                        parent.contentY = Math.max(0, Math.min(maxY,
                            parent.contentY - dy * parent.wheelMultiplier));

                        ev.accepted = true;
                    }
                }

                delegate: Rectangle {
                        width: ListView.view.width
                        height: 32
                        radius: Theme.cornerRadiusSmall
                        color: optionArea.containsMouse ? Theme.primaryHoverLight : "transparent"

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingS

                            DankIcon {
                                name: root.optionIcons.length > index ? root.optionIcons[index] : ""
                                size: 18
                                color: root.currentValue === modelData ? Theme.primary : Theme.surfaceVariantText
                                visible: name !== ""
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData
                                font.pixelSize: Theme.fontSizeMedium
                                color: root.currentValue === modelData ? Theme.primary : Theme.surfaceText
                                font.weight: root.currentValue === modelData ? Font.Medium : Font.Normal
                            }

                        }

                        MouseArea {
                            id: optionArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentValue = modelData;
                                root.valueChanged(modelData);
                                var popup = popupLoader.item;
                                if (popup) popup.close();
                            }
                        }

                }

            }

        }
        
            }
        }
    }

}
