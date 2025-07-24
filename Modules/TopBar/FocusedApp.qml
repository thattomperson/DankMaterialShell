import QtQuick
import qs.Common
import qs.Services

Rectangle {
    id: root

    property bool compactMode: false
    property int availableWidth: 400
    readonly property int baseWidth: contentRow.implicitWidth + Theme.spacingS * 2
    readonly property int maxNormalWidth: 456
    readonly property int maxCompactWidth: 288

    width: compactMode ? Math.min(baseWidth, maxCompactWidth) : Math.min(baseWidth, maxNormalWidth)
    height: 30
    radius: Theme.cornerRadius
    color: mouseArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)
    clip: true
    visible: FocusedWindowService.niriAvailable && (FocusedWindowService.focusedAppName || FocusedWindowService.focusedWindowTitle)

    Row {
        id: contentRow

        anchors.centerIn: parent
        spacing: Theme.spacingS

        Text {
            id: appText

            text: FocusedWindowService.focusedAppName || ""
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            width: Math.min(implicitWidth, compactMode ? 80 : 180)
        }

        Text {
            text: "•"
            font.pixelSize: Theme.fontSizeMedium
            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.5)
            anchors.verticalCenter: parent.verticalCenter
            visible: appText.text && titleText.text
        }

        Text {
            id: titleText

            text: FocusedWindowService.focusedWindowTitle || ""
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            width: Math.min(implicitWidth, compactMode ? 180 : 250)
            visible: text.length > 0
        }

    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
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
