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
    property bool showCategories: false



    function show() {
        appDrawerPopout.isVisible = true;
        searchField.enabled = true;
        appLauncher.searchQuery = "";
    }

    function hide() {
        searchField.enabled = false; // Disable before hiding to prevent Wayland warnings
        appDrawerPopout.isVisible = false;
        searchField.text = "";
        showCategories = false;
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
        onViewModeSelected: Prefs.setAppLauncherViewMode(mode)
    }

    // Background dim with click to close
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.3)
        opacity: appDrawerPopout.isVisible ? 1 : 0
        visible: appDrawerPopout.isVisible

        MouseArea {
            anchors.fill: parent
            enabled: appDrawerPopout.isVisible
            onClicked: appDrawerPopout.hide()
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }

        }

    }

    Component {
        id: iconComponent

        Item {
            property var appData: parent.modelData || {
            }

            IconImage {
                id: iconImg

                anchors.fill: parent
                source: (appData && appData.icon) ? Quickshell.iconPath(appData.icon, "") : ""
                smooth: true
                asynchronous: true
                visible: status === Image.Ready
            }

            Rectangle {
                anchors.fill: parent
                visible: !iconImg.visible
                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
                radius: Theme.cornerRadiusLarge
                border.width: 1
                border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)

                Text {
                    anchors.centerIn: parent
                    text: (appData && appData.name && appData.name.length > 0) ? appData.name.charAt(0).toUpperCase() : "A"
                    font.pixelSize: 28
                    color: Theme.primary
                    font.weight: Font.Bold
                }

            }

        }

    }

    // Main launcher panel with enhanced design
    Rectangle {
        id: launcherPanel

        width: 520
        height: 600
        color: Theme.popupBackground()
        radius: Theme.cornerRadiusXLarge
        opacity: appDrawerPopout.isVisible ? 1 : 0
        x: appDrawerPopout.isVisible ? Theme.spacingL : Theme.spacingL - Anims.slidePx
        y: Theme.barHeight + Theme.spacingXS

        Behavior on x {
            NumberAnimation {
                duration: Anims.durMed
                easing.type: Easing.OutCubic
            }
        }

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
                } else if (event.text && event.text.length > 0 && event.text.match(/[a-zA-Z0-9\s]/)) {
                    // User started typing, focus search field and pass the character
                    searchField.forceActiveFocus();
                    searchField.text = event.text;
                    event.accepted = true;
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingXL
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

                    // Category filter
                    Rectangle {
                        width: 200
                        height: 36
                        radius: Theme.cornerRadius
                        color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, Theme.getContentBackgroundAlpha() * 0.4)
                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
                        border.width: 1

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "category"
                                size: 18
                                color: Theme.surfaceVariantText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: appLauncher.selectedCategory
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                                font.weight: Font.Medium
                            }

                        }

                        DankIcon {
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            name: showCategories ? "expand_less" : "expand_more"
                            size: 18
                            color: Theme.surfaceVariantText
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: showCategories = !showCategories
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
                        onItemClicked: function(index, modelData) {
                            appLauncher.launchApp(modelData);
                        }
                        onItemHovered: function(index) {
                            appLauncher.selectedIndex = index;
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
                        onItemClicked: function(index, modelData) {
                            appLauncher.launchApp(modelData);
                        }
                        onItemHovered: function(index) {
                            appLauncher.selectedIndex = index;
                        }
                    }

                }

                // Category dropdown overlay - now positioned absolutely
                Rectangle {
                    id: categoryDropdown

                    width: 200
                    height: Math.min(250, categories.length * 40 + Theme.spacingM * 2)
                    radius: Theme.cornerRadiusLarge
                    color: Theme.contentBackground()
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
                    border.width: 1
                    visible: showCategories
                    z: 1000
                    // Position it below the category button
                    anchors.top: parent.top
                    anchors.topMargin: 140 + (searchField.text.length === 0 ? 0 : -40)
                    anchors.left: parent.left

                    // Drop shadow
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -4
                        color: "transparent"
                        radius: parent.radius + 4
                        z: -1
                        layer.enabled: true

                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowHorizontalOffset: 0
                            shadowVerticalOffset: 0
                            shadowBlur: 0.25 // radius/32
                            shadowColor: Qt.rgba(0, 0, 0, 0.2)
                            shadowOpacity: 0.2
                        }

                    }

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        clip: true
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        ListView {
                            // Make mouse wheel scrolling more responsive
                            property real wheelStepSize: 60

                            model: appLauncher.categories
                            spacing: 4

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.NoButton
                                propagateComposedEvents: true
                                z: -1
                                onWheel: (wheel) => {
                                    var delta = wheel.angleDelta.y;
                                    var steps = delta / 120; // Standard wheel step
                                    parent.contentY -= steps * parent.wheelStepSize;
                                    // Ensure we stay within bounds
                                    if (parent.contentY < 0)
                                        parent.contentY = 0;
                                    else if (parent.contentY > parent.contentHeight - parent.height)
                                        parent.contentY = Math.max(0, parent.contentHeight - parent.height);
                                }
                            }

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 36
                                radius: Theme.cornerRadiusSmall
                                color: catArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : "transparent"

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: appLauncher.selectedCategory === modelData ? Theme.primary : Theme.surfaceText
                                    font.weight: appLauncher.selectedCategory === modelData ? Font.Medium : Font.Normal
                                }

                                MouseArea {
                                    id: catArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        appLauncher.setCategory(modelData);
                                        showCategories = false;
                                    }
                                }

                            }

                        }

                    }

                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: Anims.durShort
                easing.type: Easing.OutCubic
            }
        }

    }

}
