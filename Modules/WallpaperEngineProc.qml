import QtCore
import QtQuick
import Quickshell.Io
import Quickshell

Item {
    id: root
    property string monitor: ""
    property string sceneId: ""
    property string pendingSceneId: ""

    Process {
        id: weProcess
        running: false
        command: []
    }

    Process {
        id: killer
        running: false
        command: []
        onExited: (code) => {
            if (pendingSceneId !== "") {
                weProcess.command = [
                    "linux-wallpaperengine",
                    "--screen-root", monitor,
                    "--bg", pendingSceneId,
                    "--silent"
                ]
                weProcess.running = true
                sceneId = pendingSceneId
                pendingSceneId = ""
            }
        }
    }

    function start(newSceneId) {
        if (sceneId === newSceneId && weProcess.running) {
            return
        }
        pendingSceneId = newSceneId
        stop()
    }

    function stop() {
        if (weProcess.running) {
            weProcess.running = false
        }
        killer.command = [
            "pkill", "-f",
            "linux-wallpaperengine --screen-root " + monitor
        ]
        killer.running = true
    }
}
