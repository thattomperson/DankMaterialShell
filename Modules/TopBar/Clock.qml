import QtQuick
import Quickshell
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property date currentDate: new Date()
    property bool compactMode: false

    signal clockClicked()

    width: clockRow.implicitWidth + Theme.spacingS * 2
    height: 30
    radius: Theme.cornerRadius
    color: {
        const baseColor = clockMouseArea.containsMouse ? Theme.primaryHover : Theme.surfaceTextHover;
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, baseColor.a * Theme.widgetTransparency);
    }
    Component.onCompleted: {
        root.currentDate = systemClock.date;
    }

    Row {
        id: clockRow

        anchors.centerIn: parent
        spacing: Theme.spacingS

        StyledText {
            text: Prefs.use24HourClock ? Qt.formatTime(root.currentDate, "H:mm") : Qt.formatTime(root.currentDate, "h:mm AP")
            font.pixelSize: Theme.fontSizeMedium - 1
            color: Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            text: "•"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.outlineButton
            anchors.verticalCenter: parent.verticalCenter
            visible: !compactMode
        }

        StyledText {
            text: Qt.formatDate(root.currentDate, "ddd d")
            font.pixelSize: Theme.fontSizeMedium - 1
            color: Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter
            visible: !compactMode
        }

    }

    SystemClock {
        id: systemClock

        precision: SystemClock.Seconds
        onDateChanged: root.currentDate = systemClock.date
    }

    MouseArea {
        id: clockMouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.clockClicked();
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing
        }

    }

}
