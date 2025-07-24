import QtQuick
import QtQuick.Controls
import QtCore
import Qt.labs.folderlistmodel
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modals

DankModal {
    id: fileBrowser

    signal fileSelected(string path)

    property string homeDir: StandardPaths.writableLocation(StandardPaths.HomeLocation)
    property string currentPath: ""
    property var fileExtensions: ["*.*"]
    property string browserTitle: "Select File"
    property string browserIcon: "folder_open"
    property string browserType: "generic" // "wallpaper" or "profile" for last path memory

    FolderListModel {
        id: folderModel
        showDirsFirst: true
        showDotAndDotDot: false
        showHidden: false
        nameFilters: fileExtensions
        showFiles: true
        showDirs: true
        folder: currentPath ? "file://" + currentPath : "file://" + homeDir
    }
    
    function getLastPath() {
        var lastPath = "";
        if (browserType === "wallpaper") {
            lastPath = Prefs.wallpaperLastPath;
        } else if (browserType === "profile") {
            lastPath = Prefs.profileLastPath;
        }
        
        // Check if last path exists, otherwise use home
        if (lastPath && lastPath !== "") {
            // TODO: Could add directory existence check here
            return lastPath;
        }
        return homeDir;
    }
    
    function saveLastPath(path) {
        if (browserType === "wallpaper") {
            Prefs.wallpaperLastPath = path;
        } else if (browserType === "profile") {
            Prefs.profileLastPath = path;
        }
        Prefs.saveSettings();
    }

    Component.onCompleted: {
        currentPath = getLastPath();
    }

    width: 800
    height: 600
    keyboardFocus: "ondemand"
    enableShadow: true
    visible: false

    onBackgroundClicked: visible = false
    
    onVisibleChanged: {
        if (visible) {
            // Use last path or home directory when opening
            var startPath = getLastPath();
            console.log("Opening file browser, setting path to:", startPath);
            currentPath = startPath;
        }
    }
    
    onCurrentPathChanged: {
        console.log("Current path changed to:", currentPath);
        console.log("Model count:", folderModel.count);
        // Log first few files to debug
        for (var i = 0; i < Math.min(3, folderModel.count); i++) {
            console.log("File", i, ":", folderModel.get(i, "fileName"));
        }
    }
    
    function navigateUp() {
        var path = currentPath;
        
        // Don't go above home directory
        if (path === homeDir) {
            console.log("Already at home directory, can't go up");
            return;
        }
        
        var lastSlash = path.lastIndexOf('/');
        if (lastSlash > 0) {
            var newPath = path.substring(0, lastSlash);
            // Make sure we don't go above home (check if newPath starts with homeDir)
            if (newPath.startsWith(homeDir)) {
                console.log("Navigating up from", path, "to", newPath);
                currentPath = newPath;
                saveLastPath(newPath);
            } else {
                console.log("Would go above home directory, stopping at", homeDir);
                currentPath = homeDir;
                saveLastPath(homeDir);
            }
        }
    }

    function navigateTo(path) {
        currentPath = path;
        saveLastPath(path); // Save the path when navigating
    }

    content: Component {
        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingS

            // Header
            Row {
                width: parent.width
                spacing: Theme.spacingM

                DankIcon {
                    name: browserIcon
                    size: Theme.iconSizeLarge
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: browserTitle
                    font.pixelSize: Theme.fontSizeXLarge
                    color: Theme.surfaceText
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    width: parent.width - 200
                    height: 1
                }

                // Close button
                DankActionButton {
                    iconName: "close"
                    iconSize: Theme.iconSizeSmall
                    iconColor: Theme.surfaceText
                    onClicked: fileBrowser.visible = false
                }
            }

            // Current path display and navigation
            Row {
                width: parent.width
                spacing: Theme.spacingS

                StyledRect {
                    width: 32
                    height: 32
                    radius: Theme.cornerRadius
                    color: mouseArea.containsMouse && currentPath !== homeDir ? Theme.surfaceVariant : "transparent"
                    opacity: currentPath !== homeDir ? 1.0 : 0.0
                    
                    DankIcon {
                        anchors.centerIn: parent
                        name: "arrow_back"
                        size: Theme.iconSizeSmall
                        color: Theme.surfaceText
                    }
                    
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: currentPath !== homeDir
                        cursorShape: currentPath !== homeDir ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: currentPath !== homeDir
                        onClicked: navigateUp()
                    }
                }

                StyledText {
                    text: "Current folder: " + fileBrowser.currentPath
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    width: parent.width - 40 - Theme.spacingS
                    elide: Text.ElideMiddle
                    anchors.verticalCenter: parent.verticalCenter
                    maximumLineCount: 1
                    wrapMode: Text.NoWrap
                }
            }

            // File grid
            ScrollView {
                width: parent.width
                height: parent.height - 80
                clip: true

                GridView {
                    id: fileGrid
                    
                    cellWidth: 150
                    cellHeight: 130
                    
                    model: folderModel

                    delegate: StyledRect {
                        width: 140
                        height: 120
                        radius: Theme.cornerRadius
                        color: mouseArea.containsMouse ? Theme.surfaceVariant : "transparent"
                        border.color: Theme.outline
                        border.width: mouseArea.containsMouse ? 1 : 0

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            // Image preview or folder icon
                            Item {
                                width: 80
                                height: 60
                                anchors.horizontalCenter: parent.horizontalCenter

                                Image {
                                    anchors.fill: parent
                                    source: !model.fileIsDir ? model.fileURL : ""
                                    fillMode: Image.PreserveAspectCrop
                                    visible: !model.fileIsDir
                                    asynchronous: true
                                }

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: model.fileIsDir ? "folder" : "description"
                                    size: Theme.iconSizeLarge
                                    color: Theme.primary
                                    visible: model.fileIsDir
                                }
                            }

                            // File name
                            StyledText {
                                text: model.fileName || ""
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                width: 120
                                elide: Text.ElideMiddle
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                maximumLineCount: 2
                                wrapMode: Text.WordWrap
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                if (model.fileIsDir) {
                                    navigateTo(model.filePath);
                                } else {
                                    fileSelected(model.filePath);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}