import QtQuick
import qs.Common

Item {
    id: toggle

    property bool checked: false
    property bool enabled: true
    property bool toggling: false

    signal clicked()

    width: 48
    height: 24

    Rectangle {
        id: toggleTrack
        width: parent.width
        height: parent.height
        radius: height / 2
        color: toggle.checked ? Theme.primary : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
        opacity: toggle.toggling ? 0.6 : 1

        Rectangle {
            id: toggleHandle
            width: 20
            height: 20
            radius: 10
            color: Theme.surface
            anchors.verticalCenter: parent.verticalCenter
            x: toggle.checked ? parent.width - width - 2 : 2

            Behavior on x {
                NumberAnimation {
                    duration: Theme.shortDuration
                    easing.type: Theme.emphasizedEasing
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 2
                height: parent.height + 2
                radius: (parent.width + 2) / 2
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.1)
                border.width: 1
                z: -1
            }
        }

        MouseArea {
            id: toggleArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: toggle.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            enabled: toggle.enabled
            onClicked: toggle.clicked()
        }

        Behavior on color {
            ColorAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }
        }
    }
}