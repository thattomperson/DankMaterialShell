import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.AppDrawer

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
    borderColor: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
    borderWidth: 1
    enableShadow: true
    
    onVisibleChanged: {
        console.log("SpotlightModal visibility changed to:", visible);
        if (visible && !spotlightOpen) {
            show();
        }
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

    content: Component {
        Item {
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
                } else if (event.text && event.text.length > 0 && event.text.match(/[a-zA-Z0-9\\s]/)) {
                    searchField.text = event.text;
                    searchField.forceActiveFocus();
                    event.accepted = true;
                }
            }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingM
            

            // Category selector
            CategorySelector {
                width: parent.width
                categories: appLauncher.categories
                selectedCategory: appLauncher.selectedCategory
                compact: false
                visible: appLauncher.categories.length > 1 || appLauncher.model.count > 0
                
                onCategorySelected: appLauncher.setCategory(category)
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
                    normalBorderColor: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
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
                    text: appLauncher.searchQuery
                    onTextEdited: {
                        appLauncher.searchQuery = text;
                    }

                    Connections {
                        target: spotlightModal
                        function onOpened() {
                            searchField.forceActiveFocus();
                        }
                        function onDialogClosed() {
                            searchField.clearFocus();
                        }
                    }
                    
                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape) {
                            hide();
                            event.accepted = true;
                        } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && appLauncher.searchQuery.length > 0) {
                            // Launch first app when typing in search field
                            if (appLauncher.model.count > 0) {
                                appLauncher.launchApp(appLauncher.model.get(0));
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up || 
                                   (event.key === Qt.Key_Left && appLauncher.viewMode === "grid") ||
                                   (event.key === Qt.Key_Right && appLauncher.viewMode === "grid") ||
                                   ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && appLauncher.searchQuery.length === 0)) {
                            // Pass navigation keys and enter (when not searching) to main handler
                            event.accepted = false;
                        }
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
                        color: appLauncher.viewMode === "list" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : listViewArea.containsMouse ? Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08) : "transparent"
                        border.color: appLauncher.viewMode === "list" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : "transparent"
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
                        color: appLauncher.viewMode === "grid" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : gridViewArea.containsMouse ? Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08) : "transparent"
                        border.color: appLauncher.viewMode === "grid" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : "transparent"
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

            // Results container
            Rectangle {
                id: resultsContainer

                width: parent.width
                height: parent.height - y // Use remaining space
                color: "transparent"

                // List view
                DankListView {
                    id: resultsList

                    anchors.fill: parent
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

                // Grid view
                DankGridView {
                    id: resultsGrid

                    anchors.fill: parent
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
}