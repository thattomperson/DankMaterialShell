import "../Common/fuzzysort.js" as FuzzySort
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
    property bool enableFuzzySearch: false
    property int popupWidthOffset: 0 // How much wider the popup should be than the button
    property int maxPopupHeight: 400

    signal valueChanged(string value)

    width: parent.width
    height: 60
    radius: Theme.cornerRadius
    color: Theme.surfaceHover
    Component.onCompleted: {
        // Force a small delay to ensure proper initialization
        forceRecreateTimer.start();
    }
    Component.onDestruction: {
        var popup = popupLoader.item;
        if (popup && popup.visible)
            popup.close();

    }
    onVisibleChanged: {
        var popup = popupLoader.item;
        if (!visible && popup && popup.visible)
            popup.close();
        else if (visible)
            // Force recreate popup when component becomes visible
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

    Column {
        anchors.left: parent.left
        anchors.right: dropdown.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingM
        spacing: Theme.spacingXS

        StyledText {
            text: root.text
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceText
            font.weight: Font.Medium
        }

        StyledText {
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
                    // Center the wider popup over the dropdown button
                    popup.x = pos.x - (root.popupWidthOffset / 2);
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

            StyledText {
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

        property bool recreateFlag: root.forceRecreate

        active: true
        onRecreateFlagChanged: {
            // Force recreation by toggling active
            active = false;
            active = true;
        }

        sourceComponent: Component {
            Popup {
                id: dropdownMenu

                property string searchQuery: ""
                property var filteredOptions: []
                property int selectedIndex: -1

                function updateFilteredOptions() {
                    if (!root.enableFuzzySearch || searchQuery.length === 0) {
                        filteredOptions = root.options;
                    } else {
                        var results = FuzzySort.go(searchQuery, root.options, {
                            "limit": 50,
                            "threshold": -10000
                        });
                        filteredOptions = results.map(function(result) {
                            return result.target;
                        });
                    }
                    selectedIndex = -1;
                }

                function selectNext() {
                    if (filteredOptions.length > 0) {
                        selectedIndex = (selectedIndex + 1) % filteredOptions.length;
                        listView.positionViewAtIndex(selectedIndex, ListView.Contain);
                    }
                }

                function selectPrevious() {
                    if (filteredOptions.length > 0) {
                        selectedIndex = selectedIndex <= 0 ? filteredOptions.length - 1 : selectedIndex - 1;
                        listView.positionViewAtIndex(selectedIndex, ListView.Contain);
                    }
                }

                function selectCurrent() {
                    if (selectedIndex >= 0 && selectedIndex < filteredOptions.length) {
                        root.currentValue = filteredOptions[selectedIndex];
                        root.valueChanged(filteredOptions[selectedIndex]);
                        dropdownMenu.close();
                    }
                }

                parent: Overlay.overlay
                width: dropdown.width + root.popupWidthOffset
                height: Math.min(root.maxPopupHeight, (root.enableFuzzySearch ? 48 : 0) + Math.min(filteredOptions.length, 10) * 36 + 16)
                padding: 0
                modal: true
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                onOpened: {
                    searchQuery = "";
                    updateFilteredOptions();
                    if (root.enableFuzzySearch && searchField.visible)
                        searchField.forceActiveFocus();

                }

                background: Rectangle {
                    color: "transparent"
                }

                contentItem: Rectangle {
                    color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 1)
                    border.color: Theme.primarySelected
                    border.width: 1
                    radius: Theme.cornerRadiusSmall

                    Column {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS

                        // Search field
                        Rectangle {
                            id: searchContainer

                            width: parent.width
                            height: 36
                            visible: root.enableFuzzySearch
                            radius: Theme.cornerRadiusSmall
                            color: Theme.surfaceVariantAlpha

                            DankTextField {
                                id: searchField

                                anchors.fill: parent
                                anchors.margins: 1
                                placeholderText: "Search..."
                                text: dropdownMenu.searchQuery
                                topPadding: Theme.spacingS
                                bottomPadding: Theme.spacingS
                                onTextChanged: {
                                    dropdownMenu.searchQuery = text;
                                    dropdownMenu.updateFilteredOptions();
                                }
                                Keys.onDownPressed: dropdownMenu.selectNext()
                                Keys.onUpPressed: dropdownMenu.selectPrevious()
                                Keys.onReturnPressed: dropdownMenu.selectCurrent()
                                Keys.onEnterPressed: dropdownMenu.selectCurrent()
                            }

                        }

                        Item {
                            width: 1
                            height: Theme.spacingXS
                            visible: root.enableFuzzySearch
                        }

                        ListView {
                            id: listView

                            property real wheelMultiplier: 1.8
                            property int wheelBaseStep: 160

                            width: parent.width
                            height: parent.height - (root.enableFuzzySearch ? searchContainer.height + Theme.spacingXS : 0)
                            clip: true
                            model: dropdownMenu.filteredOptions
                            spacing: 2

                            WheelHandler {
                                target: null
                                onWheel: (ev) => {
                                    let dy = ev.pixelDelta.y !== 0 ? ev.pixelDelta.y : (ev.angleDelta.y / 120) * parent.wheelBaseStep;
                                    if (ev.inverted)
                                        dy = -dy;

                                    const maxY = Math.max(0, parent.contentHeight - parent.height);
                                    parent.contentY = Math.max(0, Math.min(maxY, parent.contentY - dy * parent.wheelMultiplier));
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
                                property bool isSelected: dropdownMenu.selectedIndex === index
                                property bool isCurrentValue: root.currentValue === modelData
                                property int optionIndex: root.options.indexOf(modelData)

                                width: ListView.view.width
                                height: 32
                                radius: Theme.cornerRadiusSmall
                                color: isSelected ? Theme.primaryHover : optionArea.containsMouse ? Theme.primaryHoverLight : "transparent"

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingS
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.spacingS

                                    DankIcon {
                                        name: optionIndex >= 0 && root.optionIcons.length > optionIndex ? root.optionIcons[optionIndex] : ""
                                        size: 18
                                        color: isCurrentValue ? Theme.primary : Theme.surfaceVariantText
                                        visible: name !== ""
                                    }

                                    StyledText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData
                                        font.pixelSize: Theme.fontSizeMedium
                                        color: isCurrentValue ? Theme.primary : Theme.surfaceText
                                        font.weight: isCurrentValue ? Font.Medium : Font.Normal
                                        width: parent.parent.width - parent.x - Theme.spacingS
                                        elide: Text.ElideRight
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
                                        dropdownMenu.close();
                                    }
                                }

                            }

                        }

                    }

                }

            }

        }

    }

}
