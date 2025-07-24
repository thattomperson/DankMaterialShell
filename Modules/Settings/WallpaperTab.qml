import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

Column {
    id: wallpaperTab

    width: parent.width
    spacing: Theme.spacingM

    // Current Wallpaper Section
    Column {
        width: parent.width
        spacing: Theme.spacingS

        StyledText {
            text: "Current Wallpaper"
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Medium
            color: Theme.surfaceText
        }

        Row {
            width: parent.width
            spacing: Theme.spacingM

            // Wallpaper Preview
            StyledRect {
                width: 120
                height: 67
                radius: Theme.cornerRadius
                color: Theme.surfaceVariant
                border.color: Theme.outline
                border.width: 1

                CachingImage {
                    anchors.fill: parent
                    anchors.margins: 1
                    imagePath: Prefs.wallpaperPath || ""
                    fillMode: Image.PreserveAspectCrop
                    visible: Prefs.wallpaperPath !== ""
                    maxCacheSize: 120
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: mask
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                    }
                }
                
                Rectangle {
                    id: mask
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: Theme.cornerRadius - 1
                    color: "black"
                    visible: false
                    layer.enabled: true
                }

                DankIcon {
                    anchors.centerIn: parent
                    name: "image"
                    size: Theme.iconSizeLarge
                    color: Theme.surfaceVariantText
                    visible: Prefs.wallpaperPath === ""
                }
            }

            Column {
                width: parent.width - 120 - Theme.spacingM
                spacing: Theme.spacingS
                anchors.verticalCenter: parent.verticalCenter

                StyledText {
                    text: Prefs.wallpaperPath ? Prefs.wallpaperPath.split('/').pop() : "No wallpaper selected"
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    elide: Text.ElideMiddle
                    width: parent.width
                }

                StyledText {
                    text: Prefs.wallpaperPath ? Prefs.wallpaperPath : ""
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    elide: Text.ElideMiddle
                    width: parent.width
                    visible: Prefs.wallpaperPath !== ""
                }
            }
        }

        Row {
            width: parent.width
            spacing: Theme.spacingS

            StyledRect {
                width: 100
                height: 32
                radius: Theme.cornerRadius
                color: Theme.primary
                
                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingXS
                    
                    DankIcon {
                        name: "folder_open"
                        size: Theme.iconSizeSmall
                        color: Theme.primaryText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    StyledText {
                        text: "Browse..."
                        color: Theme.primaryText
                        font.pixelSize: Theme.fontSizeSmall
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        wallpaperBrowserLoader.active = true;
                        wallpaperBrowser.visible = true;
                    }
                }
            }

            StyledRect {
                width: 80
                height: 32
                radius: Theme.cornerRadius
                color: Theme.surfaceVariant
                opacity: Prefs.wallpaperPath !== "" ? 1.0 : 0.5
                
                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingXS
                    
                    DankIcon {
                        name: "clear"
                        size: Theme.iconSizeSmall
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    StyledText {
                        text: "Clear"
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    enabled: Prefs.wallpaperPath !== ""
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        Prefs.setWallpaperPath("");
                    }
                }
            }
        }
    }


    // Dynamic Theming Section
    Column {
        width: parent.width
        spacing: Theme.spacingS

        Row {
            width: parent.width
            spacing: Theme.spacingM

            Column {
                width: parent.width - toggle.width - Theme.spacingM
                spacing: Theme.spacingXS

                StyledText {
                    text: "Dynamic Theming"
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                StyledText {
                    text: "Automatically extract colors from wallpaper"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }

            DankToggle {
                id: toggle
                anchors.verticalCenter: parent.verticalCenter
                checked: Theme.isDynamicTheme
                enabled: ToastService.wallpaperErrorStatus !== "matugen_missing"
                onToggled: (toggled) => {
                    if (toggled) {
                        Theme.switchTheme(10, true)
                    } else {
                        Theme.switchTheme(0)
                    }
                }
            }
        }
        
        StyledText {
            text: "matugen not detected"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.error
            visible: ToastService.wallpaperErrorStatus === "matugen_missing"
            width: parent.width
        }
    }

    LazyLoader {
        id: wallpaperBrowserLoader
        active: false
        
        DankFileBrowser {
            id: wallpaperBrowser
            browserTitle: "Select Wallpaper"
            browserIcon: "wallpaper"
            browserType: "wallpaper"
            fileExtensions: ["*.jpg", "*.jpeg", "*.png", "*.bmp", "*.gif", "*.webp"]
            onFileSelected: (path) => {
                Prefs.setWallpaperPath(path);
                visible = false;
            }
        }
    }
    
    property alias wallpaperBrowser: wallpaperBrowserLoader.item
}