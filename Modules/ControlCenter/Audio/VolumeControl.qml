import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Column {
    id: root
    
    property real volumeLevel: Math.min(100, (AudioService.sink && AudioService.sink.audio && AudioService.sink.audio.volume * 100) || 0)
    property bool volumeMuted: (AudioService.sink && AudioService.sink.audio && AudioService.sink.audio.muted) || false
    
    width: parent.width
    spacing: Theme.spacingM

    Text {
        text: "Volume"
        font.pixelSize: Theme.fontSizeLarge
        color: Theme.surfaceText
        font.weight: Font.Medium
    }

    DankSlider {
        id: volumeSlider
        
        width: parent.width
        value: Math.round(root.volumeLevel)
        minimum: 0
        maximum: 100
        leftIcon: root.volumeMuted ? "volume_off" : "volume_down"
        rightIcon: "volume_up"
        enabled: !root.volumeMuted
        showValue: true
        unit: "%"
        
        onSliderValueChanged: (newValue) => {
            if (AudioService.sink && AudioService.sink.audio) {
                AudioService.sink.audio.muted = false;
                AudioService.sink.audio.volume = newValue / 100;
            }
        }
        
        // Add click handler for mute icon
        Component.onCompleted: {
            // Find the left icon and add mouse area
            let leftIconItem = volumeSlider.children[0].children[0];
            if (leftIconItem) {
                let mouseArea = Qt.createQmlObject(
                    'import QtQuick 2.15; MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (AudioService.sink && AudioService.sink.audio) AudioService.sink.audio.muted = !AudioService.sink.audio.muted; } }',
                    leftIconItem,
                    "dynamicMouseArea"
                );
            }
        }
    }
}