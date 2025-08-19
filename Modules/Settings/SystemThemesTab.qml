import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: systemThemesTab

    DankFlickable {
        anchors.fill: parent
        anchors.topMargin: Theme.spacingL
        clip: true
        contentHeight: mainColumn.height
        contentWidth: width

        Column {
            id: mainColumn

            width: parent.width
            spacing: Theme.spacingXL

            // System Configuration Warning
            Rectangle {
                width: parent.width
                height: warningText.implicitHeight + Theme.spacingM * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.12)
                border.color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.3)
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingM

                    DankIcon {
                        name: "info"
                        size: Theme.iconSizeSmall
                        color: Theme.warning
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        id: warningText

                        text: "Changing these settings will manipulate GTK and Qt configurations on the system"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.warning
                        wrapMode: Text.WordWrap
                        width: parent.width - Theme.iconSizeSmall - Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

            }

            // Icon Theme
            StyledRect {
                width: parent.width
                height: iconThemeSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: iconThemeSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingXS

                        DankIcon {
                            name: "image"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        DankDropdown {
                            width: parent.width - Theme.iconSize - Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Icon Theme"
                            description: "DankShell & System Icons"
                            currentValue: SettingsData.iconTheme
                            enableFuzzySearch: true
                            popupWidthOffset: 100
                            maxPopupHeight: 400
                            options: {
                                SettingsData.detectAvailableIconThemes();
                                return SettingsData.availableIconThemes;
                            }
                            onValueChanged: (value) => {
                                SettingsData.setIconTheme(value);
                                if (value !== "System Default" && !SettingsData.qt5ctAvailable && !SettingsData.qt6ctAvailable)
                                    ToastService.showWarning("qt5ct or qt6ct not found - Qt app themes may not update without these tools");

                            }
                        }

                    }

                }

            }

            // System App Theming
            StyledRect {
                width: parent.width
                height: systemThemingSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 1
                visible: Theme.isDynamicTheme && Colors.matugenAvailable

                Column {
                    id: systemThemingSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "extension"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "System App Theming"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                    }

                    DankToggle {
                        width: parent.width
                        text: "Theme GTK Applications"
                        description: Colors.gtkThemingEnabled ? "File managers, text editors, and system dialogs will match your theme" : "GTK theming not available (install gsettings)"
                        enabled: Colors.gtkThemingEnabled
                        checked: Colors.gtkThemingEnabled && SettingsData.gtkThemingEnabled
                        onToggled: function(checked) {
                            SettingsData.setGtkThemingEnabled(checked);
                        }
                    }

                    DankToggle {
                        width: parent.width
                        text: "Theme Qt Applications"
                        description: Colors.qtThemingEnabled ? "Qt applications will match your theme colors" : "Qt theming not available (install qt5ct or qt6ct)"
                        enabled: Colors.qtThemingEnabled
                        checked: Colors.qtThemingEnabled && SettingsData.qtThemingEnabled
                        onToggled: function(checked) {
                            SettingsData.setQtThemingEnabled(checked);
                        }
                    }

                }

            }

        }

    }

}