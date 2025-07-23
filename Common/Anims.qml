pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property int durShort: 160
    readonly property int durMed: 220
    readonly property int durLong: 320

    readonly property int slidePx: 100

    readonly property QtObject direction: QtObject {
        readonly property int fromLeft: 0
        readonly property int fromRight: 1
        readonly property int fadeOnly: 2
    }

    readonly property Component slideInLeft: Transition {
        NumberAnimation { properties: "x"; from: -Anims.slidePx; to: 0; duration: Anims.durMed; easing.type: Easing.OutCubic }
        NumberAnimation { properties: "opacity"; from: 0.0; to: 1.0; duration: Anims.durShort }
    }

    readonly property Component slideOutLeft: Transition {
        NumberAnimation { properties: "x"; to: -Anims.slidePx; duration: Anims.durShort; easing.type: Easing.InCubic }
        NumberAnimation { properties: "opacity"; to: 0.0; duration: Anims.durShort }
    }

    readonly property Component slideInRight: Transition {
        NumberAnimation { properties: "x"; from: Anims.slidePx; to: 0; duration: Anims.durMed; easing.type: Easing.OutCubic }
        NumberAnimation { properties: "opacity"; from: 0.0; to: 1.0; duration: Anims.durShort }
    }

    readonly property Component slideOutRight: Transition {
        NumberAnimation { properties: "x"; to: Anims.slidePx; duration: Anims.durShort; easing.type: Easing.InCubic }
        NumberAnimation { properties: "opacity"; to: 0.0; duration: Anims.durShort }
    }

    readonly property Component fadeIn: Transition {
        NumberAnimation { properties: "opacity"; from: 0.0; to: 1.0; duration: Anims.durShort; easing.type: Easing.OutCubic }
    }

    readonly property Component fadeOut: Transition {
        NumberAnimation { properties: "opacity"; to: 0.0; duration: Anims.durShort; easing.type: Easing.InCubic }
    }
}
