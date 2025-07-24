pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Modals

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock

    property bool thisLocked: false
    readonly property bool locked: thisLocked && !lock.unlocked

    function unlock(): void {
        console.log("LockSurface.unlock() called")
        lock.unlocked = true
        animDelay.start()
    }

    Component.onCompleted: {
        thisLocked = true
    }

    color: "transparent"

    Timer {
        id: animDelay
        interval: 1500 // Longer delay for success feedback
        onTriggered: root.lock.locked = false
    }

    PowerConfirmModal {
        id: powerModal
    }

    Loader {
        anchors.fill: parent
        sourceComponent: LockScreenContent {
            demoMode: false
            powerModal: powerModal
            onUnlockRequested: root.unlock()
        }
    }
}