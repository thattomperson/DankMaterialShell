import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Common
import qs.Widgets

Column {
    width: parent.width
    spacing: Theme.spacingM

    // Profile Image Preview and Input
    Column {
        width: parent.width
        spacing: Theme.spacingM

        StyledText {
            text: "Profile Image"
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Medium
            color: Theme.surfaceText
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

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.color: Theme.primary
                    border.width: 1
                    visible: parent.hasImage
                }

                CachingImage {
                    id: avatarImageSource

                    imagePath: {
                        if (Prefs.profileImage === "")
                            return "";

                        if (Prefs.profileImage.startsWith("/"))
                            return Prefs.profileImage;

                        return Prefs.profileImage;
                    }
                    smooth: true
                    asynchronous: true
                    maxCacheSize: 80
                    cache: true
                    visible: false
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

                DankIcon {
                    anchors.centerIn: parent
                    name: "warning"
                    size: Theme.iconSize + 8
                    color: Theme.primaryText
                    visible: Prefs.profileImage !== "" && avatarImageSource.status === Image.Error
                }

            }

            Column {
                width: parent.width - 54 - Theme.spacingM
                spacing: Theme.spacingS
                anchors.verticalCenter: parent.verticalCenter

                StyledText {
                    text: Prefs.profileImage ? Prefs.profileImage.split('/').pop() : "No profile image selected"
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    elide: Text.ElideMiddle
                    width: parent.width
                }

                StyledText {
                    text: Prefs.profileImage ? Prefs.profileImage : ""
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    elide: Text.ElideMiddle
                    width: parent.width
                    visible: Prefs.profileImage !== ""
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
                        profileBrowserLoader.active = true;
                        profileBrowser.visible = true;
                    }
                }
            }

            StyledRect {
                width: 80
                height: 32
                radius: Theme.cornerRadius
                color: Theme.surfaceVariant
                opacity: Prefs.profileImage !== "" ? 1.0 : 0.5
                
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
                    enabled: Prefs.profileImage !== ""
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        Prefs.setProfileImage("");
                    }
                }
            }

        }
    }

    LazyLoader {
        id: profileBrowserLoader
        active: false
        
        DankFileBrowser {
            id: profileBrowser
            browserTitle: "Select Profile Image"
            browserIcon: "person"
            browserType: "profile"
            fileExtensions: ["*.jpg", "*.jpeg", "*.png", "*.bmp", "*.gif", "*.webp"]
            onFileSelected: (path) => {
                Prefs.setProfileImage(path);
                visible = false;
            }
        }
    }
    
    property alias profileBrowser: profileBrowserLoader.item

}
