import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets

ScrollView {
    id: widgetsTab

    contentHeight: column.implicitHeight + Theme.spacingXL
    clip: true

    property var baseWidgetDefinitions: [
        {
            id: "launcherButton",
            text: "App Launcher",
            description: "Quick access to application launcher",
            icon: "apps",
            enabled: true
        },
        {
            id: "workspaceSwitcher", 
            text: "Workspace Switcher",
            description: "Shows current workspace and allows switching",
            icon: "view_module",
            enabled: true
        },
        {
            id: "focusedWindow",
            text: "Focused Window",
            description: "Display currently focused application title",
            icon: "window",
            enabled: true
        },
        {
            id: "clock",
            text: "Clock",
            description: "Current time and date display",
            icon: "schedule",
            enabled: true
        },
        {
            id: "weather",
            text: "Weather Widget",
            description: "Current weather conditions and temperature",
            icon: "wb_sunny",
            enabled: true
        },
        {
            id: "music",
            text: "Media Controls",
            description: "Control currently playing media",
            icon: "music_note",
            enabled: true
        },
        {
            id: "clipboard",
            text: "Clipboard Manager",
            description: "Access clipboard history",
            icon: "content_paste",
            enabled: true
        },
        {
            id: "systemResources",
            text: "System Resources",
            description: "CPU and memory usage indicators",
            icon: "memory",
            enabled: true
        },
        {
            id: "systemTray",
            text: "System Tray",
            description: "System notification area icons",
            icon: "notifications",
            enabled: true
        },
        {
            id: "controlCenterButton",
            text: "Control Center",
            description: "Access to system controls and settings",
            icon: "settings",
            enabled: true
        },
        {
            id: "notificationButton",
            text: "Notification Center",
            description: "Access to notifications and do not disturb",
            icon: "notifications",
            enabled: true
        },
        {
            id: "battery",
            text: "Battery",
            description: "Battery level and power management",
            icon: "battery_std",
            enabled: true
        },
        {
            id: "spacer",
            text: "Spacer",
            description: "Empty space to separate widgets",
            icon: "more_horiz",
            enabled: true
        },
        {
            id: "separator",
            text: "Separator",
            description: "Visual divider between widgets",
            icon: "remove",
            enabled: true
        }
    ]

    // Default widget configurations for each section
    property var defaultLeftWidgets: ["launcherButton", "workspaceSwitcher", "focusedWindow"]
    property var defaultCenterWidgets: ["music", "clock", "weather"]
    property var defaultRightWidgets: ["systemTray", "clipboard", "systemResources", "notificationButton", "battery", "controlCenterButton"]

    Component.onCompleted: {
        // Initialize sections with defaults if they're empty
        if (!Prefs.topBarLeftWidgets || Prefs.topBarLeftWidgets.length === 0) {
            Prefs.setTopBarLeftWidgets(defaultLeftWidgets)
        }
        if (!Prefs.topBarCenterWidgets || Prefs.topBarCenterWidgets.length === 0) {
            Prefs.setTopBarCenterWidgets(defaultCenterWidgets)
        }
        if (!Prefs.topBarRightWidgets || Prefs.topBarRightWidgets.length === 0) {
            Prefs.setTopBarRightWidgets(defaultRightWidgets)
        }
    }

    function addWidgetToSection(widgetId, targetSection) {
        var leftWidgets = Prefs.topBarLeftWidgets.slice()
        var centerWidgets = Prefs.topBarCenterWidgets.slice()
        var rightWidgets = Prefs.topBarRightWidgets.slice()

        if (targetSection === "left") {
            leftWidgets.push(widgetId)
            Prefs.setTopBarLeftWidgets(leftWidgets)
        } else if (targetSection === "center") {
            centerWidgets.push(widgetId)
            Prefs.setTopBarCenterWidgets(centerWidgets)
        } else if (targetSection === "right") {
            rightWidgets.push(widgetId)
            Prefs.setTopBarRightWidgets(rightWidgets)
        }
    }

    function removeLastWidgetFromSection(sectionId) {
        var leftWidgets = Prefs.topBarLeftWidgets.slice()
        var centerWidgets = Prefs.topBarCenterWidgets.slice()
        var rightWidgets = Prefs.topBarRightWidgets.slice()

        if (sectionId === "left" && leftWidgets.length > 0) {
            leftWidgets.pop()
            Prefs.setTopBarLeftWidgets(leftWidgets)
        } else if (sectionId === "center" && centerWidgets.length > 0) {
            centerWidgets.pop()
            Prefs.setTopBarCenterWidgets(centerWidgets)
        } else if (sectionId === "right" && rightWidgets.length > 0) {
            rightWidgets.pop()
            Prefs.setTopBarRightWidgets(rightWidgets)
        }
    }

    function handleItemEnabledChanged(itemId, enabled) {
        // Update the widget's enabled state in preferences
        if (itemId === "focusedWindow") {
            Prefs.setShowFocusedWindow(enabled)
        } else if (itemId === "weather") {
            Prefs.setShowWeather(enabled)
        } else if (itemId === "music") {
            Prefs.setShowMusic(enabled)
        } else if (itemId === "clipboard") {
            Prefs.setShowClipboard(enabled)
        } else if (itemId === "systemResources") {
            Prefs.setShowSystemResources(enabled)
        } else if (itemId === "systemTray") {
            Prefs.setShowSystemTray(enabled)
        } else if (itemId === "clock") {
            Prefs.setShowClock(enabled)
        } else if (itemId === "notificationButton") {
            Prefs.setShowNotificationButton(enabled)
        } else if (itemId === "controlCenterButton") {
            Prefs.setShowControlCenterButton(enabled)
        } else if (itemId === "battery") {
            Prefs.setShowBattery(enabled)
        } else if (itemId === "launcherButton") {
            Prefs.setShowLauncherButton(enabled)
        } else if (itemId === "workspaceSwitcher") {
            Prefs.setShowWorkspaceSwitcher(enabled)
        }
        // Note: spacer and separator don't need preference handling as they're always enabled
    }

    function handleItemOrderChanged(sectionId, newOrder) {
        if (sectionId === "left") {
            Prefs.setTopBarLeftWidgets(newOrder)
        } else if (sectionId === "center") {
            Prefs.setTopBarCenterWidgets(newOrder)
        } else if (sectionId === "right") {
            Prefs.setTopBarRightWidgets(newOrder)
        }
    }

    function getItemsForSection(sectionId) {
        var widgets = []
        var widgetIds = []
        
        if (sectionId === "left") {
            widgetIds = Prefs.topBarLeftWidgets || []
        } else if (sectionId === "center") {
            widgetIds = Prefs.topBarCenterWidgets || []
        } else if (sectionId === "right") {
            widgetIds = Prefs.topBarRightWidgets || []
        }
        
        widgetIds.forEach(widgetId => {
            var widgetDef = baseWidgetDefinitions.find(w => w.id === widgetId)
            if (widgetDef) {
                var item = Object.assign({}, widgetDef)
                // Set enabled state based on preferences
                if (widgetId === "focusedWindow") {
                    item.enabled = Prefs.showFocusedWindow
                } else if (widgetId === "weather") {
                    item.enabled = Prefs.showWeather
                } else if (widgetId === "music") {
                    item.enabled = Prefs.showMusic
                } else if (widgetId === "clipboard") {
                    item.enabled = Prefs.showClipboard
                } else if (widgetId === "systemResources") {
                    item.enabled = Prefs.showSystemResources
                } else if (widgetId === "systemTray") {
                    item.enabled = Prefs.showSystemTray
                } else if (widgetId === "clock") {
                    item.enabled = Prefs.showClock
                } else if (widgetId === "notificationButton") {
                    item.enabled = Prefs.showNotificationButton
                } else if (widgetId === "controlCenterButton") {
                    item.enabled = Prefs.showControlCenterButton
                } else if (widgetId === "battery") {
                    item.enabled = Prefs.showBattery
                } else if (widgetId === "launcherButton") {
                    item.enabled = Prefs.showLauncherButton
                } else if (widgetId === "workspaceSwitcher") {
                    item.enabled = Prefs.showWorkspaceSwitcher
                }
                // spacer and separator are always enabled (no preference toggle needed)
                widgets.push(item)
            }
        })
        
        return widgets
    }

    Column {
        id: column

        width: parent.width
        spacing: Theme.spacingXL
        topPadding: Theme.spacingL
        bottomPadding: Theme.spacingXL

        // Header section
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
                        // Reset all sections to defaults
                        Prefs.setTopBarLeftWidgets(defaultLeftWidgets)
                        Prefs.setTopBarCenterWidgets(defaultCenterWidgets)
                        Prefs.setTopBarRightWidgets(defaultRightWidgets)
                        
                        // Reset all widget enabled states to defaults (all enabled)
                        Prefs.setShowFocusedWindow(true)
                        Prefs.setShowWeather(true)
                        Prefs.setShowMusic(true)
                        Prefs.setShowClipboard(true)
                        Prefs.setShowSystemResources(true)
                        Prefs.setShowSystemTray(true)
                        Prefs.setShowClock(true)
                        Prefs.setShowNotificationButton(true)
                        Prefs.setShowControlCenterButton(true)
                        Prefs.setShowBattery(true)
                        Prefs.setShowLauncherButton(true)
                        Prefs.setShowWorkspaceSwitcher(true)
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
            opacity: 1.0
            z: 1

            StyledText {
                id: messageText
                anchors.centerIn: parent
                text: "Drag widgets to reorder within sections. Use + to add widgets and - to remove the last widget from each section."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.outline
                width: parent.width - Theme.spacingM * 2
                wrapMode: Text.WordWrap
            }
        }

        // Widget sections
        Column {
            width: parent.width
            spacing: Theme.spacingL

            // Left Section
            DankSections {
                width: parent.width
                title: "Left Section"
                titleIcon: "format_align_left"
                sectionId: "left"
                allWidgets: widgetsTab.baseWidgetDefinitions
                items: widgetsTab.getItemsForSection("left")

                onItemEnabledChanged: (itemId, enabled) => {
                    widgetsTab.handleItemEnabledChanged(itemId, enabled)
                }

                onItemOrderChanged: (newOrder) => {
                    widgetsTab.handleItemOrderChanged("left", newOrder)
                }

                onAddWidget: (sectionId) => {
                    widgetSelectionPopup.allWidgets = widgetsTab.baseWidgetDefinitions
                    widgetSelectionPopup.targetSection = sectionId
                    widgetSelectionPopup.safeOpen()
                }

                onRemoveLastWidget: (sectionId) => {
                    widgetsTab.removeLastWidgetFromSection(sectionId)
                }
            }

            // Center Section
            DankSections {
                width: parent.width
                title: "Center Section"
                titleIcon: "format_align_center"
                sectionId: "center"
                allWidgets: widgetsTab.baseWidgetDefinitions
                items: widgetsTab.getItemsForSection("center")

                onItemEnabledChanged: (itemId, enabled) => {
                    widgetsTab.handleItemEnabledChanged(itemId, enabled)
                }

                onItemOrderChanged: (newOrder) => {
                    widgetsTab.handleItemOrderChanged("center", newOrder)
                }

                onAddWidget: (sectionId) => {
                    widgetSelectionPopup.allWidgets = widgetsTab.baseWidgetDefinitions
                    widgetSelectionPopup.targetSection = sectionId
                    widgetSelectionPopup.safeOpen()
                }

                onRemoveLastWidget: (sectionId) => {
                    widgetsTab.removeLastWidgetFromSection(sectionId)
                }
            }

            // Right Section
            DankSections {
                width: parent.width
                title: "Right Section"
                titleIcon: "format_align_right"
                sectionId: "right"
                allWidgets: widgetsTab.baseWidgetDefinitions
                items: widgetsTab.getItemsForSection("right")

                onItemEnabledChanged: (itemId, enabled) => {
                    widgetsTab.handleItemEnabledChanged(itemId, enabled)
                }

                onItemOrderChanged: (newOrder) => {
                    widgetsTab.handleItemOrderChanged("right", newOrder)
                }

                onAddWidget: (sectionId) => {
                    widgetSelectionPopup.allWidgets = widgetsTab.baseWidgetDefinitions
                    widgetSelectionPopup.targetSection = sectionId
                    widgetSelectionPopup.safeOpen()
                }

                onRemoveLastWidget: (sectionId) => {
                    widgetsTab.removeLastWidgetFromSection(sectionId)
                }
            }
        }

        // Workspace Section
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

    // Tooltip for reset button (positioned above the button)
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

    // Widget selection popup
    DankWidgetSelectionPopup {
        id: widgetSelectionPopup
        anchors.centerIn: parent

        onWidgetSelected: (widgetId, targetSection) => {
            widgetsTab.addWidgetToSection(widgetId, targetSection)
        }
    }
}