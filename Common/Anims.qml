pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    // Durations match M3 token tiers: short4/medium4/long4
    readonly property int durShort: 200
    readonly property int durMed:   450
    readonly property int durLong:  600

    readonly property int slidePx: 80

    // Material Design 3 motion curves (for QML BezierSpline)
    // Use groups of: [cx1, cy1, cx2, cy2, endX, endY, ...]
    // Single-segment cubics end with 1,1.

    // Emphasized (multi-segment) – for on-screen-to-on-screen moves
    readonly property var emphasized: [
        0.05, 0.00,  0.133333, 0.06,  0.166667, 0.40,
        0.208333, 0.82,  0.25, 1.00,  1.00, 1.00
    ]

    // Emphasized decelerate – entering
    readonly property var emphasizedDecel: [ 0.05, 0.70,  0.10, 1.00,  1.00, 1.00 ]

    // Emphasized accelerate – exiting
    readonly property var emphasizedAccel: [ 0.30, 0.00,  0.80, 0.15,  1.00, 1.00 ]

    // Standard set – for small/subtle transitions
    readonly property var standard:       [ 0.20, 0.00,  0.00, 1.00,  1.00, 1.00 ]
    readonly property var standardDecel:  [ 0.00, 0.00,  0.00, 1.00,  1.00, 1.00 ]
    readonly property var standardAccel:  [ 0.30, 0.00,  1.00, 1.00,  1.00, 1.00 ]

    // readonly property QtObject direction: QtObject {
    //     readonly property int fromLeft: 0
    //     readonly property int fromRight: 1
    //     readonly property int fadeOnly: 2
    // }

    // // Slide transitions (surface/large moves)
    // // Enter = emphasizedDecel, Exit = emphasizedAccel
    // readonly property Component slideInLeft: Transition {
    //     NumberAnimation {
    //         properties: "x"; from: -root.slidePx; to: 0; duration: root.durMed
    //         easing.type: Easing.BezierSpline; easing.bezierCurve: root.emphasizedDecel
    //     }
    // }
    // readonly property Component slideOutLeft: Transition {
    //     NumberAnimation {
    //         properties: "x"; to: -root.slidePx; duration: root.durShort
    //         easing.type: Easing.BezierSpline; easing.bezierCurve: root.emphasizedAccel
    //     }
    // }
    // readonly property Component slideInRight: Transition {
    //     NumberAnimation {
    //         properties: "x"; from: root.slidePx; to: 0; duration: root.durMed
    //         easing.type: Easing.BezierSpline; easing.bezierCurve: root.emphasizedDecel
    //     }
    // }
    // readonly property Component slideOutRight: Transition {
    //     NumberAnimation {
    //         properties: "x"; to: root.slidePx; duration: root.durShort
    //         easing.type: Easing.BezierSpline; easing.bezierCurve: root.emphasizedAccel
    //     }
    // }

    // // Fade transitions (small/subtle moves)
    // // Enter = standardDecel, Exit = standardAccel
    // readonly property Component fadeIn: Transition {
    //     NumberAnimation {
    //         properties: "opacity"; from: 0.0; to: 1.0; duration: root.durMed
    //         easing.type: Easing.BezierSpline; easing.bezierCurve: root.standardDecel
    //     }
    // }
    // readonly property Component fadeOut: Transition {
    //     NumberAnimation {
    //         properties: "opacity"; to: 0.0; duration: root.durShort
    //         easing.type: Easing.BezierSpline; easing.bezierCurve: root.standardAccel
    //     }
    // }
}