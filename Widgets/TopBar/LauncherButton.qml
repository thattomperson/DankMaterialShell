import QtQuick
import qs.Common
import qs.Services

Rectangle {
    id: root

    readonly property bool nerdFontAvailable: Qt.fontFamilies()
                                  .indexOf("Symbols Nerd Font") !== -1

    Component.onCompleted: {
        console.log(Qt.fontFamilies());
    }

    width: 40
    height: 30
    radius: Theme.cornerRadius
    color: launcherArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.12) : Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)

    Text {
        anchors.centerIn: parent
        text: nerdFontAvailable && OSDetectorService.osLogo || "apps"
        font.family: nerdFontAvailable && OSDetectorService.osLogo ? "Symbols Nerd Font" : Theme.iconFont
        font.pixelSize: Theme.iconSize - 6
        font.weight: Theme.iconFontWeight
        color: Theme.surfaceText
    }

    MouseArea {
        id: launcherArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            LauncherService.toggleAppLauncher();
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing
        }

    }

}
