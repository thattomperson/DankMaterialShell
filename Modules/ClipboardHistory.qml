import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Widgets

PanelWindow {
    id: clipboardHistory

    property bool isVisible: false
    property int totalCount: 0
    // Use the global Theme singleton
    property var activeTheme: Theme
    // Confirmation dialog state
    property bool showClearConfirmation: false
    // Clipboard entries model
    property var clipboardEntries: []

    function updateFilteredModel() {
        filteredClipboardModel.clear();
        for (let i = 0; i < clipboardModel.count; i++) {
            const entry = clipboardModel.get(i).entry;
            if (searchField.text.trim().length === 0) {
                filteredClipboardModel.append({
                    "entry": entry
                });
            } else {
                const content = getEntryPreview(entry).toLowerCase();
                if (content.includes(searchField.text.toLowerCase()))
                    filteredClipboardModel.append({
                    "entry": entry
                });

            }
        }
        // Update total count
        clipboardHistory.totalCount = filteredClipboardModel.count;
    }

    function toggle() {
        if (isVisible)
            hide();
        else
            show();
    }

    function show() {
        clipboardHistory.isVisible = true;
        searchField.focus = true;
        refreshClipboard();
        console.log("ClipboardHistory: Opening and refreshing");
    }

    function hide() {
        clipboardHistory.isVisible = false;
        searchField.focus = false;
        searchField.text = "";
        // Clean up temporary image files
        cleanupTempFiles();
    }

    function cleanupTempFiles() {
        cleanupProcess.command = ["sh", "-c", "rm -f /tmp/clipboard_preview_*.png"];
        cleanupProcess.running = true;
    }

    function refreshClipboard() {
        clipboardProcess.running = true;
    }

    function copyEntry(entry) {
        const entryId = entry.split('\t')[0];
        copyProcess.command = ["sh", "-c", `cliphist decode ${entryId} | wl-copy`];
        copyProcess.running = true;
        // Simply hide the clipboard interface
        console.log("ClipboardHistory: Entry copied, hiding interface");
        hide();
    }

    function deleteEntry(entry) {
        // Use the full entry line for deletion
        console.log("Deleting entry:", entry);
        deleteProcess.command = ["sh", "-c", `echo '${entry.replace(/'/g, "'\\''")}' | cliphist delete`];
        deleteProcess.running = true;
    }

    function clearAll() {
        clearProcess.running = true;
    }

    function getEntryPreview(entry) {
        // Remove cliphist ID prefix and clean up content
        let content = entry.replace(/^\s*\d+\s+/, "");
        // Handle different content types
        if (content.includes("image/") || content.includes("binary data") || /\.(png|jpg|jpeg|gif|bmp|webp)/i.test(content)) {
            // Extract dimensions if available
            const dimensionMatch = content.match(/(\d+)x(\d+)/);
            if (dimensionMatch)
                return `Image ${dimensionMatch[1]}×${dimensionMatch[2]}`;

            // Extract file type if available
            const typeMatch = content.match(/\b(png|jpg|jpeg|gif|bmp|webp)\b/i);
            if (typeMatch)
                return `Image (${typeMatch[1].toUpperCase()})`;

            return "Image";
        }
        // Truncate long text
        if (content.length > 100)
            return content.substring(0, 100) + "...";

        return content;
    }

    function getEntryType(entry) {
        // Improved image detection
        if (entry.includes("image/") || entry.includes("binary data") || /\.(png|jpg|jpeg|gif|bmp|webp)/i.test(entry) || /\b(png|jpg|jpeg|gif|bmp|webp)\b/i.test(entry))
            return "image";

        if (entry.length > 200)
            return "long_text";

        return "text";
    }

    // Window properties
    color: "transparent"
    visible: isVisible
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    ListModel {
        id: clipboardModel
    }

    ListModel {
        id: filteredClipboardModel
    }

    // Background overlay
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        opacity: clipboardHistory.isVisible ? 1 : 0
        visible: clipboardHistory.isVisible

        MouseArea {
            anchors.fill: parent
            enabled: clipboardHistory.isVisible
            onClicked: clipboardHistory.hide()
        }

        Behavior on opacity {
            NumberAnimation {
                duration: activeTheme.mediumDuration
                easing.type: activeTheme.emphasizedEasing
            }

        }

    }

    // Main clipboard container
    Rectangle {
        id: clipboardContainer

        width: Math.min(500, parent.width - 200)
        height: Math.min(500, parent.height - 100)
        anchors.centerIn: parent
        color: activeTheme.popupBackground()
        radius: activeTheme.cornerRadiusXLarge
        border.color: Qt.rgba(activeTheme.outline.r, activeTheme.outline.g, activeTheme.outline.b, 0.08)
        border.width: 1
        opacity: clipboardHistory.isVisible ? 1 : 0
        scale: clipboardHistory.isVisible ? 1 : 0.9

        // Header section
        Column {
            id: headerSection

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: activeTheme.spacingXL
            spacing: activeTheme.spacingL

            // Title and actions
            Item {
                width: parent.width
                height: 40

                Text {
                    id: titleText

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Clipboard History" + (clipboardHistory.totalCount > 0 ? ` (${clipboardHistory.totalCount})` : "")
                    font.pixelSize: activeTheme.fontSizeLarge + 4
                    font.weight: Font.Bold
                    color: activeTheme.surfaceText
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: activeTheme.spacingS

                    // Clear all button
                    DankActionButton {
                        buttonSize: 40
                        circular: false
                        iconName: "delete_sweep"
                        iconSize: activeTheme.iconSize
                        iconColor: activeTheme.surfaceText
                        hoverColor: Qt.rgba(activeTheme.primary.r, activeTheme.primary.g, activeTheme.primary.b, 0.12)
                        visible: clipboardHistory.totalCount > 0
                        onClicked: showClearConfirmation = true
                    }

                    // Close button
                    DankActionButton {
                        buttonSize: 40
                        circular: false
                        iconName: "close"
                        iconSize: activeTheme.iconSize
                        iconColor: activeTheme.surfaceText
                        hoverColor: Qt.rgba(activeTheme.primary.r, activeTheme.primary.g, activeTheme.primary.b, 0.12)
                        onClicked: clipboardHistory.hide()
                    }

                }

            }

            // Search field
            Rectangle {
                width: parent.width
                height: 48
                radius: activeTheme.cornerRadiusLarge
                color: Qt.rgba(activeTheme.surfaceVariant.r, activeTheme.surfaceVariant.g, activeTheme.surfaceVariant.b, activeTheme.getContentBackgroundAlpha() * 0.4)
                border.color: searchField.focus ? activeTheme.primary : Qt.rgba(activeTheme.outline.r, activeTheme.outline.g, activeTheme.outline.b, 0.08)
                border.width: searchField.focus ? 2 : 1

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: activeTheme.spacingL
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: activeTheme.spacingM

                    DankIcon {
                        name: "search"
                        size: activeTheme.iconSize
                        color: searchField.focus ? activeTheme.primary : Qt.rgba(activeTheme.surfaceText.r, activeTheme.surfaceText.g, activeTheme.surfaceText.b, 0.6)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextInput {
                        id: searchField

                        width: parent.parent.width - 80
                        height: parent.parent.height
                        font.pixelSize: activeTheme.fontSizeLarge
                        color: activeTheme.surfaceText
                        verticalAlignment: TextInput.AlignVCenter
                        selectByMouse: true
                        enabled: clipboardHistory.isVisible
                        onTextChanged: updateFilteredModel()
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape)
                                clipboardHistory.hide();

                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.IBeamCursor
                            acceptedButtons: Qt.NoButton
                        }

                        // Placeholder text
                        Text {
                            text: "Search clipboard entries..."
                            font: searchField.font
                            color: Qt.rgba(activeTheme.surfaceText.r, activeTheme.surfaceText.g, activeTheme.surfaceText.b, 0.6)
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchField.text.length === 0 && !searchField.focus
                        }

                    }

                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: activeTheme.shortDuration
                    }

                }

            }

        }

        // Clipboard entries
        Rectangle {
            anchors.top: headerSection.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: activeTheme.spacingXL
            anchors.topMargin: activeTheme.spacingL
            color: "transparent"

            ScrollView {
                anchors.fill: parent
                clip: true
                // Improve scrolling responsiveness
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.vertical.width: 12
                ScrollBar.vertical.minimumSize: 0.1 // Minimum scrollbar handle size
                // Enable faster scrolling
                wheelEnabled: true

                ListView {
                    id: clipboardList

                    // Make mouse wheel scrolling more responsive
                    property real wheelStepSize: 60

                    model: filteredClipboardModel
                    spacing: activeTheme.spacingS
                    // Improve scrolling performance
                    cacheBuffer: 100
                    boundsBehavior: Flickable.StopAtBounds

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        propagateComposedEvents: true
                        z: -1
                        onWheel: (wheel) => {
                            var delta = wheel.angleDelta.y;
                            var steps = delta / 120; // Standard wheel step
                            clipboardList.contentY -= steps * clipboardList.wheelStepSize;
                            // Ensure we stay within bounds
                            if (clipboardList.contentY < 0)
                                clipboardList.contentY = 0;
                            else if (clipboardList.contentY > clipboardList.contentHeight - clipboardList.height)
                                clipboardList.contentY = Math.max(0, clipboardList.contentHeight - clipboardList.height);
                        }
                    }

                    delegate: Rectangle {
                        property string entryType: getEntryType(model.entry)
                        property string entryPreview: getEntryPreview(model.entry)
                        property int entryIndex: index + 1

                        width: clipboardList.width - 16 // Account for scrollbar space
                        height: Math.max(60, contentColumn.implicitHeight + activeTheme.spacingM * 2)
                        radius: activeTheme.cornerRadius
                        color: entryArea.containsMouse ? Qt.rgba(activeTheme.primary.r, activeTheme.primary.g, activeTheme.primary.b, 0.08) : Qt.rgba(activeTheme.surfaceVariant.r, activeTheme.surfaceVariant.g, activeTheme.surfaceVariant.b, 0.05)
                        border.color: Qt.rgba(activeTheme.outline.r, activeTheme.outline.g, activeTheme.outline.b, 0.1)
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: activeTheme.spacingM
                            spacing: activeTheme.spacingL

                            // Index number
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: Qt.rgba(activeTheme.primary.r, activeTheme.primary.g, activeTheme.primary.b, 0.2)
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: entryIndex.toString()
                                    font.pixelSize: activeTheme.fontSizeSmall
                                    font.weight: Font.Bold
                                    color: activeTheme.primary
                                }

                            }

                            // Entry content
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 80 // Adjusted for index number and delete button
                                spacing: activeTheme.spacingM

                                // Image preview - actual image display for images
                                Rectangle {
                                    property string entryId: model.entry ? model.entry.split('\t')[0] : ""
                                    property string tempImagePath: "/tmp/clipboard_preview_" + entryId + ".png"

                                    width: entryType === "image" ? 48 : 0
                                    height: entryType === "image" ? 36 : 0
                                    radius: activeTheme.cornerRadiusSmall
                                    color: Qt.rgba(activeTheme.surfaceVariant.r, activeTheme.surfaceVariant.g, activeTheme.surfaceVariant.b, 0.1)
                                    border.color: Qt.rgba(activeTheme.outline.r, activeTheme.outline.g, activeTheme.outline.b, 0.2)
                                    border.width: 1
                                    visible: entryType === "image"
                                    clip: true

                                    // Actual image preview using cliphist decode
                                    Image {
                                        id: imagePreview

                                        anchors.fill: parent
                                        anchors.margins: 1
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: false
                                        source: parent.entryType === "image" && parent.entryId ? "file://" + parent.tempImagePath : ""
                                        Component.onCompleted: {
                                            if (parent.entryType === "image" && parent.entryId) {
                                                // Simple approach: use shell redirection to write to file
                                                imageDecodeProcess.entryId = parent.entryId;
                                                imageDecodeProcess.tempPath = parent.tempImagePath;
                                                imageDecodeProcess.imagePreview = imagePreview;
                                                imageDecodeProcess.command = ["sh", "-c", `cliphist decode ${parent.entryId} > "${parent.tempImagePath}" 2>/dev/null`];
                                                imageDecodeProcess.running = true;
                                            }
                                        }
                                        onStatusChanged: {
                                            if (status === Image.Error)
                                                console.warn("Failed to load clipboard image from:", source);

                                        }

                                        // Fallback icon when image fails to load or is loading
                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: imagePreview.status === Image.Loading ? "hourglass_empty" : imagePreview.status === Image.Error ? "broken_image" : "photo"
                                            size: imagePreview.status === Image.Loading ? 14 : 18
                                            color: imagePreview.status === Image.Error ? activeTheme.error : activeTheme.primary
                                            visible: imagePreview.status !== Image.Ready

                                            SequentialAnimation on opacity {
                                                running: imagePreview.status === Image.Loading
                                                loops: Animation.Infinite

                                                NumberAnimation {
                                                    to: 0.3
                                                    duration: 500
                                                }

                                                NumberAnimation {
                                                    to: 1
                                                    duration: 500
                                                }

                                            }

                                        }

                                    }

                                }

                                Column {
                                    id: contentColumn

                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - (entryType === "image" ? 60 : 0)
                                    spacing: activeTheme.spacingXS

                                    Text {
                                        text: {
                                            switch (entryType) {
                                            case "image":
                                                return "Image • " + entryPreview;
                                            case "long_text":
                                                return "Long Text";
                                            default:
                                                return "Text";
                                            }
                                        }
                                        font.pixelSize: activeTheme.fontSizeSmall
                                        color: activeTheme.primary
                                        font.weight: Font.Medium
                                        width: parent.width
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: entryPreview
                                        font.pixelSize: activeTheme.fontSizeMedium
                                        color: activeTheme.surfaceText
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: entryType === "long_text" ? 3 : 1
                                        elide: Text.ElideRight
                                        visible: true // Show preview for all entry types including images
                                    }

                                }

                            }

                            // Actions - Single centered delete button
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 32
                                height: 32
                                radius: activeTheme.cornerRadius
                                color: deleteArea.containsMouse ? Qt.rgba(activeTheme.primary.r, activeTheme.primary.g, activeTheme.primary.b, 0.12) : "transparent"
                                z: 100 // Ensure it's above other elements

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: "delete"
                                    size: activeTheme.iconSize - 4
                                    color: deleteArea.containsMouse ? activeTheme.primary : activeTheme.surfaceText
                                }

                                MouseArea {
                                    id: deleteArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    z: 101 // Ensure click area is above everything
                                    onClicked: (mouse) => {
                                        console.log("Delete clicked for entry:", model.entry);
                                        deleteEntry(model.entry);
                                        // Prevent the click from propagating to the entry area
                                        mouse.accepted = true;
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: activeTheme.shortDuration
                                    }

                                }

                            }

                        }

                        MouseArea {
                            id: entryArea

                            anchors.fill: parent
                            anchors.rightMargin: 40 // Leave space for delete button
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: copyEntry(model.entry)
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: activeTheme.shortDuration
                            }

                        }

                    }

                }

                // Empty state
                Column {
                    anchors.centerIn: parent
                    spacing: activeTheme.spacingL
                    visible: clipboardHistory.totalCount === 0

                    DankIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: "content_paste_off"
                        size: activeTheme.iconSizeLarge + 16
                        color: Qt.rgba(activeTheme.surfaceText.r, activeTheme.surfaceText.g, activeTheme.surfaceText.b, 0.3)
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No clipboard history"
                        font.pixelSize: activeTheme.fontSizeLarge
                        color: Qt.rgba(activeTheme.surfaceText.r, activeTheme.surfaceText.g, activeTheme.surfaceText.b, 0.6)
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Copy something to see it here"
                        font.pixelSize: activeTheme.fontSizeMedium
                        color: Qt.rgba(activeTheme.surfaceText.r, activeTheme.surfaceText.g, activeTheme.surfaceText.b, 0.4)
                    }

                }

            }

        }

        // Clear All Confirmation Dialog
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.4)
            visible: showClearConfirmation
            z: 999

            MouseArea {
                anchors.fill: parent
                onClicked: clipboardHistory.showClearConfirmation = false
            }

        }

        Rectangle {
            anchors.centerIn: parent
            width: 350
            height: 200 // Increased height for better spacing
            radius: activeTheme.cornerRadiusLarge
            color: activeTheme.popupBackground()
            border.color: Qt.rgba(activeTheme.outline.r, activeTheme.outline.g, activeTheme.outline.b, 0.08)
            border.width: 1
            visible: showClearConfirmation
            z: 1000

            Column {
                anchors.centerIn: parent
                spacing: activeTheme.spacingL
                width: parent.width - 40

                // Add top padding
                Item {
                    width: 1
                    height: activeTheme.spacingM
                }

                DankIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "warning"
                    size: activeTheme.iconSizeLarge
                    color: activeTheme.error
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Clear All Clipboard History?"
                    font.pixelSize: activeTheme.fontSizeLarge
                    font.weight: Font.Bold
                    color: activeTheme.surfaceText
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "This action cannot be undone. All clipboard entries will be permanently deleted."
                    font.pixelSize: activeTheme.fontSizeMedium
                    color: Qt.rgba(activeTheme.surfaceText.r, activeTheme.surfaceText.g, activeTheme.surfaceText.b, 0.7)
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: activeTheme.spacingM

                    // Cancel button
                    Rectangle {
                        width: 100
                        height: 40
                        radius: activeTheme.cornerRadius
                        color: cancelArea.containsMouse ? Qt.rgba(activeTheme.primary.r, activeTheme.primary.g, activeTheme.primary.b, 0.08) : "transparent"
                        border.color: activeTheme.primary
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.pixelSize: activeTheme.fontSizeMedium
                            font.weight: Font.Medium
                            color: activeTheme.primary
                        }

                        MouseArea {
                            id: cancelArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: clipboardHistory.showClearConfirmation = false
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: activeTheme.shortDuration
                            }

                        }

                    }

                    // Clear button
                    Rectangle {
                        width: 100
                        height: 40
                        radius: activeTheme.cornerRadius
                        color: confirmArea.containsMouse ? Qt.rgba(activeTheme.primary.r, activeTheme.primary.g, activeTheme.primary.b, 0.8) : activeTheme.primary

                        Text {
                            anchors.centerIn: parent
                            text: "Clear All"
                            font.pixelSize: activeTheme.fontSizeMedium
                            font.weight: Font.Medium
                            color: activeTheme.surface
                        }

                        MouseArea {
                            id: confirmArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                clipboardHistory.showClearConfirmation = false;
                                clearAll();
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: activeTheme.shortDuration
                            }

                        }

                    }

                }

                // Add some bottom padding
                Item {
                    width: 1
                    height: activeTheme.spacingM
                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: activeTheme.mediumDuration
                easing.type: activeTheme.emphasizedEasing
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: activeTheme.mediumDuration
                easing.type: activeTheme.emphasizedEasing
            }

        }

    }

    // Clipboard processes
    Process {
        id: cleanupProcess

        running: false
        onExited: (exitCode) => {
            if (exitCode === 0)
                console.log("Temporary image files cleaned up");

        }
    }

    Process {
        // Force the Image component to reload

        id: imageDecodeProcess

        property string entryId: ""
        property string tempPath: ""
        property var imagePreview: null

        running: false
        onExited: (exitCode) => {
            if (exitCode === 0 && imagePreview && tempPath)
                Qt.callLater(function() {
                imagePreview.source = "";
                imagePreview.source = "file://" + tempPath;
            });

        }
        onStarted: {
            console.log("Starting image decode for entry:", entryId, "to path:", tempPath);
        }
    }

    Process {
        id: clipboardProcess

        command: ["cliphist", "list"]
        running: false
        onStarted: {
            clipboardHistory.clipboardEntries = [];
            clipboardModel.clear();
            console.log("ClipboardHistory: Starting cliphist process...");
        }
        onExited: (exitCode) => {
            if (exitCode === 0)
                updateFilteredModel();
            else
                console.warn("ClipboardHistory: Failed to load clipboard history");
        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                if (line.trim()) {
                    clipboardHistory.clipboardEntries.push(line);
                    clipboardModel.append({
                        "entry": line
                    });
                }
            }
        }

    }

    Process {
        id: copyProcess

        running: false
        onExited: (exitCode) => {
            if (exitCode !== 0)
                console.warn("ClipboardHistory: Failed to copy entry");

        }
    }

    Process {
        id: deleteProcess

        running: false
        onExited: (exitCode) => {
            if (exitCode === 0)
                refreshClipboard();

        }
    }

    Process {
        id: clearProcess

        command: ["cliphist", "wipe"]
        running: false
        onExited: (exitCode) => {
            if (exitCode === 0) {
                clipboardHistory.clipboardEntries = [];
                clipboardModel.clear();
                updateFilteredModel();
            }
        }
    }

    IpcHandler {
        function open() {
            console.log("ClipboardHistory: IPC open() called");
            clipboardHistory.show();
            return "CLIPBOARD_OPEN_SUCCESS";
        }

        function close() {
            console.log("ClipboardHistory: IPC close() called");
            clipboardHistory.hide();
            return "CLIPBOARD_CLOSE_SUCCESS";
        }

        function toggle() {
            console.log("ClipboardHistory: IPC toggle() called");
            clipboardHistory.toggle();
            return "CLIPBOARD_TOGGLE_SUCCESS";
        }

        target: "clipboard"
    }

}
