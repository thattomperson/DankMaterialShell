import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Modules.AppDrawer
import qs.Services
import qs.Widgets

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
            if (localPos.x < 0 || localPos.x > launcherLoader.width || localPos.y < 0 || localPos.y > launcherLoader.height)
                appDrawerPopout.hide();

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
                id: keyHandler

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
                    } else if (!searchField.activeFocus && event.text && event.text.length > 0 && event.text.match(/[a-zA-Z0-9\\s]/)) {
                        // User started typing, focus search field and pass the character
                        searchField.forceActiveFocus();
                        searchField.insertText(event.text);
                        event.accepted = true;
                    }
                }

                Column {
                    width: parent.width - Theme.spacingL * 2
                    height: parent.height - Theme.spacingL * 2
                    x: Theme.spacingL
                    y: Theme.spacingL
                    spacing: Theme.spacingL

                    Row {
                        width: parent.width
                        height: 40

                        StyledText {
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

                        StyledText {
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
                        ignoreLeftRightKeys: true
                        keyForwardTargets: [keyHandler]
                        onTextEdited: {
                            appLauncher.searchQuery = text;
                        }
                        Keys.onPressed: function(event) {
                            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && text.length > 0) {
                                if (appLauncher.keyboardNavigationActive && appLauncher.model.count > 0) {
                                    appLauncher.launchSelected();
                                } else if (appLauncher.model.count > 0) {
                                    var firstApp = appLauncher.model.get(0);
                                    appLauncher.launchApp(firstApp);
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up || event.key === Qt.Key_Left || event.key === Qt.Key_Right || ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && text.length === 0)) {
                                event.accepted = false;
                            }
                        }
                        Component.onCompleted: {
                            if (appDrawerPopout.isVisible)
                                searchField.forceActiveFocus();

                        }

                        Connections {
                            function onIsVisibleChanged() {
                                if (appDrawerPopout.isVisible)
                                    Qt.callLater(function() {
                                    searchField.forceActiveFocus();
                                });
                                else
                                    searchField.clearFocus();
                            }

                            target: appDrawerPopout
                        }

                    }

                    Row {
                        width: parent.width
                        height: 40
                        spacing: Theme.spacingM
                        visible: searchField.text.length === 0

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

                        Row {
                            spacing: 4
                            anchors.verticalCenter: parent.verticalCenter

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

                    // App grid/list container with enhanced styling
                    Rectangle {
                        width: parent.width
                        height: {
                            let usedHeight = 40 + Theme.spacingL;
                            usedHeight += 52 + Theme.spacingL;
                            usedHeight += (searchField.text.length === 0 ? 40 + Theme.spacingL : 0);
                            return parent.height - usedHeight;
                        }
                        radius: Theme.cornerRadiusLarge
                        color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.1)
                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.05)
                        border.width: 1

                        // List view
                        DankListView {
                            id: appList

                            anchors.fill: parent
                            anchors.margins: Theme.spacingS
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
                            anchors.margins: Theme.spacingS
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
