import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services

ScrollView {
    id: root
    
    width: parent.width
    height: parent.height - 140
    clip: true
    contentWidth: -1
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ListView {
        id: notificationsList

        model: NotificationService.groupedNotifications
        spacing: Theme.spacingL
        interactive: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 1500
        maximumFlickVelocity: 2000

        add: Transition {
            ParallelAnimation {
                NumberAnimation {
                    properties: "opacity"
                    from: 0
                    to: 1
                    duration: Theme.mediumDuration
                    easing.type: Theme.emphasizedEasing
                }

                NumberAnimation {
                    properties: "height"
                    from: 0
                    duration: Theme.mediumDuration
                    easing.type: Theme.emphasizedEasing
                }
            }
        }

        remove: Transition {
            SequentialAnimation {
                PauseAnimation {
                    duration: 50
                }

                ParallelAnimation {
                    NumberAnimation {
                        properties: "opacity"
                        to: 0
                        duration: Theme.mediumDuration
                        easing.type: Theme.emphasizedEasing
                    }

                    NumberAnimation {
                        properties: "height,anchors.topMargin,anchors.bottomMargin"
                        to: 0
                        duration: Theme.mediumDuration
                        easing.type: Theme.emphasizedEasing
                    }
                }
            }
        }

        displaced: Transition {
            NumberAnimation {
                properties: "y"
                duration: Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
            }
        }

        move: Transition {
            NumberAnimation {
                properties: "y"
                duration: Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
            }
        }

        delegate: NotificationCard {
            notificationGroup: modelData
        }
    }

    NotificationEmptyState {}
}