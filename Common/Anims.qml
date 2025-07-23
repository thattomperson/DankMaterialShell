pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property int durShort: 200
    readonly property int durMed: 400
    readonly property int durLong: 600

    readonly property int slidePx: 80
    
    // Material Design 3 motion curves
    readonly property var emphasized: [0.05, 0, 2/15, 0.06, 1/6, 0.4, 5/24, 0.82, 0.25, 1, 1, 1]
    readonly property var emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var standard: [0.2, 0, 0, 1, 1, 1]

    readonly property QtObject direction: QtObject {
        readonly property int fromLeft: 0
        readonly property int fromRight: 1
        readonly property int fadeOnly: 2
    }

    readonly property Component slideInLeft: Transition {
        NumberAnimation { properties: "x"; from: -Anims.slidePx; to: 0; duration: Anims.durMed; easing.type: Easing.OutQuart }
    }

    readonly property Component slideOutLeft: Transition {
        NumberAnimation { properties: "x"; to: -Anims.slidePx; duration: Anims.durShort; easing.type: Easing.InQuart }
    }

    readonly property Component slideInRight: Transition {
        NumberAnimation { properties: "x"; from: Anims.slidePx; to: 0; duration: Anims.durMed; easing.type: Easing.OutQuart }
    }

    readonly property Component slideOutRight: Transition {
        NumberAnimation { properties: "x"; to: Anims.slidePx; duration: Anims.durShort; easing.type: Easing.InQuart }
    }

    readonly property Component fadeIn: Transition {
        NumberAnimation { properties: "opacity"; from: 0.0; to: 1.0; duration: Anims.durMed; easing.type: Easing.OutQuart }
    }

    readonly property Component fadeOut: Transition {
        NumberAnimation { properties: "opacity"; to: 0.0; duration: Anims.durShort; easing.type: Easing.InQuart }
    }
}
