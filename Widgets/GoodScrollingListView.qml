import QtQuick
import QtQuick.Controls

ListView {
    id: listView

    // Kinetic scrolling momentum properties
    property real momentumVelocity: 0
    property bool isMomentumActive: false
    property real friction: 0.95
    property real minMomentumVelocity: 50
    property real maxMomentumVelocity: 2500

    // Qt 6.9+ scrolling: flickDeceleration/maximumFlickVelocity only affect touch now
    flickDeceleration: 1500
    maximumFlickVelocity: 2000
    boundsBehavior: Flickable.StopAtBounds
    boundsMovement: Flickable.FollowBoundsBehavior
    pressDelay: 0
    flickableDirection: Flickable.VerticalFlick

    // Custom wheel handler for Qt 6.9+ responsive mouse wheel scrolling
    WheelHandler {
        id: wheelHandler

        // Tunable parameters for responsive scrolling
        property real mouseWheelSpeed: 20
        // Higher = faster mouse wheel
        property real touchpadSpeed: 1.8
        // Touchpad sensitivity
        property real momentumRetention: 0.92
        property real lastWheelTime: 0
        property real momentum: 0
        property var velocitySamples: []

        function startMomentum() {
            isMomentumActive = true;
            momentumTimer.start();
        }

        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            // Stop any existing momentum
            momentumTimer.stop();
            isMomentumActive = false;
            let currentTime = Date.now();
            let timeDelta = currentTime - lastWheelTime;
            lastWheelTime = currentTime;
            // Calculate scroll delta based on input type
            let delta = 0;
            if (event.pixelDelta.y !== 0)
                // Touchpad with pixel precision
                delta = event.pixelDelta.y * touchpadSpeed;
            else
                // Mouse wheel - moderate steps for comfortable scrolling
                delta = event.angleDelta.y / 120 * 72 * 1.2; // Using default item height
            // Track velocity for momentum
            velocitySamples.push({
                "delta": delta,
                "time": currentTime
            });
            velocitySamples = velocitySamples.filter((s) => {
                return currentTime - s.time < 100;
            });
            // Calculate momentum velocity from samples
            if (velocitySamples.length > 1) {
                let totalDelta = velocitySamples.reduce((sum, s) => {
                    return sum + s.delta;
                }, 0);
                let timeSpan = currentTime - velocitySamples[0].time;
                if (timeSpan > 0)
                    momentumVelocity = Math.max(-maxMomentumVelocity, Math.min(maxMomentumVelocity, totalDelta / timeSpan * 1000));

            }
            // Apply momentum for touchpad (smooth continuous scrolling)
            if (event.pixelDelta.y !== 0 && timeDelta < 50) {
                momentum = momentum * momentumRetention + delta * 0.15;
                delta += momentum;
            } else {
                momentum = 0;
            }
            // Apply scrolling with proper bounds checking
            let newY = listView.contentY - delta;
            newY = Math.max(0, Math.min(listView.contentHeight - listView.height, newY));
            // Cancel any conflicting flicks and apply new position
            if (listView.flicking)
                listView.cancelFlick();

            listView.contentY = newY;
            event.accepted = true;
        }
        onActiveChanged: {
            if (!active && Math.abs(momentumVelocity) >= minMomentumVelocity) {
                startMomentum();
            } else if (!active) {
                velocitySamples = [];
                momentumVelocity = 0;
            }
        }
    }

    // Physics-based momentum timer for kinetic scrolling
    Timer {
        id: momentumTimer

        interval: 16 // ~60 FPS
        repeat: true
        onTriggered: {
            // Apply velocity to position
            let newY = contentY - momentumVelocity * 0.016;
            let maxY = Math.max(0, contentHeight - height);
            
            // Stop momentum at boundaries instead of bouncing
            if (newY < 0) {
                contentY = 0;
                stop();
                isMomentumActive = false;
                momentumVelocity = 0;
                return;
            } else if (newY > maxY) {
                contentY = maxY;
                stop();
                isMomentumActive = false;
                momentumVelocity = 0;
                return;
            }
            
            contentY = newY;
            
            // Apply friction
            momentumVelocity *= friction;
            
            // Stop if velocity too low
            if (Math.abs(momentumVelocity) < 5) {
                stop();
                isMomentumActive = false;
                momentumVelocity = 0;
            }
        }
    }

    // Smooth return to bounds animation
    NumberAnimation {
        id: returnToBoundsAnimation

        target: listView
        property: "contentY"
        duration: 300
        easing.type: Easing.OutQuad
    }
}