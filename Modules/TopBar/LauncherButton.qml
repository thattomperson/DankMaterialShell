import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    signal clicked()

    property bool isActive: false

    readonly property bool nerdFontAvailable: Qt.fontFamilies()
                                  .indexOf("Symbols Nerd Font") !== -1

    width: 40
    height: 30
    radius: Theme.cornerRadius
    color: launcherArea.containsMouse || isActive ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.12) : Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)

    Text {
        visible: nerdFontAvailable && OSDetectorService.osLogo
        anchors.centerIn: parent
        text: OSDetectorService.osLogo
        font.family: "Symbols Nerd Font"
        font.pixelSize: Theme.iconSize - 6
        font.weight: Theme.iconFontWeight
        color: Theme.surfaceText
    }

    DankIcon {
        visible: !nerdFontAvailable || !OSDetectorService.osLogo
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
