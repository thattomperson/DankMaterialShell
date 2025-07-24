import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import qs.Common
import qs.Modals
import qs.Services
import qs.Widgets

ScrollView {
    id: personalizationTab

    property alias profileBrowser: profileBrowserLoader.item
    property alias wallpaperBrowser: wallpaperBrowserLoader.item

    contentWidth: availableWidth
    contentHeight: column.implicitHeight
    clip: true

    Column {
        id: column

        width: parent.width
        spacing: Theme.spacingXL

        // Profile Section
        StyledRect {
            width: parent.width
            height: profileSection.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadiusLarge
            color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            border.width: 1

            Column {
                id: profileSection

                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    DankIcon {
                        name: "person"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "Profile Image"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingL

                    // Circular profile image preview
                    Item {
                        id: avatarContainer

                        property bool hasImage: avatarImageSource.status === Image.Ready

                        width: 80
                        height: 80

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.color: Theme.primary
                            border.width: 1
                            visible: parent.hasImage
                        }

                        Image {
                            id: avatarImageSource

                            source: {
                                if (Prefs.profileImage === "")
                                    return "";

                                if (Prefs.profileImage.startsWith("/"))
                                    return "file://" + Prefs.profileImage;

                                return Prefs.profileImage;
                            }
                            smooth: true
                            asynchronous: true
                            mipmap: true
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

                            width: 70
                            height: 70
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
                                size: Theme.iconSizeLarge + 8
                                color: Theme.primaryText
                            }

                        }

                        DankIcon {
                            anchors.centerIn: parent
                            name: "warning"
                            size: Theme.iconSizeLarge
                            color: Theme.error
                            visible: Prefs.profileImage !== "" && avatarImageSource.status === Image.Error
                        }

                    }

                    Column {
                        width: parent.width - 80 - Theme.spacingL
                        spacing: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter

                        StyledText {
                            text: Prefs.profileImage ? Prefs.profileImage.split('/').pop() : "No profile image selected"
                            font.pixelSize: Theme.fontSizeLarge
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

                        Row {
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
                                        text: "Browse"
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
                                opacity: Prefs.profileImage !== "" ? 1 : 0.5

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

                }

            }

        }

        // Wallpaper Section
        StyledRect {
            width: parent.width
            height: wallpaperSection.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadiusLarge
            color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            border.width: 1

            Column {
                id: wallpaperSection

                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    DankIcon {
                        name: "wallpaper"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "Wallpaper"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingL

                    // Wallpaper Preview
                    StyledRect {
                        width: 160
                        height: 90
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
                            maxCacheSize: 160
                            layer.enabled: true

                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: wallpaperMask
                                maskThresholdMin: 0.5
                                maskSpreadAtMin: 1
                            }

                        }

                        Rectangle {
                            id: wallpaperMask

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
                            size: Theme.iconSizeLarge + 8
                            color: Theme.surfaceVariantText
                            visible: Prefs.wallpaperPath === ""
                        }

                    }

                    Column {
                        width: parent.width - 160 - Theme.spacingL
                        spacing: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter

                        StyledText {
                            text: Prefs.wallpaperPath ? Prefs.wallpaperPath.split('/').pop() : "No wallpaper selected"
                            font.pixelSize: Theme.fontSizeLarge
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

                        Row {
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
                                        text: "Browse"
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
                                opacity: Prefs.wallpaperPath !== "" ? 1 : 0.5

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

                }

            }

        }

        // Dynamic Theming Section
        StyledRect {
            width: parent.width
            height: dynamicThemeSection.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadiusLarge
            color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            border.width: 1

            Column {
                id: dynamicThemeSection

                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    DankIcon {
                        name: "palette"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        width: parent.width - Theme.iconSize - Theme.spacingM - toggle.width - Theme.spacingM
                        spacing: Theme.spacingXS
                        anchors.verticalCenter: parent.verticalCenter

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
                            if (toggled)
                                Theme.switchTheme(10, true);
                            else
                                Theme.switchTheme(0);
                        }
                    }

                }

                StyledText {
                    text: "matugen not detected - dynamic theming unavailable"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.error
                    visible: ToastService.wallpaperErrorStatus === "matugen_missing"
                    width: parent.width
                    leftPadding: Theme.iconSize + Theme.spacingM
                }

            }

        }

    }

    LazyLoader {
        id: profileBrowserLoader

        active: false

        FileBrowserModal {
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

    LazyLoader {
        id: wallpaperBrowserLoader

        active: false

        FileBrowserModal {
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

}
