import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services

ListView {
    id: root

    property alias count: root.count
    readonly property real listContentHeight: root.contentHeight
    readonly property bool atYBeginning: root.contentY === 0
    property real stableY: 0
    property bool isUserScrolling: false

    width: parent.width
    height: parent.height
    clip: true
    model: NotificationService.groupedNotifications
    spacing: Theme.spacingL
    interactive: true
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 1500
    maximumFlickVelocity: 2000
    cacheBuffer: 1000
    onMovementStarted: isUserScrolling = true
    onMovementEnded: {
        isUserScrolling = false;
        if (contentY > 40)
            stableY = contentY;

    }
    onContentYChanged: {
        if (!isUserScrolling && visible && parent.visible && stableY > 40 && Math.abs(contentY - stableY) > 10)
            contentY = stableY;

    }

    NotificationEmptyState {
        visible: root.count === 0
        anchors.centerIn: parent
    }

    add: Transition {
        enabled: !root.isUserScrolling

        ParallelAnimation {
            NumberAnimation {
                properties: "opacity"
                from: 0
                to: 1
                duration: root.isUserScrolling ? 0 : Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
            }

            NumberAnimation {
                properties: "height"
                from: 0
                duration: root.isUserScrolling ? 0 : Theme.mediumDuration
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
        enabled: false

        NumberAnimation {
            properties: "y"
            duration: 0
        }

    }

    move: Transition {
        enabled: false

        NumberAnimation {
            properties: "y"
            duration: 0
            easing.type: Theme.emphasizedEasing
        }

    }

    delegate: NotificationCard {
        notificationGroup: modelData
    }

}
