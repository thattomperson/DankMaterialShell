import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets

ScrollView {
    id: widgetsTab

    property var baseWidgetDefinitions: [{
        "id": "launcherButton",
        "text": "App Launcher",
        "description": "Quick access to application launcher",
        "icon": "apps",
        "enabled": true
    }, {
        "id": "workspaceSwitcher",
        "text": "Workspace Switcher",
        "description": "Shows current workspace and allows switching",
        "icon": "view_module",
        "enabled": true
    }, {
        "id": "focusedWindow",
        "text": "Focused Window",
        "description": "Display currently focused application title",
        "icon": "window",
        "enabled": true
    }, {
        "id": "clock",
        "text": "Clock",
        "description": "Current time and date display",
        "icon": "schedule",
        "enabled": true
    }, {
        "id": "weather",
        "text": "Weather Widget",
        "description": "Current weather conditions and temperature",
        "icon": "wb_sunny",
        "enabled": true
    }, {
        "id": "music",
        "text": "Media Controls",
        "description": "Control currently playing media",
        "icon": "music_note",
        "enabled": true
    }, {
        "id": "clipboard",
        "text": "Clipboard Manager",
        "description": "Access clipboard history",
        "icon": "content_paste",
        "enabled": true
    }, {
        "id": "systemResources",
        "text": "System Resources",
        "description": "CPU and memory usage indicators",
        "icon": "memory",
        "enabled": true
    }, {
        "id": "systemTray",
        "text": "System Tray",
        "description": "System notification area icons",
        "icon": "notifications",
        "enabled": true
    }, {
        "id": "controlCenterButton",
        "text": "Control Center",
        "description": "Access to system controls and settings",
        "icon": "settings",
        "enabled": true
    }, {
        "id": "notificationButton",
        "text": "Notification Center",
        "description": "Access to notifications and do not disturb",
        "icon": "notifications",
        "enabled": true
    }, {
        "id": "battery",
        "text": "Battery",
        "description": "Battery level and power management",
        "icon": "battery_std",
        "enabled": true
    }, {
        "id": "spacer",
        "text": "Spacer",
        "description": "Customizable empty space",
        "icon": "more_horiz",
        "enabled": true
    }, {
        "id": "separator",
        "text": "Separator",
        "description": "Visual divider between widgets",
        "icon": "remove",
        "enabled": true
    }]
    property var defaultLeftWidgets: [{
        "id": "launcherButton",
        "enabled": true
    }, {
        "id": "workspaceSwitcher",
        "enabled": true
    }, {
        "id": "focusedWindow",
        "enabled": true
    }]
    property var defaultCenterWidgets: [{
        "id": "music",
        "enabled": true
    }, {
        "id": "clock",
        "enabled": true
    }, {
        "id": "weather",
        "enabled": true
    }]
    property var defaultRightWidgets: [{
        "id": "systemTray",
        "enabled": true
    }, {
        "id": "clipboard",
        "enabled": true
    }, {
        "id": "systemResources",
        "enabled": true
    }, {
        "id": "notificationButton",
        "enabled": true
    }, {
        "id": "battery",
        "enabled": true
    }, {
        "id": "controlCenterButton",
        "enabled": true
    }]

    function addWidgetToSection(widgetId, targetSection) {
        var widgetObj = {
            "id": widgetId,
            "enabled": true
        };
        if (widgetId === "spacer")
            widgetObj.size = 20;

        var widgets = [];
        if (targetSection === "left") {
            widgets = Prefs.topBarLeftWidgets.slice();
            widgets.push(widgetObj);
            Prefs.setTopBarLeftWidgets(widgets);
        } else if (targetSection === "center") {
            widgets = Prefs.topBarCenterWidgets.slice();
            widgets.push(widgetObj);
            Prefs.setTopBarCenterWidgets(widgets);
        } else if (targetSection === "right") {
            widgets = Prefs.topBarRightWidgets.slice();
            widgets.push(widgetObj);
            Prefs.setTopBarRightWidgets(widgets);
        }
    }

    function removeWidgetFromSection(sectionId, itemId) {
        var widgets = [];
        if (sectionId === "left") {
            widgets = Prefs.topBarLeftWidgets.slice();
            widgets = widgets.filter((widget) => {
                var widgetId = typeof widget === "string" ? widget : widget.id;
                return widgetId !== itemId;
            });
            Prefs.setTopBarLeftWidgets(widgets);
        } else if (sectionId === "center") {
            widgets = Prefs.topBarCenterWidgets.slice();
            widgets = widgets.filter((widget) => {
                var widgetId = typeof widget === "string" ? widget : widget.id;
                return widgetId !== itemId;
            });
            Prefs.setTopBarCenterWidgets(widgets);
        } else if (sectionId === "right") {
            widgets = Prefs.topBarRightWidgets.slice();
            widgets = widgets.filter((widget) => {
                var widgetId = typeof widget === "string" ? widget : widget.id;
                return widgetId !== itemId;
            });
            Prefs.setTopBarRightWidgets(widgets);
        }
    }

    function handleItemEnabledChanged(sectionId, itemId, enabled) {
        var widgets = [];
        if (sectionId === "left")
            widgets = Prefs.topBarLeftWidgets.slice();
        else if (sectionId === "center")
            widgets = Prefs.topBarCenterWidgets.slice();
        else if (sectionId === "right")
            widgets = Prefs.topBarRightWidgets.slice();
        for (var i = 0; i < widgets.length; i++) {
            var widget = widgets[i];
            var widgetId = typeof widget === "string" ? widget : widget.id;
            if (widgetId === itemId) {
                widgets[i] = typeof widget === "string" ? {
                    "id": widget,
                    "enabled": enabled
                } : {
                    "id": widget.id,
                    "enabled": enabled,
                    "size": widget.size
                };
                break;
            }
        }
        if (sectionId === "left")
            Prefs.setTopBarLeftWidgets(widgets);
        else if (sectionId === "center")
            Prefs.setTopBarCenterWidgets(widgets);
        else if (sectionId === "right")
            Prefs.setTopBarRightWidgets(widgets);
    }

    function handleItemOrderChanged(sectionId, newOrder) {
        if (sectionId === "left")
            Prefs.setTopBarLeftWidgets(newOrder);
        else if (sectionId === "center")
            Prefs.setTopBarCenterWidgets(newOrder);
        else if (sectionId === "right")
            Prefs.setTopBarRightWidgets(newOrder);
    }

    function handleSpacerSizeChanged(sectionId, itemId, newSize) {
        var widgets = [];
        if (sectionId === "left")
            widgets = Prefs.topBarLeftWidgets.slice();
        else if (sectionId === "center")
            widgets = Prefs.topBarCenterWidgets.slice();
        else if (sectionId === "right")
            widgets = Prefs.topBarRightWidgets.slice();
        for (var i = 0; i < widgets.length; i++) {
            var widget = widgets[i];
            var widgetId = typeof widget === "string" ? widget : widget.id;
            if (widgetId === itemId && widgetId === "spacer") {
                widgets[i] = typeof widget === "string" ? {
                    "id": widget,
                    "enabled": true,
                    "size": newSize
                } : {
                    "id": widget.id,
                    "enabled": widget.enabled,
                    "size": newSize
                };
                break;
            }
        }
        if (sectionId === "left")
            Prefs.setTopBarLeftWidgets(widgets);
        else if (sectionId === "center")
            Prefs.setTopBarCenterWidgets(widgets);
        else if (sectionId === "right")
            Prefs.setTopBarRightWidgets(widgets);
    }

    function getItemsForSection(sectionId) {
        var widgets = [];
        var widgetData = [];
        if (sectionId === "left")
            widgetData = Prefs.topBarLeftWidgets || [];
        else if (sectionId === "center")
            widgetData = Prefs.topBarCenterWidgets || [];
        else if (sectionId === "right")
            widgetData = Prefs.topBarRightWidgets || [];
        widgetData.forEach((widget) => {
            var widgetId = typeof widget === "string" ? widget : widget.id;
            var widgetEnabled = typeof widget === "string" ? true : widget.enabled;
            var widgetSize = typeof widget === "string" ? undefined : widget.size;
            var widgetDef = baseWidgetDefinitions.find((w) => {
                return w.id === widgetId;
            });
            if (widgetDef) {
                var item = Object.assign({
                }, widgetDef);
                item.enabled = widgetEnabled;
                if (widgetSize !== undefined)
                    item.size = widgetSize;

                widgets.push(item);
            }
        });
        return widgets;
    }

    contentHeight: column.implicitHeight + Theme.spacingXL
    clip: true
    Component.onCompleted: {
        if (!Prefs.topBarLeftWidgets || Prefs.topBarLeftWidgets.length === 0)
            Prefs.setTopBarLeftWidgets(defaultLeftWidgets);

        if (!Prefs.topBarCenterWidgets || Prefs.topBarCenterWidgets.length === 0)
            Prefs.setTopBarCenterWidgets(defaultCenterWidgets);

        if (!Prefs.topBarRightWidgets || Prefs.topBarRightWidgets.length === 0)
            Prefs.setTopBarRightWidgets(defaultRightWidgets);

        ["left", "center", "right"].forEach((sectionId) => {
            var widgets = [];
            if (sectionId === "left")
                widgets = Prefs.topBarLeftWidgets.slice();
            else if (sectionId === "center")
                widgets = Prefs.topBarCenterWidgets.slice();
            else if (sectionId === "right")
                widgets = Prefs.topBarRightWidgets.slice();
            var updated = false;
            for (var i = 0; i < widgets.length; i++) {
                var widget = widgets[i];
                if (typeof widget === "object" && widget.id === "spacer" && !widget.size) {
                    widgets[i] = Object.assign({
                    }, widget, {
                        "size": 20
                    });
                    updated = true;
                }
            }
            if (updated) {
                if (sectionId === "left")
                    Prefs.setTopBarLeftWidgets(widgets);
                else if (sectionId === "center")
                    Prefs.setTopBarCenterWidgets(widgets);
                else if (sectionId === "right")
                    Prefs.setTopBarRightWidgets(widgets);
            }
        });
    }

    Column {
        id: column

        width: parent.width
        spacing: Theme.spacingXL
        topPadding: Theme.spacingL
        bottomPadding: Theme.spacingXL

        Row {
            width: parent.width
            spacing: Theme.spacingM

            DankIcon {
                name: "widgets"
                size: Theme.iconSize
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: "Top Bar Widget Management"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Medium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                width: parent.width - 400
                height: 1
            }

            Rectangle {
                width: 80
                height: 28
                radius: Theme.cornerRadius
                color: resetArea.containsMouse ? Theme.surfacePressed : Theme.surfaceVariant
                anchors.verticalCenter: parent.verticalCenter
                border.width: 1
                border.color: resetArea.containsMouse ? Theme.outline : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.5)

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingXS

                    DankIcon {
                        name: "refresh"
                        size: 14
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "Reset"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                MouseArea {
                    id: resetArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Prefs.setTopBarLeftWidgets(defaultLeftWidgets);
                        Prefs.setTopBarCenterWidgets(defaultCenterWidgets);
                        Prefs.setTopBarRightWidgets(defaultRightWidgets);
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }

                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }

                }

            }

        }

        Rectangle {
            width: parent.width
            height: messageText.contentHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            border.width: 1
            visible: true
            opacity: 1
            z: 1

            StyledText {
                id: messageText

                anchors.centerIn: parent
                text: "Drag widgets to reorder within sections. Use the eye icon to hide/show widgets (maintains spacing), or X to remove them completely."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.outline
                width: parent.width - Theme.spacingM * 2
                wrapMode: Text.WordWrap
            }

        }

        Column {
            width: parent.width
            spacing: Theme.spacingL

            DankSections {
                width: parent.width
                title: "Left Section"
                titleIcon: "format_align_left"
                sectionId: "left"
                allWidgets: widgetsTab.baseWidgetDefinitions
                items: widgetsTab.getItemsForSection("left")
                onItemEnabledChanged: (sectionId, itemId, enabled) => {
                    widgetsTab.handleItemEnabledChanged(sectionId, itemId, enabled);
                }
                onItemOrderChanged: (newOrder) => {
                    widgetsTab.handleItemOrderChanged("left", newOrder);
                }
                onAddWidget: (sectionId) => {
                    widgetSelectionPopup.allWidgets = widgetsTab.baseWidgetDefinitions;
                    widgetSelectionPopup.targetSection = sectionId;
                    widgetSelectionPopup.safeOpen();
                }
                onRemoveWidget: (sectionId, itemId) => {
                    widgetsTab.removeWidgetFromSection(sectionId, itemId);
                }
                onSpacerSizeChanged: (sectionId, itemId, newSize) => {
                    widgetsTab.handleSpacerSizeChanged(sectionId, itemId, newSize);
                }
            }

            DankSections {
                width: parent.width
                title: "Center Section"
                titleIcon: "format_align_center"
                sectionId: "center"
                allWidgets: widgetsTab.baseWidgetDefinitions
                items: widgetsTab.getItemsForSection("center")
                onItemEnabledChanged: (sectionId, itemId, enabled) => {
                    widgetsTab.handleItemEnabledChanged(sectionId, itemId, enabled);
                }
                onItemOrderChanged: (newOrder) => {
                    widgetsTab.handleItemOrderChanged("center", newOrder);
                }
                onAddWidget: (sectionId) => {
                    widgetSelectionPopup.allWidgets = widgetsTab.baseWidgetDefinitions;
                    widgetSelectionPopup.targetSection = sectionId;
                    widgetSelectionPopup.safeOpen();
                }
                onRemoveWidget: (sectionId, itemId) => {
                    widgetsTab.removeWidgetFromSection(sectionId, itemId);
                }
                onSpacerSizeChanged: (sectionId, itemId, newSize) => {
                    widgetsTab.handleSpacerSizeChanged(sectionId, itemId, newSize);
                }
            }

            DankSections {
                width: parent.width
                title: "Right Section"
                titleIcon: "format_align_right"
                sectionId: "right"
                allWidgets: widgetsTab.baseWidgetDefinitions
                items: widgetsTab.getItemsForSection("right")
                onItemEnabledChanged: (sectionId, itemId, enabled) => {
                    widgetsTab.handleItemEnabledChanged(sectionId, itemId, enabled);
                }
                onItemOrderChanged: (newOrder) => {
                    widgetsTab.handleItemOrderChanged("right", newOrder);
                }
                onAddWidget: (sectionId) => {
                    widgetSelectionPopup.allWidgets = widgetsTab.baseWidgetDefinitions;
                    widgetSelectionPopup.targetSection = sectionId;
                    widgetSelectionPopup.safeOpen();
                }
                onRemoveWidget: (sectionId, itemId) => {
                    widgetsTab.removeWidgetFromSection(sectionId, itemId);
                }
                onSpacerSizeChanged: (sectionId, itemId, newSize) => {
                    widgetsTab.handleSpacerSizeChanged(sectionId, itemId, newSize);
                }
            }

        }

        StyledRect {
            width: parent.width
            height: workspaceSection.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadiusLarge
            color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            border.width: 1

            Column {
                id: workspaceSection

                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    DankIcon {
                        name: "view_module"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "Workspace Settings"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                DankToggle {
                    width: parent.width
                    text: "Workspace Index Numbers"
                    description: "Show workspace index numbers in the top bar workspace switcher"
                    checked: Prefs.showWorkspaceIndex
                    onToggled: (checked) => {
                        return Prefs.setShowWorkspaceIndex(checked);
                    }
                }

                DankToggle {
                    width: parent.width
                    text: "Workspace Padding"
                    description: "Always show a minimum of 3 workspaces, even if fewer are available"
                    checked: Prefs.showWorkspacePadding
                    onToggled: (checked) => {
                        return Prefs.setShowWorkspacePadding(checked);
                    }
                }

            }

        }

    }

    Rectangle {
        width: tooltipText.contentWidth + Theme.spacingM * 2
        height: tooltipText.contentHeight + Theme.spacingS * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainer
        border.color: Theme.outline
        border.width: 1
        visible: resetArea.containsMouse
        opacity: resetArea.containsMouse ? 1 : 0
        y: column.y + 48 // Position above the reset button in the header
        x: parent.width - width - Theme.spacingM
        z: 100

        StyledText {
            id: tooltipText

            anchors.centerIn: parent
            text: "Reset widget layout to defaults"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceText
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }

        }

    }

    DankWidgetSelectionPopup {
        id: widgetSelectionPopup

        anchors.centerIn: parent
        onWidgetSelected: (widgetId, targetSection) => {
            widgetsTab.addWidgetToSection(widgetId, targetSection);
        }
    }

}
