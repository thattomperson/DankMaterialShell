import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets

DankModal {
    // Don't hide the interface, just show toast

    id: clipboardHistoryModal

    property bool isVisible: false
    property int totalCount: 0
    property var activeTheme: Theme
    property bool showClearConfirmation: false
    property var clipboardEntries: []
    property string searchText: ""
    property bool imagemagickAvailable: false
    property string thumbnailCacheDir: ""

    function updateFilteredModel() {
        filteredClipboardModel.clear();
        for (let i = 0; i < clipboardModel.count; i++) {
            const entry = clipboardModel.get(i).entry;
            if (searchText.trim().length === 0) {
                filteredClipboardModel.append({
                    "entry": entry
                });
            } else {
                const content = getEntryPreview(entry).toLowerCase();
                if (content.includes(searchText.toLowerCase()))
                    filteredClipboardModel.append({
                    "entry": entry
                });

            }
        }
        clipboardHistoryModal.totalCount = filteredClipboardModel.count;
    }

    function toggle() {
        if (isVisible)
            hide();
        else
            show();
    }

    function show() {
        clipboardHistoryModal.isVisible = true;
        initializeThumbnailSystem();
        refreshClipboard();
        console.log("ClipboardHistoryModal: Opening and refreshing");
    }

    function hide() {
        clipboardHistoryModal.isVisible = false;
        clipboardHistoryModal.searchText = "";
        cleanupTempFiles();
    }

    function initializeThumbnailSystem() {
        getCacheDirProcess.running = true;
    }

    function cleanupTempFiles() {
        cleanupProcess.command = ["sh", "-c", "rm -f /tmp/clipboard_preview_*.png"];
        cleanupProcess.running = true;
    }

    function generateThumbnails() {
        if (!imagemagickAvailable) return;
        
        for (let i = 0; i < clipboardModel.count; i++) {
            const entry = clipboardModel.get(i).entry;
            const entryType = getEntryType(entry);
            
            if (entryType === "image") {
                const entryId = entry.split('\t')[0];
                const thumbnailPath = `${thumbnailCacheDir}/${entryId}.png`;
                
                thumbnailGenProcess.command = [
                    "sh", "-c", 
                    `mkdir -p "${thumbnailCacheDir}" && cliphist decode ${entryId} | magick - -resize '128x128>' "${thumbnailPath}"`
                ];
                thumbnailGenProcess.running = true;
            }
        }
    }

    function getThumbnailPath(entry) {
        const entryId = entry.split('\t')[0];
        return `${thumbnailCacheDir}/${entryId}.png`;
    }


    function refreshClipboard() {
        clipboardProcess.running = true;
    }

    function copyEntry(entry) {
        const entryId = entry.split('\t')[0];
        copyProcess.command = ["sh", "-c", `cliphist decode ${entryId} | wl-copy`];
        copyProcess.running = true;
        console.log("ClipboardHistoryModal: Entry copied, showing toast");
        ToastService.showInfo("Copied to clipboard");
        clipboardHistoryModal.hide();
    }

    function deleteEntry(entry) {
        console.log("Deleting entry:", entry);
        deleteProcess.command = ["sh", "-c", `echo '${entry.replace(/'/g, "'\\''")}' | cliphist delete`];
        deleteProcess.running = true;
    }

    function clearAll() {
        clearProcess.running = true;
    }

    function getEntryPreview(entry) {
        let content = entry.replace(/^\s*\d+\s+/, "");
        if (content.includes("image/") || content.includes("binary data") || /\.(png|jpg|jpeg|gif|bmp|webp)/i.test(content)) {
            const dimensionMatch = content.match(/(\d+)x(\d+)/);
            if (dimensionMatch)
                return `Image ${dimensionMatch[1]}×${dimensionMatch[2]}`;

            const typeMatch = content.match(/\b(png|jpg|jpeg|gif|bmp|webp)\b/i);
            if (typeMatch)
                return `Image (${typeMatch[1].toUpperCase()})`;

            return "Image";
        }
        if (content.length > 100)
            return content.substring(0, 100) + "...";

        return content;
    }

    function getEntryType(entry) {
        if (entry.includes("image/") || entry.includes("binary data") || /\.(png|jpg|jpeg|gif|bmp|webp)/i.test(entry) || /\b(png|jpg|jpeg|gif|bmp|webp)\b/i.test(entry))
            return "image";

        if (entry.length > 200)
            return "long_text";

        return "text";
    }

    // DankModal configuration
    visible: isVisible
    width: 650
    height: 550
    keyboardFocus: "ondemand"
    backgroundColor: Theme.popupBackground()
    cornerRadius: Theme.cornerRadiusLarge
    borderColor: Theme.outlineMedium
    borderWidth: 1
    enableShadow: true 
    onBackgroundClicked: {
        hide();
    }

    // Clear confirmation dialog
    DankModal {
        id: clearConfirmDialog

        visible: showClearConfirmation
        width: 350
        height: 150
        keyboardFocus: "ondemand"
        onBackgroundClicked: {
            showClearConfirmation = false;
        }

        content: Component {
            Item {
                anchors.fill: parent

                Column {
                    anchors.centerIn: parent
                    width: parent.width - Theme.spacingM * 2
                    spacing: Theme.spacingM

                    StyledText {
                        text: "Clear All History?"
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    StyledText {
                        text: "This will permanently delete all clipboard history."
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceVariantText
                        anchors.horizontalCenter: parent.horizontalCenter
                        wrapMode: Text.WordWrap
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.spacingM

                        Rectangle {
                            width: 100
                            height: 40
                            radius: Theme.cornerRadius
                            color: cancelClearButton.containsMouse ? Theme.surfaceTextPressed : Theme.surfaceVariantAlpha

                            StyledText {
                                text: "Cancel"
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: cancelClearButton

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: showClearConfirmation = false
                            }

                        }

                        Rectangle {
                            width: 100
                            height: 40
                            radius: Theme.cornerRadius
                            color: confirmClearButton.containsMouse ? Theme.errorPressed : Theme.error

                            StyledText {
                                text: "Clear All"
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.primaryText
                                font.weight: Font.Medium
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: confirmClearButton

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    clearAll();
                                    showClearConfirmation = false;
                                    hide();
                                }
                            }

                        }

                    }

                }

            }

        }

    }

    // Data models
    ListModel {
        id: clipboardModel
    }

    ListModel {
        id: filteredClipboardModel
    }

    // Processes
    Process {
        id: clipboardProcess

        command: ["cliphist", "list"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                clipboardModel.clear();
                const lines = text.trim().split('\n');
                for (const line of lines) {
                    if (line.trim().length > 0)
                        clipboardModel.append({
                            "entry": line
                        });

                }
                updateFilteredModel();
                generateThumbnails();
            }
        }

    }

    Process {
        id: copyProcess

        running: false
        onExited: (exitCode) => {
            if (exitCode !== 0)
                console.error("Copy failed with exit code:", exitCode);

        }
    }

    Process {
        id: deleteProcess

        running: false
        onExited: (exitCode) => {
            if (exitCode === 0)
                refreshClipboard();
            else
                console.error("Delete failed with exit code:", exitCode);
        }
    }

    Process {
        id: clearProcess

        command: ["cliphist", "wipe"]
        running: false
        onExited: (exitCode) => {
            if (exitCode === 0) {
                clipboardModel.clear();
                filteredClipboardModel.clear();
                totalCount = 0;
            } else {
                console.error("Clear failed with exit code:", exitCode);
            }
        }
    }

    Process {
        id: cleanupProcess

        running: false
    }

    Process {
        id: getCacheDirProcess

        command: ["sh", "-c", "echo ${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/thumbs"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                thumbnailCacheDir = text.trim();
                checkImageMagickProcess.running = true;
            }
        }
    }

    Process {
        id: checkImageMagickProcess

        command: ["which", "magick"]
        running: false

        onExited: (exitCode) => {
            imagemagickAvailable = (exitCode === 0);
            if (!imagemagickAvailable) {
                console.warn("ClipboardHistoryModal: ImageMagick not available, thumbnails disabled");
            }
        }
    }

    Process {
        id: thumbnailGenProcess

        running: false

        onExited: (exitCode) => {
            if (exitCode !== 0) {
                console.warn("ClipboardHistoryModal: Thumbnail generation failed with exit code:", exitCode);
            }
        }
    }


    IpcHandler {
        function open() {
            console.log("ClipboardHistoryModal: IPC open() called");
            clipboardHistoryModal.show();
            return "CLIPBOARD_OPEN_SUCCESS";
        }

        function close() {
            console.log("ClipboardHistoryModal: IPC close() called");
            clipboardHistoryModal.hide();
            return "CLIPBOARD_CLOSE_SUCCESS";
        }

        function toggle() {
            console.log("ClipboardHistoryModal: IPC toggle() called");
            clipboardHistoryModal.toggle();
            return "CLIPBOARD_TOGGLE_SUCCESS";
        }

        target: "clipboard"
    }

    content: Component {
        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingL

            Item {
                width: parent.width
                height: 40

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingM

                    DankIcon {
                        name: "content_paste"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: `Clipboard History (${totalCount})`
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingS

                    DankActionButton {
                        iconName: "delete_sweep"
                        iconSize: Theme.iconSize
                        iconColor: Theme.error
                        hoverColor: Theme.errorHover
                        onClicked: {
                            showClearConfirmation = true;
                        }
                    }

                    DankActionButton {
                        iconName: "close"
                        iconSize: Theme.iconSize - 4
                        iconColor: Theme.surfaceText
                        hoverColor: Theme.errorHover
                        onClicked: hide()
                    }
                }
            }

            DankTextField {
                id: searchField

                width: parent.width
                placeholderText: "Search clipboard history..."
                leftIconName: "search"
                showClearButton: true
                onTextChanged: {
                    clipboardHistoryModal.searchText = text;
                    updateFilteredModel();
                }

                Connections {
                    function onOpened() {
                        searchField.forceActiveFocus();
                    }

                    function onDialogClosed() {
                        searchField.clearFocus();
                    }

                    target: clipboardHistoryModal
                }
            }

            Rectangle {
                width: parent.width
                height: parent.height - 110
                radius: Theme.cornerRadiusLarge
                color: Theme.surfaceLight
                border.color: Theme.outlineLight
                border.width: 1
                clip: true

                ListView {
                    id: clipboardListView

                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    clip: true
                    model: filteredClipboardModel
                    spacing: Theme.spacingXS

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                    property real wheelMultiplier: 1.8
                    property int wheelBaseStep: 160

                    WheelHandler {
                        target: null
                        onWheel: (ev) => {
                            let dy = ev.pixelDelta.y !== 0
                                     ? ev.pixelDelta.y
                                     : (ev.angleDelta.y / 120) * clipboardListView.wheelBaseStep;
                            if (ev.inverted) dy = -dy;

                            const maxY = Math.max(0, clipboardListView.contentHeight - clipboardListView.height);
                            clipboardListView.contentY = Math.max(0, Math.min(maxY,
                                clipboardListView.contentY - dy * clipboardListView.wheelMultiplier));

                            ev.accepted = true;
                        }
                    }

                    StyledText {
                        text: "No clipboard entries found"
                        anchors.centerIn: parent
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceVariantText
                        visible: filteredClipboardModel.count === 0
                    }

                    delegate: Rectangle {
                            property string entryType: getEntryType(model.entry)
                            property string entryPreview: getEntryPreview(model.entry)
                            property int entryIndex: index + 1
                            property string entryData: model.entry
                            property alias thumbnailImageSource: thumbnailImageSource

                            width: clipboardListView.width
                            height: Math.max(entryType === "image" ? 72 : 60, contentText.contentHeight + Theme.spacingL)
                            radius: Theme.cornerRadius
                            color: mouseArea.containsMouse ? Theme.primaryHover : Theme.primaryBackground
                            border.color: Theme.outlineStrong
                            border.width: 1

                            Row {
                                anchors.fill: parent
                                anchors.margins: Theme.spacingM
                                anchors.rightMargin: Theme.spacingS // Reduced right margin
                                spacing: Theme.spacingL

                                // Index number
                                Rectangle {
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: Theme.primarySelected
                                    anchors.verticalCenter: parent.verticalCenter

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: entryIndex.toString()
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Bold
                                        color: Theme.primary
                                    }

                                }

                                // Content thumbnail/icon and text
                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 68 // Account for index (24) + spacing (16) + delete button (32) - small margin
                                    spacing: Theme.spacingM

                                    // Thumbnail or icon container
                                    Item {
                                        width: entryType === "image" ? 48 : Theme.iconSize
                                        height: entryType === "image" ? 48 : Theme.iconSize
                                        anchors.verticalCenter: parent.verticalCenter

                                        // Image thumbnail
                                        CachingImage {
                                            id: thumbnailImageSource
                                            anchors.fill: parent
                                            source: entryType === "image" && imagemagickAvailable ? "file://" + getThumbnailPath(model.entry) : ""
                                            fillMode: Image.PreserveAspectCrop
                                            smooth: true
                                            cache: true
                                            visible: false
                                            asynchronous: true
                                            
                                            // Handle loading errors gracefully and retry once
                                            onStatusChanged: {
                                                if (status === Image.Error && source !== "") {
                                                    // Clear source to prevent repeated error attempts
                                                    const originalSource = source;
                                                    source = "";
                                                    
                                                    // Retry once after 2 seconds to allow thumbnail generation
                                                    retryTimer.originalSource = originalSource;
                                                    retryTimer.start();
                                                }
                                            }
                                            
                                            Timer {
                                                id: retryTimer
                                                interval: 2000
                                                repeat: false
                                                property string originalSource: ""
                                                
                                                onTriggered: {
                                                    if (originalSource !== "" && thumbnailImageSource.source === "") {
                                                        thumbnailImageSource.source = originalSource;
                                                    }
                                                }
                                            }
                                        }

                                        MultiEffect {
                                            anchors.fill: parent
                                            source: thumbnailImageSource
                                            maskEnabled: true
                                            maskSource: clipboardCircularMask
                                            visible: entryType === "image" && imagemagickAvailable && thumbnailImageSource.status === Image.Ready
                                            maskThresholdMin: 0.5
                                            maskSpreadAtMin: 1
                                        }

                                        Item {
                                            id: clipboardCircularMask
                                            width: 48
                                            height: 48
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

                                        // Fallback icon
                                        DankIcon {
                                            visible: !(entryType === "image" && imagemagickAvailable && thumbnailImageSource.status === Image.Ready)
                                            name: {
                                                if (entryType === "image")
                                                    return "image";
                                                if (entryType === "long_text")
                                                    return "subject";
                                                return "content_copy";
                                            }
                                            size: Theme.iconSize
                                            color: Theme.primary
                                            anchors.centerIn: parent
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - (entryType === "image" ? 48 : Theme.iconSize) - Theme.spacingM
                                        spacing: Theme.spacingXS

                                        StyledText {
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
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.primary
                                            font.weight: Font.Medium
                                            width: parent.width
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            id: contentText

                                            text: entryPreview
                                            font.pixelSize: Theme.fontSizeMedium
                                            color: Theme.surfaceText
                                            width: parent.width
                                            wrapMode: Text.WordWrap
                                            maximumLineCount: entryType === "long_text" ? 3 : 1
                                            elide: Text.ElideRight
                                        }

                                    }

                                }

                            }

                            // Delete button
                            DankActionButton {
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.spacingM
                                anchors.verticalCenter: parent.verticalCenter
                                iconName: "close"
                                iconSize: Theme.iconSize - 6
                                iconColor: Theme.error
                                hoverColor: Theme.errorHover
                                onClicked: {
                                    console.log("Delete clicked for entry:", model.entry);
                                    deleteEntry(model.entry);
                                }
                            }

                            // Main click area - explicitly excludes delete button area
                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                anchors.rightMargin: 40 // Enough space to avoid delete button (32 + 8 margin)
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: copyEntry(model.entry)
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.shortDuration
                                }
                            }

                        }

                    }

            }

        }

    }

}
