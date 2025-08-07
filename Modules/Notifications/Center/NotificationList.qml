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
    
    // Qt 6.9+ scrolling: flickDeceleration/maximumFlickVelocity only affect touch now
    flickDeceleration: 1500
    maximumFlickVelocity: 2000
    boundsMovement: Flickable.FollowBoundsBehavior
    pressDelay: 0
    flickableDirection: Flickable.VerticalFlick
    cacheBuffer: 1000
    
    // Custom wheel handler for Qt 6.9+ responsive mouse wheel scrolling
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        property real momentum: 0
        onWheel: (event) => {
            if (event.pixelDelta.y !== 0) {
                // Touchpad with pixel delta
                momentum = event.pixelDelta.y * 1.8
            } else {
                // Mouse wheel with angle delta
                momentum = (event.angleDelta.y / 120) * (parent.spacing * 2.5) // ~2.5 items per wheel step
            }
            
            let newY = parent.contentY - momentum
            newY = Math.max(0, Math.min(parent.contentHeight - parent.height, newY))
            parent.contentY = newY
            momentum *= 0.92 // Decay for smooth momentum
            event.accepted = true
        }
    }
    
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
