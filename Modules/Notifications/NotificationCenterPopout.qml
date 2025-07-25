import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets

PanelWindow {
    id: root

    property bool notificationHistoryVisible: false

    visible: notificationHistoryVisible
    implicitWidth: 400
    implicitHeight: Math.min(Screen.height * 0.6, Math.max(580, 720))
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            notificationHistoryVisible = false;
        }
    }

    Rectangle {
        width: 400
        height: Math.min(Screen.height * 0.6, Math.max(580, 720))
        x: Screen.width - width - Theme.spacingL
        y: Theme.barHeight + Theme.spacingXS
        color: Theme.popupBackground()
        radius: Theme.cornerRadiusLarge
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
        border.width: 1
        opacity: notificationHistoryVisible ? 1 : 0
        
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            color: "transparent"
            radius: parent.radius + 3
            border.color: Qt.rgba(0, 0, 0, 0.05)
            border.width: 1
            z: -3
        }
        
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            color: "transparent"
            radius: parent.radius + 2
            border.color: Qt.rgba(0, 0, 0, 0.08)
            border.width: 1
            z: -2
        }
        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
            border.width: 1
            radius: parent.radius
            z: -1
        }

        transform: [
            Scale {
                id: scaleTransform

                origin.x: 400
                origin.y: 0
                xScale: notificationHistoryVisible ? 1 : 0.95
                yScale: notificationHistoryVisible ? 1 : 0.8
            },
            Translate {
                id: translateTransform

                x: notificationHistoryVisible ? 0 : 15
                y: notificationHistoryVisible ? 0 : -30
            }
        ]

        states: [
            State {
                name: "visible"
                when: notificationHistoryVisible

                PropertyChanges {
                    target: scaleTransform
                    xScale: 1
                    yScale: 1
                }

                PropertyChanges {
                    target: translateTransform
                    x: 0
                    y: 0
                }
            },
            State {
                name: "hidden"
                when: !notificationHistoryVisible

                PropertyChanges {
                    target: scaleTransform
                    xScale: 0.95
                    yScale: 0.8
                }

                PropertyChanges {
                    target: translateTransform
                    x: 15
                    y: -30
                }
            }
        ]

        transitions: [
            Transition {
                from: "*"
                to: "*"

                ParallelAnimation {
                    NumberAnimation {
                        targets: [scaleTransform, translateTransform]
                        properties: "xScale,yScale,x,y"
                        duration: Theme.mediumDuration
                        easing.type: Theme.emphasizedEasing
                    }
                }
            }
        ]

        MouseArea {
            anchors.fill: parent
            onClicked: {
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            NotificationHeader {}
            
            NotificationList {}
        }

        Behavior on height {
            NumberAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
            }
        }
    }
}