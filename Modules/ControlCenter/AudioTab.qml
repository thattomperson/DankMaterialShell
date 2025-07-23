import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets
import "../../Widgets"

Item {
    id: audioTab

    property int audioSubTab: 0 // 0: Output, 1: Input
    readonly property real volumeLevel: (AudioService.sink && AudioService.sink.audio && AudioService.sink.audio.volume * 100) || 0
    readonly property real micLevel: (AudioService.source && AudioService.source.audio && AudioService.source.audio.volume * 100) || 0
    readonly property bool volumeMuted: (AudioService.sink && AudioService.sink.audio && AudioService.sink.audio.muted) || false
    readonly property bool micMuted: (AudioService.source && AudioService.source.audio && AudioService.source.audio.muted) || false
    readonly property string currentSinkDisplayName: AudioService.sink ? AudioService.displayName(AudioService.sink) : ""
    readonly property string currentSourceDisplayName: AudioService.source ? AudioService.displayName(AudioService.source) : ""

    Column {
        anchors.fill: parent
        spacing: Theme.spacingM

        // Audio Sub-tabs
        DankTabBar {
            width: parent.width
            tabHeight: 40
            currentIndex: audioTab.audioSubTab
            showIcons: false
            model: [
                {
                    "text": "Output"
                },
                {
                    "text": "Input"
                }
            ]
            onTabClicked: function(index) {
                audioTab.audioSubTab = index;
            }
        }

        // Output Tab Content
        ScrollView {
            width: parent.width
            height: parent.height - 48
            visible: audioTab.audioSubTab === 0
            clip: true

            Column {
                width: parent.width
                spacing: Theme.spacingL

                // Volume Control
                Column {
                    width: parent.width
                    spacing: Theme.spacingM

                    Text {
                        text: "Volume"
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DankIcon {
                            name: audioTab.volumeMuted ? "volume_off" : "volume_down"
                            size: Theme.iconSize
                            color: audioTab.volumeMuted ? Theme.error : Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (AudioService.sink && AudioService.sink.audio)
                                        AudioService.sink.audio.muted = !AudioService.sink.audio.muted;

                                }
                            }

                        }

                        Item {
                            id: volumeSliderContainer

                            width: parent.width - 80
                            height: 32
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                id: volumeSliderTrack

                                width: parent.width
                                height: 8
                                radius: 4
                                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    id: volumeSliderFill

                                    width: parent.width * (audioTab.volumeLevel / 100)
                                    height: parent.height
                                    radius: parent.radius
                                    color: Theme.primary

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 100
                                        }

                                    }

                                }

                                // Draggable handle
                                Rectangle {
                                    id: volumeHandle

                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: Theme.primary
                                    border.color: Qt.lighter(Theme.primary, 1.3)
                                    border.width: 2
                                    x: Math.max(0, Math.min(parent.width - width, volumeSliderFill.width - width / 2))
                                    anchors.verticalCenter: parent.verticalCenter
                                    scale: volumeMouseArea.containsMouse || volumeMouseArea.pressed ? 1.2 : 1

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 150
                                        }

                                    }

                                }

                            }

                            MouseArea {
                                id: volumeMouseArea

                                property bool isDragging: false

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                preventStealing: true
                                onPressed: (mouse) => {
                                    isDragging = true;
                                    let ratio = Math.max(0, Math.min(1, mouse.x / volumeSliderTrack.width));
                                    let newVolume = Math.round(ratio * 100);
                                    if (AudioService.sink && AudioService.sink.audio) {
                                        AudioService.sink.audio.muted = false;
                                        AudioService.sink.audio.volume = newVolume / 100;
                                    }
                                }
                                onReleased: {
                                    isDragging = false;
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed && isDragging) {
                                        let ratio = Math.max(0, Math.min(1, mouse.x / volumeSliderTrack.width));
                                        let newVolume = Math.round(ratio * 100);
                                        if (AudioService.sink && AudioService.sink.audio) {
                                            AudioService.sink.audio.muted = false;
                                            AudioService.sink.audio.volume = newVolume / 100;
                                        }
                                    }
                                }
                                onClicked: (mouse) => {
                                    let ratio = Math.max(0, Math.min(1, mouse.x / volumeSliderTrack.width));
                                    let newVolume = Math.round(ratio * 100);
                                    if (AudioService.sink && AudioService.sink.audio) {
                                        AudioService.sink.audio.muted = false;
                                        AudioService.sink.audio.volume = newVolume / 100;
                                    }
                                }
                            }

                            // Global mouse area for drag tracking
                            MouseArea {
                                id: volumeGlobalMouseArea

                                x: 0
                                y: 0
                                width: audioTab.width
                                height: audioTab.height
                                enabled: volumeMouseArea.isDragging
                                visible: false
                                preventStealing: true
                                onPositionChanged: (mouse) => {
                                    if (volumeMouseArea.isDragging) {
                                        let globalPos = mapToItem(volumeSliderTrack, mouse.x, mouse.y);
                                        let ratio = Math.max(0, Math.min(1, globalPos.x / volumeSliderTrack.width));
                                        let newVolume = Math.round(ratio * 100);
                                        if (AudioService.sink && AudioService.sink.audio) {
                                            AudioService.sink.audio.muted = false;
                                            AudioService.sink.audio.volume = newVolume / 100;
                                        }
                                    }
                                }
                                onReleased: {
                                    volumeMouseArea.isDragging = false;
                                }
                            }

                        }

                        DankIcon {
                            name: "volume_up"
                            size: Theme.iconSize
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                    }

                }

                // Output Devices
                Column {
                    width: parent.width
                    spacing: Theme.spacingM

                    Text {
                        text: "Output Device"
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                    }

                    // Current device indicator
                    Rectangle {
                        width: parent.width
                        height: 35
                        radius: Theme.cornerRadius
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3)
                        border.width: 1
                        visible: AudioService.sink !== null

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "check_circle"
                                size: Theme.iconSize - 4
                                color: Theme.primary
                            }

                            Text {
                                text: "Current: " + (audioTab.currentSinkDisplayName || "None")
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.primary
                                font.weight: Font.Medium
                            }

                        }

                    }

                    // Real audio devices
                    Repeater {
                        model: {
                            if (!Pipewire.ready || !Pipewire.nodes || !Pipewire.nodes.values) return []
                            let sinks = []
                            for (let i = 0; i < Pipewire.nodes.values.length; i++) {
                                let node = Pipewire.nodes.values[i]
                                if (!node || node.isStream) continue
                                if ((node.type & PwNodeType.AudioSink) === PwNodeType.AudioSink) {
                                    sinks.push(node)
                                }
                            }
                            return sinks
                        }

                        Rectangle {
                            width: parent.width
                            height: 50
                            radius: Theme.cornerRadius
                            color: deviceArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : (modelData === AudioService.sink ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08))
                            border.color: modelData === AudioService.sink ? Theme.primary : "transparent"
                            border.width: 1

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacingM

                                DankIcon {
                                    name: {
                                        if (modelData.name.includes("bluez"))
                                            return "headset";
                                        else if (modelData.name.includes("hdmi"))
                                            return "tv";
                                        else if (modelData.name.includes("usb"))
                                            return "headset";
                                        else
                                            return "speaker";
                                    }
                                    size: Theme.iconSize
                                    color: modelData === AudioService.sink ? Theme.primary : Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    spacing: 2
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        text: AudioService.displayName(modelData)
                                        font.pixelSize: Theme.fontSizeMedium
                                        color: modelData === AudioService.sink ? Theme.primary : Theme.surfaceText
                                        font.weight: modelData === AudioService.sink ? Font.Medium : Font.Normal
                                    }

                                    Text {
                                        text: {
                                            if (AudioService.subtitle(modelData.name) && AudioService.subtitle(modelData.name) !== "")
                                                return AudioService.subtitle(modelData.name) + (modelData === AudioService.sink ? " • Selected" : "");
                                            else
                                                return modelData === AudioService.sink ? "Selected" : "";
                                        }
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                                        visible: text !== ""
                                    }

                                }

                            }

                            MouseArea {
                                id: deviceArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData)
                                        Pipewire.preferredDefaultAudioSink = modelData;

                                }
                            }

                        }

                    }

                }

            }

        }

        // Input Tab Content
        ScrollView {
            width: parent.width
            height: parent.height - 48
            visible: audioTab.audioSubTab === 1
            clip: true

            Column {
                width: parent.width
                spacing: Theme.spacingL

                // Microphone Level Control
                Column {
                    width: parent.width
                    spacing: Theme.spacingM

                    Text {
                        text: "Microphone Level"
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DankIcon {
                            name: audioTab.micMuted ? "mic_off" : "mic"
                            size: Theme.iconSize
                            color: audioTab.micMuted ? Theme.error : Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (AudioService.source && AudioService.source.audio)
                                        AudioService.source.audio.muted = !AudioService.source.audio.muted;

                                }
                            }

                        }

                        Item {
                            id: micSliderContainer

                            width: parent.width - 80
                            height: 32
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                id: micSliderTrack

                                width: parent.width
                                height: 8
                                radius: 4
                                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    id: micSliderFill

                                    width: parent.width * (audioTab.micLevel / 100)
                                    height: parent.height
                                    radius: parent.radius
                                    color: Theme.primary

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 100
                                        }

                                    }

                                }

                                // Draggable handle
                                Rectangle {
                                    id: micHandle

                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: Theme.primary
                                    border.color: Qt.lighter(Theme.primary, 1.3)
                                    border.width: 2
                                    x: Math.max(0, Math.min(parent.width - width, micSliderFill.width - width / 2))
                                    anchors.verticalCenter: parent.verticalCenter
                                    scale: micMouseArea.containsMouse || micMouseArea.pressed ? 1.2 : 1

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 150
                                        }

                                    }

                                }

                            }

                            MouseArea {
                                id: micMouseArea

                                property bool isDragging: false

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                preventStealing: true
                                onPressed: (mouse) => {
                                    isDragging = true;
                                    let ratio = Math.max(0, Math.min(1, mouse.x / micSliderTrack.width));
                                    let newMicLevel = Math.round(ratio * 100);
                                    if (AudioService.source && AudioService.source.audio) {
                                        AudioService.source.audio.muted = false;
                                        AudioService.source.audio.volume = newMicLevel / 100;
                                    }
                                }
                                onReleased: {
                                    isDragging = false;
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed && isDragging) {
                                        let ratio = Math.max(0, Math.min(1, mouse.x / micSliderTrack.width));
                                        let newMicLevel = Math.round(ratio * 100);
                                        if (AudioService.source && AudioService.source.audio) {
                                            AudioService.source.audio.muted = false;
                                            AudioService.source.audio.volume = newMicLevel / 100;
                                        }
                                    }
                                }
                                onClicked: (mouse) => {
                                    let ratio = Math.max(0, Math.min(1, mouse.x / micSliderTrack.width));
                                    let newMicLevel = Math.round(ratio * 100);
                                    if (AudioService.source && AudioService.source.audio) {
                                        AudioService.source.audio.muted = false;
                                        AudioService.source.audio.volume = newMicLevel / 100;
                                    }
                                }
                            }

                            // Global mouse area for drag tracking
                            MouseArea {
                                id: micGlobalMouseArea

                                x: 0
                                y: 0
                                width: audioTab.width
                                height: audioTab.height
                                enabled: micMouseArea.isDragging
                                visible: false
                                preventStealing: true
                                onPositionChanged: (mouse) => {
                                    if (micMouseArea.isDragging) {
                                        let globalPos = mapToItem(micSliderTrack, mouse.x, mouse.y);
                                        let ratio = Math.max(0, Math.min(1, globalPos.x / micSliderTrack.width));
                                        let newMicLevel = Math.round(ratio * 100);
                                        if (AudioService.source && AudioService.source.audio) {
                                            AudioService.source.audio.muted = false;
                                            AudioService.source.audio.volume = newMicLevel / 100;
                                        }
                                    }
                                }
                                onReleased: {
                                    micMouseArea.isDragging = false;
                                }
                            }

                        }

                        DankIcon {
                            name: "mic"
                            size: Theme.iconSize
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                    }

                }

                // Input Devices
                Column {
                    width: parent.width
                    spacing: Theme.spacingM

                    Text {
                        text: "Input Device"
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                    }

                    // Current device indicator
                    Rectangle {
                        width: parent.width
                        height: 35
                        radius: Theme.cornerRadius
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3)
                        border.width: 1
                        visible: AudioService.source !== null

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "check_circle"
                                size: Theme.iconSize - 4
                                color: Theme.primary
                            }

                            Text {
                                text: "Current: " + (audioTab.currentSourceDisplayName || "None")
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.primary
                                font.weight: Font.Medium
                            }

                        }

                    }

                    // Real audio input devices
                    Repeater {
                        model: {
                            if (!Pipewire.ready || !Pipewire.nodes || !Pipewire.nodes.values) return []
                            let sources = []
                            for (let i = 0; i < Pipewire.nodes.values.length; i++) {
                                let node = Pipewire.nodes.values[i]
                                if (!node || node.isStream) continue
                                if ((node.type & PwNodeType.AudioSource) === PwNodeType.AudioSource && !node.name.includes(".monitor")) {
                                    sources.push(node)
                                }
                            }
                            return sources
                        }

                        Rectangle {
                            width: parent.width
                            height: 50
                            radius: Theme.cornerRadius
                            color: sourceArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : (modelData === AudioService.source ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08))
                            border.color: modelData === AudioService.source ? Theme.primary : "transparent"
                            border.width: 1

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacingM

                                DankIcon {
                                    name: {
                                        if (modelData.name.includes("bluez"))
                                            return "headset_mic";
                                        else if (modelData.name.includes("usb"))
                                            return "headset_mic";
                                        else
                                            return "mic";
                                    }
                                    size: Theme.iconSize
                                    color: modelData === AudioService.source ? Theme.primary : Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    spacing: 2
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        text: AudioService.displayName(modelData)
                                        font.pixelSize: Theme.fontSizeMedium
                                        color: modelData === AudioService.source ? Theme.primary : Theme.surfaceText
                                        font.weight: modelData === AudioService.source ? Font.Medium : Font.Normal
                                    }

                                    Text {
                                        text: {
                                            if (AudioService.subtitle(modelData.name) && AudioService.subtitle(modelData.name) !== "")
                                                return AudioService.subtitle(modelData.name) + (modelData === AudioService.source ? " • Selected" : "");
                                            else
                                                return modelData === AudioService.source ? "Selected" : "";
                                        }
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                                        visible: text !== ""
                                    }

                                }

                            }

                            MouseArea {
                                id: sourceArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData)
                                        Pipewire.preferredDefaultAudioSource = modelData;

                                }
                            }

                        }

                    }

                }

            }

        }

    }

}
