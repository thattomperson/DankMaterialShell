import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets

PanelWindow {
    id: spotlightLauncher

    property bool spotlightOpen: false
    property var filteredApps: []
    property int selectedIndex: 0
    property int maxResults: 50
    property var categories: {
        var allCategories = AppSearchService.getAllCategories().filter((cat) => {
            return cat !== "Education" && cat !== "Science";
        });
        // Insert "Recents" after "All"
        var result = ["All", "Recents"];
        return result.concat(allCategories.filter((cat) => {
            return cat !== "All";
        }));
    }
    property string selectedCategory: "All"
    property string viewMode: Prefs.spotlightLauncherViewMode // "list" or "grid"

    // ...existing code...
    function show() {
        console.log("SpotlightLauncher: show() called");
        spotlightOpen = true;
        console.log("SpotlightLauncher: spotlightOpen set to", spotlightOpen);
        searchDebounceTimer.stop(); // Stop any pending search
        updateFilteredApps(); // Immediate update when showing
        Qt.callLater(function() {
            searchField.forceActiveFocus();
            searchField.selectAll();
        });
    }

    function hide() {
        spotlightOpen = false;
        searchDebounceTimer.stop(); // Stop any pending search
        searchField.text = "";
        selectedIndex = 0;
        selectedCategory = "All";
        updateFilteredApps();
    }

    function toggle() {
        if (spotlightOpen)
            hide();
        else
            show();
    }

    function updateFilteredApps() {
        filteredApps = [];
        selectedIndex = 0;
        var apps = [];
        var searchQuery = searchField.text;
        if (searchQuery.length === 0) {
            // Show apps from category
            if (selectedCategory === "All") {
                // For "All" category, show all available apps
                apps = AppSearchService.applications || [];
            } else if (selectedCategory === "Recents") {
                // For "Recents" category, get recent apps from Prefs and filter out non-existent ones
                var recentApps = Prefs.getRecentApps();
                apps = recentApps.map((recentApp) => {
                    return AppSearchService.getAppByExec(recentApp.exec);
                }).filter((app) => {
                    return app !== null && !app.noDisplay;
                });
            } else {
                // For specific categories, limit results
                var categoryApps = AppSearchService.getAppsInCategory(selectedCategory);
                apps = categoryApps.slice(0, maxResults);
            }
        } else {
            // Search with category filter
            if (selectedCategory === "All") {
                // For "All" category, search all apps without limit
                apps = AppSearchService.searchApplications(searchQuery);
            } else if (selectedCategory === "Recents") {
                // For "Recents" category, search within recent apps
                var recentApps = Prefs.getRecentApps();
                var recentDesktopEntries = recentApps.map((recentApp) => {
                    return AppSearchService.getAppByExec(recentApp.exec);
                }).filter((app) => {
                    return app !== null && !app.noDisplay;
                });
                if (recentDesktopEntries.length > 0) {
                    var allSearchResults = AppSearchService.searchApplications(searchQuery);
                    var recentNames = new Set(recentDesktopEntries.map((app) => {
                        return app.name;
                    }));
                    // Filter search results to only include recent apps
                    apps = allSearchResults.filter((searchApp) => {
                        return recentNames.has(searchApp.name);
                    });
                } else {
                    apps = [];
                }
            } else {
                // For specific categories, filter search results by category
                var categoryApps = AppSearchService.getAppsInCategory(selectedCategory);
                if (categoryApps.length > 0) {
                    var allSearchResults = AppSearchService.searchApplications(searchQuery);
                    var categoryNames = new Set(categoryApps.map((app) => {
                        return app.name;
                    }));
                    // Filter search results to only include apps from the selected category
                    apps = allSearchResults.filter((searchApp) => {
                        return categoryNames.has(searchApp.name);
                    }).slice(0, maxResults);
                } else {
                    apps = [];
                }
            }
        }
        // Convert to our format - batch operations for better performance
        filteredApps = apps.map((app) => {
            return ({
                "name": app.name,
                "exec": app.execString || "",
                "icon": app.icon || "application-x-executable",
                "comment": app.comment || "",
                "categories": app.categories || [],
                "desktopEntry": app
            });
        });
        // Clear and repopulate model efficiently
        filteredModel.clear();
        filteredApps.forEach((app) => {
            return filteredModel.append(app);
        });
    }

    function launchApp(app) {
        Prefs.addRecentApp(app);
        if (app.desktopEntry) {
            app.desktopEntry.execute();
        } else {
            var cleanExec = app.exec.replace(/%[fFuU]/g, "").trim();
            console.log("Spotlight: Launching app directly:", cleanExec);
            Quickshell.execDetached(["sh", "-c", cleanExec]);
        }
        hide();
    }

    function selectNext() {
        if (filteredApps.length > 0) {
            if (viewMode === "grid") {
                // Grid navigation: move by columns
                var columnsCount = resultsGrid.columns || 6;
                selectedIndex = Math.min(selectedIndex + columnsCount, filteredApps.length - 1);
            } else {
                // List navigation: next item
                selectedIndex = (selectedIndex + 1) % filteredApps.length;
            }
        }
    }

    function selectPrevious() {
        if (filteredApps.length > 0) {
            if (viewMode === "grid") {
                // Grid navigation: move by columns
                var columnsCount = resultsGrid.columns || 6;
                selectedIndex = Math.max(selectedIndex - columnsCount, 0);
            } else {
                // List navigation: previous item
                selectedIndex = selectedIndex > 0 ? selectedIndex - 1 : filteredApps.length - 1;
            }
        }
    }

    function selectNextInRow() {
        if (filteredApps.length > 0 && viewMode === "grid")
            selectedIndex = Math.min(selectedIndex + 1, filteredApps.length - 1);

    }

    function selectPreviousInRow() {
        if (filteredApps.length > 0 && viewMode === "grid")
            selectedIndex = Math.max(selectedIndex - 1, 0);

    }

    function launchSelected() {
        if (filteredApps.length > 0 && selectedIndex >= 0 && selectedIndex < filteredApps.length)
            launchApp(filteredApps[selectedIndex]);

    }

    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: spotlightOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-spotlight"
    visible: spotlightOpen
    onVisibleChanged: {
        console.log("SpotlightLauncher visibility changed to:", visible);
    }
    color: "transparent"
    Component.onCompleted: {
        console.log("SpotlightLauncher: Component.onCompleted called - component loaded successfully!");
        var allCategories = AppSearchService.getAllCategories().filter((cat) => {
            return cat !== "Education" && cat !== "Science";
        });
        // Insert "Recents" after "All"
        var result = ["All", "Recents"];
        categories = result.concat(allCategories.filter((cat) => {
            return cat !== "All";
        }));
    }

    // Search debouncing
    Timer {
        id: searchDebounceTimer

        interval: 50
        repeat: false
        onTriggered: updateFilteredApps()
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    ListModel {
        id: filteredModel
    }

    Connections {
        function onReadyChanged() {
            if (AppSearchService.ready) {
                var allCategories = AppSearchService.getAllCategories().filter((cat) => {
                    return cat !== "Education" && cat !== "Science";
                });
                // Insert "Recents" after "All"
                var result = ["All", "Recents"];
                categories = result.concat(allCategories.filter((cat) => {
                    return cat !== "All";
                }));
                if (spotlightOpen)
                    updateFilteredApps();

            }
        }

        target: DesktopEntries
    }

    Connections {
        function onApplicationsChanged() {
            console.log("SpotlightLauncher: DesktopEntries.applicationsChanged signal received");
            // Update categories when applications change
            if (AppSearchService.ready) {
                console.log("SpotlightLauncher: Updating categories and apps due to applicationsChanged");
                var allCategories = AppSearchService.getAllCategories().filter((cat) => {
                    return cat !== "Education" && cat !== "Science";
                });
                var result = ["All", "Recents"];
                categories = result.concat(allCategories.filter((cat) => {
                    return cat !== "All";
                }));
                if (spotlightOpen)
                    updateFilteredApps();

            } else {
                console.log("SpotlightLauncher: AppSearchService not ready, skipping update");
            }
        }

        target: DesktopEntries
    }

    // Dimmed overlay background
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.4)
        opacity: spotlightOpen ? 1 : 0

        MouseArea {
            anchors.fill: parent
            enabled: spotlightOpen
            onClicked: hide()
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }

        }

    }

    // Main container with search and results
    Rectangle {
        // Margins and spacing
        // Categories (2 rows)

        id: mainContainer

        width: 600
        height: {
            // Fixed height to prevent shrinking - consistent experience
            let baseHeight = Theme.spacingXL * 2 + Theme.spacingL * 3;
            // Add category section height if visible
            if (categories.length > 1 || filteredModel.count > 0)
                baseHeight += 36 * 2 + Theme.spacingS + Theme.spacingM;

            // Add search field height
            baseHeight += 56;
            // Add fixed results height for consistent size
            let fixedResultsHeight = 400;
            // Always same height regardless of content
            baseHeight += fixedResultsHeight;
            // Ensure reasonable bounds
            return Math.min(Math.max(baseHeight, 500), parent.height - 40);
        }
        anchors.centerIn: parent
        color: Theme.popupBackground()
        radius: Theme.cornerRadiusXLarge
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
        border.width: 1
        layer.enabled: true
        opacity: spotlightOpen ? 1 : 0
        scale: spotlightOpen ? 1 : 0.96

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingXL
            spacing: Theme.spacingL

            // Combined row for categories and view mode toggle
            Column {
                width: parent.width
                spacing: Theme.spacingM
                visible: categories.length > 1 || filteredModel.count > 0

                // Categories organized in 2 rows: 4 + 5
                Column {
                    width: parent.width
                    spacing: Theme.spacingS

                    // Top row: All, Development, Graphics, Internet (4 items)
                    Row {
                        property var topRowCategories: ["All", "Recents", "Development", "Graphics"]

                        width: parent.width
                        spacing: Theme.spacingS

                        Repeater {
                            model: parent.topRowCategories.filter((cat) => {
                                return categories.includes(cat);
                            })

                            Rectangle {
                                height: 36
                                width: (parent.width - (parent.topRowCategories.length - 1) * Theme.spacingS) / parent.topRowCategories.length
                                radius: Theme.cornerRadiusLarge
                                color: selectedCategory === modelData ? Theme.primary : "transparent"
                                border.color: selectedCategory === modelData ? "transparent" : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: selectedCategory === modelData ? Theme.surface : Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: selectedCategory === modelData ? Font.Medium : Font.Normal
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        selectedCategory = modelData;
                                        updateFilteredApps();
                                    }
                                }

                            }

                        }

                    }

                    // Bottom row: Media, Office, Settings, System, Utilities (5 items)
                    Row {
                        property var bottomRowCategories: ["Internet", "Media", "Office", "Settings", "System"]

                        width: parent.width
                        spacing: Theme.spacingS

                        Repeater {
                            model: parent.bottomRowCategories.filter((cat) => {
                                return categories.includes(cat);
                            })

                            Rectangle {
                                height: 36
                                width: (parent.width - (parent.bottomRowCategories.length - 1) * Theme.spacingS) / parent.bottomRowCategories.length
                                radius: Theme.cornerRadiusLarge
                                color: selectedCategory === modelData ? Theme.primary : "transparent"
                                border.color: selectedCategory === modelData ? "transparent" : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: selectedCategory === modelData ? Theme.surface : Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: selectedCategory === modelData ? Font.Medium : Font.Normal
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        selectedCategory = modelData;
                                        updateFilteredApps();
                                    }
                                }

                            }

                        }

                    }

                }

            }

            // Search field with view toggle buttons
            Row {
                width: parent.width
                spacing: Theme.spacingM

                Rectangle {
                    id: searchContainer

                    width: parent.width - 80 - Theme.spacingM // Leave space for view toggle buttons
                    height: 56
                    radius: Theme.cornerRadiusLarge
                    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, Theme.getContentBackgroundAlpha() * 0.7)
                    border.width: searchField.activeFocus ? 2 : 1
                    border.color: searchField.activeFocus ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingL
                        anchors.rightMargin: Theme.spacingL
                        spacing: Theme.spacingM

                        DankIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "search"
                            size: Theme.iconSize
                            color: searchField.activeFocus ? Theme.primary : Theme.surfaceVariantText
                        }

                        TextInput {
                            id: searchField

                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - parent.spacing - Theme.iconSize - 32
                            height: parent.height - Theme.spacingS
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeLarge
                            verticalAlignment: Text.AlignVCenter
                            focus: spotlightOpen
                            selectByMouse: true
                            onTextChanged: {
                                searchDebounceTimer.restart();
                            }
                            Keys.onPressed: (event) => {
                                if (event.key === Qt.Key_Escape) {
                                    hide();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    launchSelected();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Down) {
                                    selectNext();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up) {
                                    selectPrevious();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Right && viewMode === "grid") {
                                    selectNextInRow();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Left && viewMode === "grid") {
                                    selectPreviousInRow();
                                    event.accepted = true;
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.IBeamCursor
                                acceptedButtons: Qt.NoButton
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Search applications..."
                                color: Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeLarge
                                visible: searchField.text.length === 0 && !searchField.activeFocus
                            }

                        }

                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Theme.shortDuration
                            easing.type: Theme.standardEasing
                        }

                    }

                }

                // View mode toggle buttons next to search bar
                Row {
                    spacing: Theme.spacingXS
                    visible: filteredModel.count > 0
                    anchors.verticalCenter: parent.verticalCenter

                    // List view button
                    Rectangle {
                        width: 36
                        height: 36
                        radius: Theme.cornerRadiusLarge
                        color: viewMode === "list" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : listViewArea.containsMouse ? Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08) : "transparent"
                        border.color: viewMode === "list" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : "transparent"
                        border.width: 1

                        DankIcon {
                            anchors.centerIn: parent
                            name: "view_list"
                            size: 18
                            color: viewMode === "list" ? Theme.primary : Theme.surfaceText
                        }

                        MouseArea {
                            id: listViewArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                viewMode = "list";
                                Prefs.setSpotlightLauncherViewMode("list");
                            }
                        }

                    }

                    // Grid view button
                    Rectangle {
                        width: 36
                        height: 36
                        radius: Theme.cornerRadiusLarge
                        color: viewMode === "grid" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : gridViewArea.containsMouse ? Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08) : "transparent"
                        border.color: viewMode === "grid" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : "transparent"
                        border.width: 1

                        DankIcon {
                            anchors.centerIn: parent
                            name: "grid_view"
                            size: 18
                            color: viewMode === "grid" ? Theme.primary : Theme.surfaceText
                        }

                        MouseArea {
                            id: gridViewArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                viewMode = "grid";
                                Prefs.setSpotlightLauncherViewMode("grid");
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
                    visible: viewMode === "list"
                    model: filteredModel
                    currentIndex: selectedIndex
                    itemHeight: 60
                    iconSize: 40
                    showDescription: true
                    onItemClicked: function(index, modelData) {
                        launchApp(modelData);
                    }
                    onItemHovered: function(index) {
                        selectedIndex = index;
                    }
                }

                // Grid view
                DankGridView {
                    id: resultsGrid
                    anchors.fill: parent
                    visible: viewMode === "grid"
                    model: filteredModel
                    columns: 6
                    adaptiveColumns: true
                    minCellWidth: 120
                    maxCellWidth: 160
                    iconSizeRatio: 0.55
                    maxIconSize: 48
                    currentIndex: selectedIndex
                    onItemClicked: function(index, modelData) {
                        launchApp(modelData);
                    }
                    onItemHovered: function(index) {
                        selectedIndex = index;
                    }
                }

            }

        }

        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 8
            shadowBlur: 1 // radius/32
            shadowColor: Qt.rgba(0, 0, 0, 0.3)
            shadowOpacity: 0.3
        }
        // Center-screen fade with subtle scale

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
            }

        }

    }

    IpcHandler {
        function open() {
            console.log("SpotlightLauncher: IPC open() called");
            spotlightLauncher.show();
            return "SPOTLIGHT_OPEN_SUCCESS";
        }

        function close() {
            console.log("SpotlightLauncher: IPC close() called");
            spotlightLauncher.hide();
            return "SPOTLIGHT_CLOSE_SUCCESS";
        }

        function toggle() {
            console.log("SpotlightLauncher: IPC toggle() called");
            spotlightLauncher.toggle();
            return "SPOTLIGHT_TOGGLE_SUCCESS";
        }

        target: "spotlight"
    }

}
