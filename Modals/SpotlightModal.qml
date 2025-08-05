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
        
        spotlightOpen = true;
        
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
        
        if (visible && !spotlightOpen)
            show();

    }
    onBackgroundClicked: {
        spotlightOpen = false;
    }
    Component.onCompleted: {
        
    }

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
            
            spotlightModal.show();
            return "SPOTLIGHT_OPEN_SUCCESS";
        }

        function close() {
            
            spotlightModal.hide();
            return "SPOTLIGHT_CLOSE_SUCCESS";
        }

        function toggle() {
            
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
                                if (appLauncher.keyboardNavigationActive && appLauncher.model.count > 0)
                                    appLauncher.launchSelected();
                                else if (appLauncher.model.count > 0)
                                    appLauncher.launchApp(appLauncher.model.get(0));
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up || event.key === Qt.Key_Left || event.key === Qt.Key_Right || ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && text.length === 0)) {
                                event.accepted = false;
                            }
                        }

                        Connections {
                            function onSpotlightOpenChanged() {
                                if (spotlightModal.spotlightOpen) {
                                    Qt.callLater(function() {
                                        searchField.forceActiveFocus();
                                    });
                                }
                            }

                            target: spotlightModal
                        }

                    }

                    Row {
                        spacing: Theme.spacingXS
                        visible: appLauncher.model.count > 0
                        anchors.verticalCenter: parent.verticalCenter

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
                        onItemRightClicked: function(index, modelData, mouseX, mouseY) {
                            contextMenu.show(mouseX, mouseY, modelData)
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
                        onItemRightClicked: function(index, modelData, mouseX, mouseY) {
                            contextMenu.show(mouseX, mouseY, modelData)
                        }
                        onKeyboardNavigationReset: {
                            appLauncher.keyboardNavigationActive = false;
                        }
                    }

                }

            }

        }

    }
    
    Popup {
        id: contextMenu
        
        property var currentApp: null
        
        function show(x, y, app) {
            currentApp = app
            if (!contextMenu.parent && typeof Overlay !== "undefined" && Overlay.overlay)
                contextMenu.parent = Overlay.overlay;
            
            const menuWidth = 180;
            const menuHeight = menuColumn.implicitHeight + Theme.spacingS * 2;
            const screenWidth = Screen.width;
            const screenHeight = Screen.height;
            let finalX = x;
            let finalY = y;
            if (x + menuWidth > screenWidth - 20)
                finalX = x - menuWidth;
            
            if (y + menuHeight > screenHeight - 20)
                finalY = y - menuHeight;
            
            contextMenu.x = Math.max(20, finalX);
            contextMenu.y = Math.max(20, finalY);
            open();
        }
        
        width: 180
        height: menuColumn.implicitHeight + Theme.spacingS * 2
        padding: 0
        modal: false
        closePolicy: Popup.CloseOnEscape
        onClosed: {
            closePolicy = Popup.CloseOnEscape;
        }
        onOpened: {
            outsideClickTimer.start();
        }
        
        Timer {
            id: outsideClickTimer
            interval: 100
            onTriggered: {
                contextMenu.closePolicy = Popup.CloseOnEscape | Popup.CloseOnPressOutside;
            }
        }
        
        background: Rectangle {
            color: "transparent"
        }
        
        contentItem: Rectangle {
            color: Theme.popupBackground()
            radius: Theme.cornerRadiusLarge
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
            border.width: 1
            
            Column {
                id: menuColumn
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                spacing: 1
                
                Rectangle {
                    width: parent.width
                    height: 32
                    radius: Theme.cornerRadiusSmall
                    color: pinMouseArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                    
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingS
                        
                        DankIcon {
                            name: {
                                if (!contextMenu.currentApp || !contextMenu.currentApp.desktopEntry) return "push_pin"
                                var appId = contextMenu.currentApp.desktopEntry.id || contextMenu.currentApp.desktopEntry.execString || ""
                                return Prefs.isPinnedApp(appId) ? "keep_off" : "push_pin"
                            }
                            size: Theme.iconSize - 2
                            color: Theme.surfaceText
                            opacity: 0.7
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        StyledText {
                            text: {
                                if (!contextMenu.currentApp || !contextMenu.currentApp.desktopEntry) return "Pin to Dock"
                                var appId = contextMenu.currentApp.desktopEntry.id || contextMenu.currentApp.desktopEntry.execString || ""
                                return Prefs.isPinnedApp(appId) ? "Unpin from Dock" : "Pin to Dock"
                            }
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Normal
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    MouseArea {
                        id: pinMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!contextMenu.currentApp || !contextMenu.currentApp.desktopEntry) return
                            var appId = contextMenu.currentApp.desktopEntry.id || contextMenu.currentApp.desktopEntry.execString || ""
                            if (Prefs.isPinnedApp(appId)) {
                                Prefs.removePinnedApp(appId)
                            } else {
                                Prefs.addPinnedApp(appId)
                            }
                            contextMenu.close()
                        }
                    }
                }
                
                Rectangle {
                    width: parent.width - Theme.spacingS * 2
                    height: 5
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "transparent"
                    
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: 1
                        color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                    }
                }
                
                Rectangle {
                    width: parent.width
                    height: 32
                    radius: Theme.cornerRadiusSmall
                    color: launchMouseArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                    
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingS
                        
                        DankIcon {
                            name: "launch"
                            size: Theme.iconSize - 2
                            color: Theme.surfaceText
                            opacity: 0.7
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        StyledText {
                            text: "Launch"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Normal
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    MouseArea {
                        id: launchMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (contextMenu.currentApp) {
                                appLauncher.launchApp(contextMenu.currentApp)
                            }
                            contextMenu.close()
                        }
                    }
                }
            }
        }
    }

}
