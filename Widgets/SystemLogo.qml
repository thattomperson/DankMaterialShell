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

    MultiEffect {
        source: iconImage
        anchors.fill: iconImage
        colorization: 1.0
        colorizationColor: root.color
        brightness: 0.5
        saturation: 0.0
        visible: iconImage.status === Image.Ready
    }
}