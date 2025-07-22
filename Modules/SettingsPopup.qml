import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Widgets

PanelWindow {
    id: settingsPopup

    property bool settingsVisible: false

    signal closingPopup()

    onSettingsVisibleChanged: {
        if (!settingsVisible) {
            closingPopup();
            // Hide any open dropdown when settings close
            if (typeof globalDropdownWindow !== 'undefined') {
                globalDropdownWindow.hide();
            }
        }
    }
    visible: settingsVisible
    implicitWidth: 600
    implicitHeight: 700
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"

    // SettingsDropdown component - only used within this popup
    Component {
        id: settingsDropdownComponent
        
        Rectangle {
            id: dropdownRoot

            property string text: ""
            property string description: ""
            property string currentValue: ""
            property var options: []

            signal valueChanged(string value)

            width: parent.width
            height: 60
            radius: Theme.cornerRadius
            color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08)

            Column {
                anchors.left: parent.left
                anchors.right: dropdown.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Theme.spacingM
                anchors.rightMargin: Theme.spacingM
                spacing: Theme.spacingXS

                Text {
                    text: dropdownRoot.text
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    font.weight: Font.Medium
                }

                Text {
                    text: dropdownRoot.description
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    visible: description.length > 0
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }

            Rectangle {
                id: dropdown
                
                width: 180
                height: 36
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacingM
                anchors.verticalCenter: parent.verticalCenter
                radius: Theme.cornerRadiusSmall
                color: dropdownArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Theme.contentBackground()
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 1

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Theme.spacingM
                    anchors.rightMargin: Theme.spacingS

                    Text {
                        text: dropdownRoot.currentValue
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 24
                        elide: Text.ElideRight
                    }

                    DankIcon {
                        name: "expand_more"
                        size: 20
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: dropdownArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof globalDropdownWindow !== 'undefined') {
                            // Get global position of the dropdown button
                            var globalPos = dropdown.mapToGlobal(0, 0);
                            globalDropdownWindow.showAt(dropdownRoot, globalPos.x, globalPos.y + dropdown.height + 4, dropdownRoot.options, dropdownRoot.currentValue);
                            
                            // Connect to value selection (with cleanup)
                            globalDropdownWindow.valueSelected.connect(function(value) {
                                dropdownRoot.currentValue = value;
                                dropdownRoot.valueChanged(value);
                            });
                        }
                    }
                }
            }
        }
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // Darkened background
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.5

        MouseArea {
            anchors.fill: parent
            onClicked: settingsPopup.settingsVisible = false
        }

    }

    // Main settings panel - spotlight-like centered appearance
    Rectangle {
        id: mainPanel

        width: Math.min(600, parent.width - Theme.spacingXL * 2)
        height: Math.min(700, parent.height - Theme.spacingXL * 2)
        anchors.centerIn: parent
        color: Theme.popupBackground()
        radius: Theme.cornerRadiusLarge
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
        border.width: 1
        // Simple opacity and scale control tied directly to settingsVisible
        opacity: settingsPopup.settingsVisible ? 1 : 0
        scale: settingsPopup.settingsVisible ? 1 : 0.95
        // Add shadow effect
        layer.enabled: true

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingL

            // Header
            Row {
                width: parent.width
                spacing: Theme.spacingM

                DankIcon {
                    name: "settings"
                    size: Theme.iconSize
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Settings"
                    font.pixelSize: Theme.fontSizeXLarge
                    color: Theme.surfaceText
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    width: parent.width - 175 // Spacer to push close button to the right
                    height: 1
                }

                // Close button
                DankActionButton {
                    circular: false
                    iconName: "close"
                    iconSize: Theme.iconSize - 4
                    iconColor: Theme.surfaceText
                    hoverColor: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12)
                    onClicked: settingsPopup.settingsVisible = false
                }

            }

            // Settings sections
            Flickable {
                id: settingsScrollView
                width: parent.width
                height: parent.height - 80
                clip: true
                contentHeight: settingsColumn.height
                boundsBehavior: Flickable.DragAndOvershootBounds
                flickDeceleration: 8000
                maximumFlickVelocity: 15000
                
                property real wheelStepSize: 60

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    propagateComposedEvents: true
                    z: -1
                    onWheel: (wheel) => {
                        var delta = wheel.angleDelta.y
                        var steps = delta / 120
                        settingsScrollView.contentY -= steps * settingsScrollView.wheelStepSize
                        
                        // Keep within bounds
                        if (settingsScrollView.contentY < 0)
                            settingsScrollView.contentY = 0
                        else if (settingsScrollView.contentY > settingsScrollView.contentHeight - settingsScrollView.height)
                            settingsScrollView.contentY = Math.max(0, settingsScrollView.contentHeight - settingsScrollView.height)
                    }
                }

                Column {
                    id: settingsColumn
                    width: parent.width
                    spacing: Theme.spacingL

                    // Profile Settings
                    SettingsSection {
                        title: "Profile"
                        iconName: "person"

                        content: Column {
                            width: parent.width
                            spacing: Theme.spacingM

                            // Profile Image Preview and Input
                            Column {
                                width: parent.width
                                spacing: Theme.spacingM

                                Text {
                                    text: "Profile Image"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    font.weight: Font.Medium
                                }

                                // Profile Image Preview with circular crop
                                Row {
                                    width: parent.width
                                    spacing: Theme.spacingM

                                    // Circular profile image preview
                                    Item {
                                        id: avatarContainer

                                        property bool hasImage: avatarImageSource.status === Image.Ready

                                        width: 54
                                        height: 54

                                        // This rectangle provides the themed ring via its border.
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: width / 2
                                            color: "transparent"
                                            border.color: Theme.primary
                                            border.width: 1 // The ring is 1px thick.
                                            visible: parent.hasImage
                                        }

                                        // Hidden Image loader. Its only purpose is to load the texture.
                                        Image {
                                            id: avatarImageSource

                                            source: {
                                                if (profileImageInput.text === "")
                                                    return "";

                                                if (profileImageInput.text.startsWith("/"))
                                                    return "file://" + profileImageInput.text;

                                                return profileImageInput.text;
                                            }
                                            smooth: true
                                            asynchronous: true
                                            mipmap: true
                                            cache: true
                                            visible: false // This item is never shown directly.
                                        }

                                        MultiEffect {
                                            anchors.fill: parent
                                            anchors.margins: 5
                                            source: avatarImageSource
                                            maskEnabled: true
                                            maskSource: settingsCircularMask
                                            visible: avatarContainer.hasImage
                                            maskThresholdMin: 0.5
                                            maskSpreadAtMin: 1
                                        }

                                        Item {
                                            id: settingsCircularMask

                                            width: 54 - 10
                                            height: 54 - 10
                                            layer.enabled: true
                                            layer.smooth: true
                                            visible: false

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: width / 2
                                                color: "black"
                                                antialiasing: true
                                            }

                                        }

                                        // Fallback for when there is no image.
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: width / 2
                                            color: Theme.primary
                                            visible: !parent.hasImage

                                            DankIcon {
                                                anchors.centerIn: parent
                                                name: "person"
                                                size: Theme.iconSize + 8
                                                color: Theme.primaryText
                                            }

                                        }

                                        // Error icon for when the image fails to load.
                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: "warning"
                                            size: Theme.iconSize + 8
                                            color: Theme.primaryText
                                            visible: profileImageInput.text !== "" && avatarImageSource.status === Image.Error
                                        }

                                    }

                                    // Input field
                                    Column {
                                        width: parent.width - 80 - Theme.spacingM
                                        spacing: Theme.spacingS

                                        Rectangle {
                                            width: parent.width
                                            height: 48
                                            radius: Theme.cornerRadius
                                            color: Theme.surfaceVariant
                                            border.color: profileImageInput.activeFocus ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)
                                            border.width: profileImageInput.activeFocus ? 2 : 1

                                            DankTextField {
                                                id: profileImageInput

                                                anchors.fill: parent
                                                textColor: Theme.surfaceText
                                                font.pixelSize: Theme.fontSizeMedium
                                                text: Prefs.profileImage
                                                placeholderText: "Enter image path or URL..."
                                                backgroundColor: "transparent"
                                                normalBorderColor: "transparent"
                                                focusedBorderColor: "transparent"
                                                onEditingFinished: {
                                                    Prefs.setProfileImage(text);
                                                }

                                            }

                                        }

                                        Text {
                                            text: "Local filesystem path or URL to an image file."
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.surfaceVariantText
                                            wrapMode: Text.WordWrap
                                            width: parent.width
                                        }

                                    }

                                }

                            }

                        }

                    }

                    // Clock Settings
                    SettingsSection {
                        title: "Clock & Time"
                        iconName: "schedule"

                        content: Column {
                            width: parent.width
                            spacing: Theme.spacingM

                            DankToggle {
                                text: "24-Hour Format"
                                description: "Use 24-hour time format instead of 12-hour AM/PM"
                                checked: Prefs.use24HourClock
                                onToggled: (checked) => {
                                    return Prefs.setClockFormat(checked);
                                }
                            }

                        }

                    }


                    // Weather Settings
                    SettingsSection {
                        title: "Weather"
                        iconName: "wb_sunny"

                        content: Column {
                            width: parent.width
                            spacing: Theme.spacingM

                            DankToggle {
                                text: "Fahrenheit"
                                description: "Use Fahrenheit instead of Celsius for temperature"
                                checked: Prefs.useFahrenheit
                                onToggled: (checked) => {
                                    return Prefs.setTemperatureUnit(checked);
                                }
                            }

                            // Weather Location Setting
                            Column {
                                width: parent.width
                                spacing: Theme.spacingS

                                Text {
                                    text: "Location"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    font.weight: Font.Medium
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 48
                                    radius: Theme.cornerRadius
                                    color: Theme.surfaceVariant
                                    border.color: weatherLocationInput.activeFocus ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)
                                    border.width: weatherLocationInput.activeFocus ? 2 : 1

                                    DankTextField {
                                        id: weatherLocationInput

                                        anchors.fill: parent
                                        textColor: Theme.surfaceText
                                        font.pixelSize: Theme.fontSizeMedium
                                        text: Prefs.weatherLocationOverride
                                        placeholderText: "Enter location..."
                                        backgroundColor: "transparent"
                                        normalBorderColor: "transparent"
                                        focusedBorderColor: "transparent"
                                        onEditingFinished: {
                                            Prefs.setWeatherLocationOverride(text);
                                        }

                                    }

                                }

                                Text {
                                    text: "Examples: \"New York, NY\", \"London\", \"Tokyo\""
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                }

                            }

                        }

                    }

                    // Widget Visibility Settings
                    SettingsSection {
                        title: "Top Bar Widgets"
                        iconName: "widgets"

                        content: Column {
                            width: parent.width
                            spacing: Theme.spacingM

                            DankToggle {
                                text: "Focused Window"
                                description: "Show the currently focused application in the top bar"
                                checked: Prefs.showFocusedWindow
                                onToggled: (checked) => {
                                    return Prefs.setShowFocusedWindow(checked);
                                }
                            }

                            DankToggle {
                                text: "Weather Widget"
                                description: "Display weather information in the top bar"
                                checked: Prefs.showWeather
                                onToggled: (checked) => {
                                    return Prefs.setShowWeather(checked);
                                }
                            }

                            DankToggle {
                                text: "Media Controls"
                                description: "Show currently playing media in the top bar"
                                checked: Prefs.showMusic
                                onToggled: (checked) => {
                                    return Prefs.setShowMusic(checked);
                                }
                            }

                            DankToggle {
                                text: "Clipboard Button"
                                description: "Show clipboard access button in the top bar"
                                checked: Prefs.showClipboard
                                onToggled: (checked) => {
                                    return Prefs.setShowClipboard(checked);
                                }
                            }

                            DankToggle {
                                text: "System Resources"
                                description: "Display CPU and RAM usage indicators"
                                checked: Prefs.showSystemResources
                                onToggled: (checked) => {
                                    return Prefs.setShowSystemResources(checked);
                                }
                            }

                            DankToggle {
                                text: "System Tray"
                                description: "Show system tray icons in the top bar"
                                checked: Prefs.showSystemTray
                                onToggled: (checked) => {
                                    return Prefs.setShowSystemTray(checked);
                                }
                            }


                        }

                    }

                    // Workspace Settings
                    SettingsSection {
                        title: "Workspaces"
                        iconName: "tab"

                        content: Column {
                            width: parent.width
                            spacing: Theme.spacingM

                            DankToggle {
                                text: "Workspace Index Numbers"
                                description: "Show workspace index numbers in the top bar workspace switcher"
                                checked: Prefs.showWorkspaceIndex
                                onToggled: (checked) => {
                                    return Prefs.setShowWorkspaceIndex(checked);
                                }
                            }

                            DankToggle {
                                text: "Workspace Padding"
                                description: "Always show a minimum of 3 workspaces, even if fewer are available"
                                checked: Prefs.showWorkspacePadding
                                onToggled: (checked) => {
                                    return Prefs.setShowWorkspacePadding(checked);
                                }
                            }

                        }

                    }

                    // Display Settings
                    SettingsSection {
                        title: "Display & Appearance"
                        iconName: "palette"

                        content: Column {
                            width: parent.width
                            spacing: Theme.spacingL

                            DankToggle {
                                text: "Night Mode"
                                description: "Apply warm color temperature to reduce eye strain"
                                checked: Prefs.nightModeEnabled
                                onToggled: (checked) => {
                                    Prefs.setNightModeEnabled(checked);
                                    if (checked)
                                        nightModeEnableProcess.running = true;
                                    else
                                        nightModeDisableProcess.running = true;
                                }
                            }

                            DankToggle {
                                text: "Light Mode"
                                description: "Use light theme instead of dark theme"
                                checked: Prefs.isLightMode
                                onToggled: (checked) => {
                                    Prefs.setLightMode(checked);
                                    Theme.isLightMode = checked;
                                }
                            }

                            Loader {
                                width: parent.width
                                sourceComponent: settingsDropdownComponent
                                onLoaded: {
                                    item.text = "Icon Theme"
                                    item.description = "Select icon theme (requires restart)"
                                    item.currentValue = Prefs.iconTheme
                                    // Set initial options, will be updated when detection completes
                                    item.options = Qt.binding(function() { return Prefs.availableIconThemes; })
                                    item.valueChanged.connect(function(value) {
                                        Prefs.setIconTheme(value);
                                    })
                                }
                                
                                // Update options when available themes change
                                Connections {
                                    target: Prefs
                                    function onAvailableIconThemesChanged() {
                                        if (parent.item && parent.item.hasOwnProperty('options')) {
                                            parent.item.options = Prefs.availableIconThemes;
                                        }
                                    }
                                }
                            }

                            // Top Bar Transparency
                            Column {
                                width: parent.width
                                spacing: Theme.spacingS

                                Text {
                                    text: "Top Bar Transparency"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    font.weight: Font.Medium
                                }

                                DankSlider {
                                    width: parent.width
                                    value: Math.round(Prefs.topBarTransparency * 100)
                                    minimum: 0
                                    maximum: 100
                                    leftIcon: "opacity"
                                    rightIcon: "circle"
                                    unit: "%"
                                    showValue: true
                                    onSliderDragFinished: (finalValue) => {
                                        let transparencyValue = finalValue / 100;
                                        Prefs.setTopBarTransparency(transparencyValue);
                                    }
                                }

                                Text {
                                    text: "Adjust the transparency of the top bar background"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                }

                            }

                            // Popup Transparency
                            Column {
                                width: parent.width
                                spacing: Theme.spacingS

                                Text {
                                    text: "Popup Transparency"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    font.weight: Font.Medium
                                }

                                DankSlider {
                                    width: parent.width
                                    value: Math.round(Prefs.popupTransparency * 100)
                                    minimum: 0
                                    maximum: 100
                                    leftIcon: "blur_on"
                                    rightIcon: "circle"
                                    unit: "%"
                                    showValue: true
                                    onSliderDragFinished: (finalValue) => {
                                        let transparencyValue = finalValue / 100;
                                        Prefs.setPopupTransparency(transparencyValue);
                                    }
                                }

                                Text {
                                    text: "Adjust transparency for dialogs, menus, and popups"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                }

                            }

                            // Theme Picker
                            Column {
                                width: parent.width
                                spacing: Theme.spacingS

                                Text {
                                    text: "Theme Color"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    font.weight: Font.Medium
                                }

                                ThemePicker {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                            }

                        }

                    }

                }

            }

        }

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

        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 8
            shadowBlur: 1
            shadowColor: Qt.rgba(0, 0, 0, 0.3)
            shadowOpacity: 0.3
        }

    }

    // Night mode processes
    Process {
        id: nightModeEnableProcess

        command: ["bash", "-c", "if command -v wlsunset > /dev/null; then pkill wlsunset; wlsunset -t 3000 & elif command -v redshift > /dev/null; then pkill redshift; redshift -P -O 3000 & else echo 'No night mode tool available'; fi"]
        running: false
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                console.warn("Failed to enable night mode");
                Prefs.setNightModeEnabled(false);
            }
        }
    }

    Process {
        id: nightModeDisableProcess

        command: ["bash", "-c", "pkill wlsunset; pkill redshift; if command -v wlsunset > /dev/null; then wlsunset -t 6500 -T 6500 & sleep 1; pkill wlsunset; elif command -v redshift > /dev/null; then redshift -P -O 6500; redshift -x; fi"]
        running: false
        onExited: (exitCode) => {
            if (exitCode !== 0)
                console.warn("Failed to disable night mode");

        }
    }

    // Keyboard focus and shortcuts
    FocusScope {
        anchors.fill: parent
        focus: settingsPopup.settingsVisible
        Keys.onEscapePressed: settingsPopup.settingsVisible = false
    }

}
