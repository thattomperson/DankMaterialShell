import QtQuick
import qs.Common
import qs.Widgets

MouseArea {
    id: root

    property bool disabled: false
    property color stateColor: Theme.surfaceText
    property real cornerRadius: parent?.radius ?? Appearance.rounding.normal

    anchors.fill: parent
    cursorShape: disabled ? undefined : Qt.PointingHandCursor
    hoverEnabled: true

    onPressed: event => {
        if (disabled) return;

        rippleAnimation.x = event.x;
        rippleAnimation.y = event.y;

        const dist = (ox, oy) => ox * ox + oy * oy;
        rippleAnimation.radius = Math.sqrt(Math.max(
            dist(event.x, event.y),
            dist(event.x, height - event.y),
            dist(width - event.x, event.y),
            dist(width - event.x, height - event.y)
        ));

        rippleAnimation.restart();
    }

    Rectangle {
        id: hoverLayer
        anchors.fill: parent
        radius: root.cornerRadius
        color: Qt.rgba(root.stateColor.r, root.stateColor.g, root.stateColor.b,
                      root.disabled ? 0 : 
                      root.pressed ? 0.12 : 
                      root.containsMouse ? 0.08 : 0)

        Rectangle {
            id: ripple
            radius: width / 2
            color: root.stateColor
            opacity: 0

            transform: Translate {
                x: -ripple.width / 2
                y: -ripple.height / 2
            }
        }

        // Clip ripple to container bounds
        clip: true
    }

    SequentialAnimation {
        id: rippleAnimation

        property real x
        property real y
        property real radius

        PropertyAction {
            target: ripple
            property: "x"
            value: rippleAnimation.x
        }
        PropertyAction {
            target: ripple
            property: "y"
            value: rippleAnimation.y
        }
        PropertyAction {
            target: ripple
            property: "opacity"
            value: 0.12
        }
        NumberAnimation {
            target: ripple
            properties: "width,height"
            from: 0
            to: rippleAnimation.radius * 2
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standardDecel
        }
        NumberAnimation {
            target: ripple
            property: "opacity"
            to: 0
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }
}