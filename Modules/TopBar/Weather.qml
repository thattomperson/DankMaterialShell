import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    signal clicked()

    // Visibility is now controlled by TopBar.qml
    width: visible ? Math.min(100, weatherRow.implicitWidth + Theme.spacingS * 2) : 0
    height: 30
    radius: Theme.cornerRadius
    color: {
        const baseColor = weatherArea.containsMouse ? Theme.primaryHover : Theme.surfaceTextHover;
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, baseColor.a * Theme.widgetTransparency);
    }

    Ref {
        service: WeatherService
    }

    Row {
        id: weatherRow

        anchors.centerIn: parent
        spacing: Theme.spacingXS

        DankIcon {
            name: WeatherService.getWeatherIcon(WeatherService.weather.wCode)
            size: Theme.iconSize - 4
            color: Theme.primary
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            text: (Prefs.useFahrenheit ? WeatherService.weather.tempF : WeatherService.weather.temp) + "°" + (Prefs.useFahrenheit ? "F" : "C")
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter
        }

    }

    MouseArea {
        id: weatherArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing
        }

    }

    Behavior on width {
        NumberAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing
        }

    }

}
