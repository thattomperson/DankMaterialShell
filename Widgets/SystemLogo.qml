import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Common

Item {
    id: root
    
    property color color: Theme.surfaceText

    IconImage {
        id: iconImage
        anchors.fill: parent
        smooth: true
        asynchronous: true
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1
            colorizationColor: root.color
            brightness: 0.5
        }
        Process {
            running: true
            command: ["sh", "-c", ". /etc/os-release && echo $LOGO"]
            stdout: StdioCollector {
                onStreamFinished: () => {
                    iconImage.source = Quickshell.iconPath(this.text.trim());
                }
            }
        }
    }
}