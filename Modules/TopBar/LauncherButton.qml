import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    property bool isActive: false

    signal clicked()

    width: 40
    height: 30
    radius: Theme.cornerRadius
    color: {
        const baseColor = launcherArea.containsMouse || isActive ? Theme.surfaceTextPressed : Theme.surfaceTextHover;
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, baseColor.a * Theme.widgetTransparency);
    }

    SystemLogo {
        visible: Prefs.useOSLogo
        anchors.centerIn: parent
        width: Theme.iconSize - 3
        height: Theme.iconSize - 3
        colorOverride: Prefs.osLogoColorOverride
        brightnessOverride: Prefs.osLogoBrightness
        contrastOverride: Prefs.osLogoContrast
    }

    DankIcon {
        visible: !Prefs.useOSLogo
        anchors.centerIn: parent
        name: "apps"
        size: Theme.iconSize - 6
        color: Theme.surfaceText
    }

    MouseArea {
        id: launcherArea

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

}
