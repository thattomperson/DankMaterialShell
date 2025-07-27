pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common

Item {
    id: root
    
    function activate() {
        loader.activeAsync = true
    }

    LazyLoader {
        id: loader

        WlSessionLock {
            id: lock

            property bool unlocked: false
            property string sharedPasswordBuffer: ""

            locked: true

            onLockedChanged: {
                if (!locked)
                    loader.active = false
            }

            LockSurface {
                lock: lock
                sharedPasswordBuffer: lock.sharedPasswordBuffer
                onPasswordChanged: (newPassword) => {
                    lock.sharedPasswordBuffer = newPassword
                }
            }
        }
    }

    LockScreenDemo {
        id: demoWindow
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            console.log("Lock screen requested via IPC")
            loader.activeAsync = true
        }

        function demo(): void {
            console.log("Lock screen DEMO mode requested via IPC")
            demoWindow.showDemo()
        }

        function isLocked(): bool {
            return loader.active
        }
    }
}