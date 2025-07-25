import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modules.AppDrawer
import qs.Services
import qs.Widgets

DankModal {
    id: spotlightModal

    property bool spotlightOpen: false

    function show() {
        console.log("SpotlightModal: show() called");
        spotlightOpen = true;
        console.log("SpotlightModal: spotlightOpen set to", spotlightOpen);
        appLauncher.searchQuery = "";
    }

    function hide() {
        spotlightOpen = false;
        appLauncher.searchQuery = "";
        appLauncher.selectedIndex = 0;
        appLauncher.setCategory("All");
    }

    function toggle() {
        if (spotlightOpen)
            hide();
        else
            show();
    }

    // DankModal configuration
    visible: spotlightOpen
    width: 550
    height: 600
    keyboardFocus: "ondemand"
    backgroundColor: Theme.popupBackground()
    cornerRadius: Theme.cornerRadiusXLarge
    borderColor: Theme.outlineMedium
    borderWidth: 1
    enableShadow: true
    onVisibleChanged: {
        console.log("SpotlightModal visibility changed to:", visible);
        if (visible && !spotlightOpen)
            show();

    }
    onBackgroundClicked: {
        spotlightOpen = false;
    }
    Component.onCompleted: {
        console.log("SpotlightModal: Component.onCompleted called - component loaded successfully!");
    }

    // App launcher logic
    AppLauncher {
        id: appLauncher

        viewMode: Prefs.spotlightModalViewMode
        gridColumns: 4
        onAppLaunched: hide()
        onViewModeSelected: function(mode) {
            Prefs.setSpotlightModalViewMode(mode);
        }
    }

    IpcHandler {
        function open() {
            console.log("SpotlightModal: IPC open() called");
            spotlightModal.show();
            return "SPOTLIGHT_OPEN_SUCCESS";
        }

        function close() {
            console.log("SpotlightModal: IPC close() called");
            spotlightModal.hide();
            return "SPOTLIGHT_CLOSE_SUCCESS";
        }

        function toggle() {
            console.log("SpotlightModal: IPC toggle() called");
            spotlightModal.toggle();
            return "SPOTLIGHT_TOGGLE_SUCCESS";
        }

        target: "spotlight"
    }

    content: Component {
        Item {
            id: spotlightKeyHandler
            anchors.fill: parent
            focus: true
            // Handle keyboard shortcuts
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                    hide();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                    appLauncher.selectNext();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    appLauncher.selectPrevious();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right && appLauncher.viewMode === "grid") {
                    appLauncher.selectNextInRow();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Left && appLauncher.viewMode === "grid") {
                    appLauncher.selectPreviousInRow();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    appLauncher.launchSelected();
                    event.accepted = true;
                } else if (!searchField.activeFocus && event.text && event.text.length > 0 && event.text.match(/[a-zA-Z0-9\\s]/)) {
                    searchField.forceActiveFocus();
                    searchField.insertText(event.text);
                    event.accepted = true;
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingL

                Rectangle {
                    width: parent.width
                    height: categorySelector.height + Theme.spacingM * 2
                    radius: Theme.cornerRadiusLarge
                    color: Theme.surfaceVariantAlpha
                    border.color: Theme.outlineMedium
                    border.width: 1
                    visible: appLauncher.categories.length > 1 || appLauncher.model.count > 0

                    CategorySelector {
                        id: categorySelector
                        anchors.centerIn: parent
                        width: parent.width - Theme.spacingM * 2
                        categories: appLauncher.categories
                        selectedCategory: appLauncher.selectedCategory
                        compact: false
                        onCategorySelected: (category) => {
                            return appLauncher.setCategory(category);
                        }
                    }
                }

                // Search field with view toggle buttons
                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    DankTextField {
                        id: searchField

                        width: parent.width - 80 - Theme.spacingM // Leave space for view toggle buttons
                        height: 56
                        cornerRadius: Theme.cornerRadiusLarge
                        backgroundColor: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, Theme.getContentBackgroundAlpha() * 0.7)
                        normalBorderColor: Theme.outlineMedium
                        focusedBorderColor: Theme.primary
                        leftIconName: "search"
                        leftIconSize: Theme.iconSize
                        leftIconColor: Theme.surfaceVariantText
                        leftIconFocusedColor: Theme.primary
                        showClearButton: true
                        textColor: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeLarge
                        enabled: spotlightOpen
                        placeholderText: "Search applications..."
                        ignoreLeftRightKeys: true
                        keyForwardTargets: [spotlightKeyHandler]
                        text: appLauncher.searchQuery
                        onTextEdited: {
                            appLauncher.searchQuery = text;
                        }
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape) {
                                hide();
                                event.accepted = true;
                            } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && text.length > 0) {
                                if (appLauncher.keyboardNavigationActive && appLauncher.model.count > 0) {
                                    appLauncher.launchSelected();
                                } else if (appLauncher.model.count > 0) {
                                    appLauncher.launchApp(appLauncher.model.get(0));
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up || event.key === Qt.Key_Left || event.key === Qt.Key_Right || ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && text.length === 0)) {
                                event.accepted = false;
                            }
                        }

                        Connections {
                            function onOpened() {
                                searchField.forceActiveFocus();
                            }

                            function onDialogClosed() {
                                searchField.clearFocus();
                            }

                            target: spotlightModal
                        }

                    }

                    // View mode toggle buttons next to search bar
                    Row {
                        spacing: Theme.spacingXS
                        visible: appLauncher.model.count > 0
                        anchors.verticalCenter: parent.verticalCenter

                        // List view button
                        Rectangle {
                            width: 36
                            height: 36
                            radius: Theme.cornerRadiusLarge
                            color: appLauncher.viewMode === "list" ? Theme.primaryHover : listViewArea.containsMouse ? Theme.surfaceHover : "transparent"
                            border.color: appLauncher.viewMode === "list" ? Theme.primarySelected : "transparent"
                            border.width: 1

                            DankIcon {
                                anchors.centerIn: parent
                                name: "view_list"
                                size: 18
                                color: appLauncher.viewMode === "list" ? Theme.primary : Theme.surfaceText
                            }

                            MouseArea {
                                id: listViewArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    appLauncher.setViewMode("list");
                                }
                            }

                        }

                        // Grid view button
                        Rectangle {
                            width: 36
                            height: 36
                            radius: Theme.cornerRadiusLarge
                            color: appLauncher.viewMode === "grid" ? Theme.primaryHover : gridViewArea.containsMouse ? Theme.surfaceHover : "transparent"
                            border.color: appLauncher.viewMode === "grid" ? Theme.primarySelected : "transparent"
                            border.width: 1

                            DankIcon {
                                anchors.centerIn: parent
                                name: "grid_view"
                                size: 18
                                color: appLauncher.viewMode === "grid" ? Theme.primary : Theme.surfaceText
                            }

                            MouseArea {
                                id: gridViewArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    appLauncher.setViewMode("grid");
                                }
                            }

                        }

                    }

                }

                Rectangle {
                    id: resultsContainer

                    width: parent.width
                    height: parent.height - y
                    radius: Theme.cornerRadiusLarge
                    color: Theme.surfaceLight
                    border.color: Theme.outlineLight
                    border.width: 1

                    DankListView {
                        id: resultsList

                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        visible: appLauncher.viewMode === "list"
                        model: appLauncher.model
                        currentIndex: appLauncher.selectedIndex
                        itemHeight: 60
                        iconSize: 40
                        showDescription: true
                        hoverUpdatesSelection: false
                        keyboardNavigationActive: appLauncher.keyboardNavigationActive
                        onItemClicked: function(index, modelData) {
                            appLauncher.launchApp(modelData);
                        }
                        onItemHovered: function(index) {
                            appLauncher.selectedIndex = index;
                        }
                        onKeyboardNavigationReset: {
                            appLauncher.keyboardNavigationActive = false;
                        }
                    }

                    DankGridView {
                        id: resultsGrid

                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        visible: appLauncher.viewMode === "grid"
                        model: appLauncher.model
                        columns: 4
                        adaptiveColumns: false
                        minCellWidth: 120
                        maxCellWidth: 160
                        iconSizeRatio: 0.55
                        maxIconSize: 48
                        currentIndex: appLauncher.selectedIndex
                        hoverUpdatesSelection: false
                        keyboardNavigationActive: appLauncher.keyboardNavigationActive
                        onItemClicked: function(index, modelData) {
                            appLauncher.launchApp(modelData);
                        }
                        onItemHovered: function(index) {
                            appLauncher.selectedIndex = index;
                        }
                        onKeyboardNavigationReset: {
                            appLauncher.keyboardNavigationActive = false;
                        }
                    }

                }

            }

        }

    }

}
