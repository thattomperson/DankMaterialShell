import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root

    // Public interface
    property string searchQuery: ""
    property string selectedCategory: "All"
    property string viewMode: "list" // "list" or "grid"
    property int selectedIndex: 0
    property int maxResults: 50
    property int gridColumns: 4
    property bool debounceSearch: true
    property int debounceInterval: 50

    // Categories (computed from AppSearchService)
    property var categories: {
        var allCategories = AppSearchService.getAllCategories().filter(cat => {
            return cat !== "Education" && cat !== "Science";
        });
        var result = ["All", "Recents"];
        return result.concat(allCategories.filter(cat => {
            return cat !== "All";
        }));
    }

    // Recent apps helper
    property var recentApps: Prefs.recentlyUsedApps.map(recentApp => {
        var app = AppSearchService.getAppByExec(recentApp.exec);
        return app && !app.noDisplay ? app : null;
    }).filter(app => {
        return app !== null;
    })

    // Signals
    signal appLaunched(var app)
    signal categorySelected(string category)
    signal viewModeSelected(string mode)

    // Internal model
    property alias model: filteredModel

    ListModel {
        id: filteredModel
    }

    // Search debouncing
    Timer {
        id: searchDebounceTimer
        interval: root.debounceInterval
        repeat: false
        onTriggered: updateFilteredModel()
    }

    // Watch for changes
    onSearchQueryChanged: {
        if (debounceSearch) {
            searchDebounceTimer.restart();
        } else {
            updateFilteredModel();
        }
    }
    onSelectedCategoryChanged: updateFilteredModel()

    function updateFilteredModel() {
        filteredModel.clear();
        selectedIndex = 0;

        var apps = [];

        if (searchQuery.length === 0) {
            // Show apps from category
            if (selectedCategory === "All") {
                apps = AppSearchService.applications || [];
            } else if (selectedCategory === "Recents") {
                apps = recentApps;
            } else {
                var categoryApps = AppSearchService.getAppsInCategory(selectedCategory);
                apps = categoryApps.slice(0, maxResults);
            }
        } else {
            // Search with category filter
            if (selectedCategory === "All") {
                apps = AppSearchService.searchApplications(searchQuery);
            } else if (selectedCategory === "Recents") {
                if (recentApps.length > 0) {
                    var allSearchResults = AppSearchService.searchApplications(searchQuery);
                    var recentNames = new Set(recentApps.map(app => app.name));
                    apps = allSearchResults.filter(searchApp => {
                        return recentNames.has(searchApp.name);
                    });
                } else {
                    apps = [];
                }
            } else {
                var categoryApps = AppSearchService.getAppsInCategory(selectedCategory);
                if (categoryApps.length > 0) {
                    var allSearchResults = AppSearchService.searchApplications(searchQuery);
                    var categoryNames = new Set(categoryApps.map(app => app.name));
                    apps = allSearchResults.filter(searchApp => {
                        return categoryNames.has(searchApp.name);
                    }).slice(0, maxResults);
                } else {
                    apps = [];
                }
            }
        }

        // Convert to model format and populate
        apps.forEach(app => {
            if (app) {
                filteredModel.append({
                    "name": app.name || "",
                    "exec": app.execString || "",
                    "icon": app.icon || "application-x-executable",
                    "comment": app.comment || "",
                    "categories": app.categories || [],
                    "desktopEntry": app
                });
            }
        });
    }

    // Keyboard navigation functions
    function selectNext() {
        if (filteredModel.count > 0) {
            if (viewMode === "grid") {
                var newIndex = Math.min(selectedIndex + gridColumns, filteredModel.count - 1);
                selectedIndex = newIndex;
            } else {
                selectedIndex = (selectedIndex + 1) % filteredModel.count;
            }
        }
    }

    function selectPrevious() {
        if (filteredModel.count > 0) {
            if (viewMode === "grid") {
                var newIndex = Math.max(selectedIndex - gridColumns, 0);
                selectedIndex = newIndex;
            } else {
                selectedIndex = selectedIndex > 0 ? selectedIndex - 1 : filteredModel.count - 1;
            }
        }
    }

    function selectNextInRow() {
        if (filteredModel.count > 0 && viewMode === "grid") {
            selectedIndex = Math.min(selectedIndex + 1, filteredModel.count - 1);
        }
    }

    function selectPreviousInRow() {
        if (filteredModel.count > 0 && viewMode === "grid") {
            selectedIndex = Math.max(selectedIndex - 1, 0);
        }
    }

    // App launching
    function launchSelected() {
        if (filteredModel.count > 0 && selectedIndex >= 0 && selectedIndex < filteredModel.count) {
            var selectedApp = filteredModel.get(selectedIndex);
            launchApp(selectedApp);
        }
    }

    function launchApp(appData) {
        if (appData.desktopEntry) {
            Prefs.addRecentApp(appData.desktopEntry);
            appData.desktopEntry.execute();
        } else {
            // Fallback to direct execution
            var cleanExec = appData.exec.replace(/%[fFuU]/g, "").trim();
            console.log("AppLauncher: Launching app directly:", cleanExec);
            Quickshell.execDetached(["sh", "-c", cleanExec]);
        }
        appLaunched(appData);
    }

    // Category management
    function setCategory(category) {
        selectedCategory = category;
        categorySelected(category);
    }

    // View mode management
    function setViewMode(mode) {
        viewMode = mode;
        viewModeSelected(mode);
    }

    // Initialize
    Component.onCompleted: {
        updateFilteredModel();
    }
}