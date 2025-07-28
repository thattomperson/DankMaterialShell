import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets

ScrollView {
    id: timeWeatherTab

    contentWidth: availableWidth
    contentHeight: column.implicitHeight
    clip: true

    Column {
        id: column

        width: parent.width
        spacing: Theme.spacingXL

        // Time Settings Section
        StyledRect {
            width: parent.width
            height: timeSection.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadiusLarge
            color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            border.width: 1

            Column {
                id: timeSection

                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    DankIcon {
                        name: "schedule"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "Time Format"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                DankToggle {
                    width: parent.width
                    text: "24-Hour Format"
                    description: "Use 24-hour time format instead of 12-hour AM/PM"
                    checked: Prefs.use24HourClock
                    onToggled: (checked) => {
                        return Prefs.setClockFormat(checked);
                    }
                }

            }

        }

        // Weather Settings Section
        StyledRect {
            width: parent.width
            height: weatherSection.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadiusLarge
            color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            border.width: 1

            Column {
                id: weatherSection

                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    DankIcon {
                        name: "cloud"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "Weather"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                DankToggle {
                    width: parent.width
                    text: "Fahrenheit"
                    description: "Use Fahrenheit instead of Celsius for temperature"
                    checked: Prefs.useFahrenheit
                    onToggled: (checked) => {
                        return Prefs.setTemperatureUnit(checked);
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingXS

                    StyledText {
                        text: "Location"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                    }

                    DankLocationSearch {
                        width: parent.width
                        currentLocation: Prefs.weatherLocation
                        placeholderText: "New York, NY"
                        onLocationSelected: (displayName, coordinates) => {
                            Prefs.setWeatherLocation(displayName, coordinates);
                        }
                    }

                }

            }

        }

    }

}
