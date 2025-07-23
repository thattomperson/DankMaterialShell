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
import qs.Modules.AppDrawer

PanelWindow {
    id: appDrawerPopout

    property bool isVisible: false

    function show() {
        appDrawerPopout.isVisible = true;
        appLauncher.searchQuery = "";
    }

    function hide() {
        appDrawerPopout.isVisible = false;
    }

    function toggle() {
        if (appDrawerPopout.isVisible)
            hide();
        else
            show();
    }

    // Proper layer shell configuration
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: isVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-launcher"
    visible: isVisible
    color: "transparent"

    // Full screen overlay setup for proper focus
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // App launcher logic
    AppLauncher {
        id: appLauncher
        
        viewMode: Prefs.appLauncherViewMode
        gridColumns: 4
        
        onAppLaunched: appDrawerPopout.hide()
        onViewModeSelected: function(mode) {
            Prefs.setAppLauncherViewMode(mode);
        }
    }

    // Background click to close (no visual background)
    MouseArea {
        anchors.fill: parent
        enabled: appDrawerPopout.isVisible
        onClicked: function(mouse) {
            // Only close if click is outside the launcher panel
            var localPos = mapToItem(launcherLoader, mouse.x, mouse.y);
            if (localPos.x < 0 || localPos.x > launcherLoader.width || 
                localPos.y < 0 || localPos.y > launcherLoader.height) {
                appDrawerPopout.hide();
            }
        }
    }

    // Main launcher panel with asynchronous loading
    Loader {
        id: launcherLoader
        asynchronous: true
        active: appDrawerPopout.isVisible
        
        width: 520
        height: 600
        x: Theme.spacingL
        y: Theme.barHeight + Theme.spacingXS
        
        // GPU-accelerated scale + opacity animation
        opacity: appDrawerPopout.isVisible ? 1 : 0
        scale: appDrawerPopout.isVisible ? 1 : 0.9
        
        Behavior on opacity {
            NumberAnimation {
                duration: Anims.durMed
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anims.emphasized
            }
        }
        
        Behavior on scale {
            NumberAnimation {
                duration: Anims.durMed
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anims.emphasized
            }
        }
        
        sourceComponent: Rectangle {
            id: launcherPanel
            color: Theme.popupBackground()
            radius: Theme.cornerRadiusXLarge
            
            // Remove layer rendering for better performance
            antialiasing: true
            smooth: true

            // Material 3 elevation with multiple layers
            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                color: "transparent"
                radius: parent.radius + 3
                border.color: Qt.rgba(0, 0, 0, 0.05)
                border.width: 1
                z: -3
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                color: "transparent"
                radius: parent.radius + 2
                border.color: Qt.rgba(0, 0, 0, 0.08)
                border.width: 1
                z: -2
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                border.width: 1
                radius: parent.radius
                z: -1
            }

            // Content with focus management
            Item {
                anchors.fill: parent
                focus: true
                Component.onCompleted: {
                    if (appDrawerPopout.isVisible)
                        forceActiveFocus();
                }
                
                // Handle keyboard shortcuts
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Escape) {
                        appDrawerPopout.hide();
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
                        // User started typing, focus search field and pass the character
                        searchField.forceActiveFocus();
                        searchField.text = event.text;
                        event.accepted = true;
                    }
                }

                Column {
                    width: parent.width - Theme.spacingXL * 2
                    height: parent.height - Theme.spacingXL * 2
                    x: Theme.spacingXL
                    y: Theme.spacingXL
                    spacing: Theme.spacingL

                    // Header section
                    Row {
                        width: parent.width
                        height: 40

                        // App launcher title
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Applications"
                            font.pixelSize: Theme.fontSizeLarge + 4
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }

                        Item {
                            width: parent.width - 200
                            height: 1
                        }

                        // Quick stats
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: appLauncher.model.count + " apps"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceVariantText
                        }
                    }

                    // Enhanced search field
                    DankTextField {
                        id: searchField

                        width: parent.width
                        height: 52
                        cornerRadius: Theme.cornerRadiusLarge
                        backgroundColor: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, Theme.getContentBackgroundAlpha() * 0.7)
                        normalBorderColor: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)
                        focusedBorderColor: Theme.primary
                        leftIconName: "search"
                        leftIconSize: Theme.iconSize
                        leftIconColor: Theme.surfaceVariantText
                        leftIconFocusedColor: Theme.primary
                        showClearButton: true
                        font.pixelSize: Theme.fontSizeLarge
                        enabled: appDrawerPopout.isVisible
                        placeholderText: "Search applications..."
                        onTextEdited: {
                            appLauncher.searchQuery = text;
                        }
                        Keys.onPressed: function(event) {
                            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && appLauncher.model.count && text.length > 0) {
                                // Launch first app when typing in search field
                                var firstApp = appLauncher.model.get(0);
                                appLauncher.launchApp(firstApp);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up || (event.key === Qt.Key_Left && appLauncher.viewMode === "grid") || (event.key === Qt.Key_Right && appLauncher.viewMode === "grid") || ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && text.length === 0)) {
                                // Pass navigation keys and enter (when not searching) to main handler
                                event.accepted = false;
                            }
                        }

                        Connections {
                            function onVisibleChanged() {
                                if (appDrawerPopout.visible)
                                    searchField.forceActiveFocus();
                                else
                                    searchField.clearFocus();
                            }

                            target: appDrawerPopout
                        }
                    }

                    // Category filter and view mode controls
                    Row {
                        width: parent.width
                        height: 40
                        spacing: Theme.spacingM
                        visible: searchField.text.length === 0

                        // Category filter using DankDropdown
                        Item {
                            width: 200
                            height: 36
                            
                            DankDropdown {
                                anchors.fill: parent
                                text: ""
                                currentValue: appLauncher.selectedCategory
                                options: appLauncher.categories
                                optionIcons: appLauncher.categoryIcons
                                onValueChanged: function(value) {
                                    appLauncher.setCategory(value);
                                }
                            }
                        }

                        Item {
                            width: parent.width - 300
                            height: 1
                        }

                        // View mode toggle
                        Row {
                            spacing: 4
                            anchors.verticalCenter: parent.verticalCenter

                            // List view button
                            DankActionButton {
                                buttonSize: 36
                                circular: false
                                iconName: "view_list"
                                iconSize: 20
                                iconColor: appLauncher.viewMode === "list" ? Theme.primary : Theme.surfaceText
                                hoverColor: appLauncher.viewMode === "list" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08)
                                backgroundColor: appLauncher.viewMode === "list" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                                onClicked: {
                                    appLauncher.setViewMode("list");
                                }
                            }

                            // Grid view button
                            DankActionButton {
                                buttonSize: 36
                                circular: false
                                iconName: "grid_view"
                                iconSize: 20
                                iconColor: appLauncher.viewMode === "grid" ? Theme.primary : Theme.surfaceText
                                hoverColor: appLauncher.viewMode === "grid" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08)
                                backgroundColor: appLauncher.viewMode === "grid" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                                onClicked: {
                                    appLauncher.setViewMode("grid");
                                }
                            }
                        }
                    }

                    // App grid/list container
                    Rectangle {
                        width: parent.width
                        height: {
                            // Calculate more precise remaining height
                            let usedHeight = 40 + Theme.spacingL;
                            // Header
                            usedHeight += 52 + Theme.spacingL;
                            // Search container
                            usedHeight += (searchField.text.length === 0 ? 40 + Theme.spacingL : 0);
                            // Category/controls when visible
                            return parent.height - usedHeight;
                        }
                        color: "transparent"

                        // List view
                        DankListView {
                            id: appList

                            anchors.fill: parent
                            visible: appLauncher.viewMode === "list"
                            model: appLauncher.model
                            currentIndex: appLauncher.selectedIndex
                            itemHeight: 72
                            iconSize: 56
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
                            id: appGrid

                            anchors.fill: parent
                            visible: appLauncher.viewMode === "grid"
                            model: appLauncher.model
                            columns: 4
                            adaptiveColumns: false
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
}