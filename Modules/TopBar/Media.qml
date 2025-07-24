import QtQuick
import Quickshell.Services.Mpris
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool playerAvailable: activePlayer !== null
    
    // Screen detection for responsive design (same logic as FocusedApp)
    readonly property bool isSmallScreen: {
        // Walk up the parent chain to find the TopBar PanelWindow
        let current = root.parent
        while (current && !current.screen) {
            current = current.parent
        }
        
        if (!current || !current.screen) {
            return true  // Default to small if we can't detect
        }
        
        const s = current.screen
        
        // Multi-method detection for laptop/small screens:
        
        // Method 1: Check screen name for laptop indicators
        const screenName = (s.name || "").toLowerCase()
        if (screenName.includes("edp") || screenName.includes("lvds")) {
            return true
        }
        
        // Method 2: Check pixel density if available
        try {
            if (s.pixelDensity && s.pixelDensity > 1.5) {
                return true
            }
        } catch (e) { /* ignore */ }
        
        // Method 3: Check device pixel ratio if available
        try {
            if (s.devicePixelRatio && s.devicePixelRatio > 1.25) {
                return true
            }
        } catch (e) { /* ignore */ }
        
        // Method 4: Resolution-based fallback for smaller displays
        if (s.width <= 1920 && s.height <= 1200) {
            return true
        }
        
        // Method 5: Check for high-res laptop displays
        if ((s.width === 2400 && s.height === 1600) || 
            (s.width === 2560 && s.height === 1600) ||
            (s.width === 2880 && s.height === 1800)) {
            return true
        }
        
        return false  // Default to large screen
    }
    
    readonly property int contentWidth: Math.min(280, mediaRow.implicitWidth + Theme.spacingS * 2)

    signal clicked()

    height: 30
    radius: Theme.cornerRadius
    color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)
    states: [
        State {
            name: "shown"
            when: playerAvailable

            PropertyChanges {
                target: root
                opacity: 1
                width: contentWidth
            }

        },
        State {
            name: "hidden"
            when: !playerAvailable

            PropertyChanges {
                target: root
                opacity: 0
                width: 0
            }

        }
    ]
    transitions: [
        Transition {
            from: "shown"
            to: "hidden"

            SequentialAnimation {
                PauseAnimation {
                    duration: 500
                }

                NumberAnimation {
                    properties: "opacity,width"
                    duration: Theme.shortDuration
                    easing.type: Theme.standardEasing
                }

            }

        },
        Transition {
            from: "hidden"
            to: "shown"

            NumberAnimation {
                properties: "opacity,width"
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }

        }
    ]

    Row {
        id: mediaRow

        anchors.centerIn: parent
        spacing: Theme.spacingXS

        // Media info section (clickable to open full player)
        Row {
            id: mediaInfo

            spacing: Theme.spacingXS

            AudioVisualization {
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: mediaText

                anchors.verticalCenter: parent.verticalCenter
                width: 140
                visible: !root.isSmallScreen  // Hide title text on small screens
                text: {
                    if (!activePlayer || !activePlayer.trackTitle)
                        return "";

                    let identity = activePlayer.identity || "";
                    let isWebMedia = identity.toLowerCase().includes("firefox") || identity.toLowerCase().includes("chrome") || identity.toLowerCase().includes("chromium") || identity.toLowerCase().includes("edge") || identity.toLowerCase().includes("safari");
                    let title = "";
                    let subtitle = "";
                    if (isWebMedia && activePlayer.trackTitle) {
                        title = activePlayer.trackTitle;
                        subtitle = activePlayer.trackArtist || identity;
                    } else {
                        title = activePlayer.trackTitle || "Unknown Track";
                        subtitle = activePlayer.trackArtist || "";
                    }
                    if (title.length > 20)
                        title = title.substring(0, 20) + "...";

                    if (subtitle.length > 22)
                        subtitle = subtitle.substring(0, 22) + "...";

                    return subtitle.length > 0 ? title + " • " + subtitle : title;
                }
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                font.weight: Font.Medium
                elide: Text.ElideRight

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clicked()
                }

            }

        }

        // Control buttons
        Row {
            spacing: Theme.spacingXS
            anchors.verticalCenter: parent.verticalCenter

            // Previous button
            Rectangle {
                width: 20
                height: 20
                radius: 10
                anchors.verticalCenter: parent.verticalCenter
                color: prevArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                visible: root.playerAvailable
                opacity: (activePlayer && activePlayer.canGoPrevious) ? 1 : 0.3

                DankIcon {
                    anchors.centerIn: parent
                    name: "skip_previous"
                    size: 12
                    color: Theme.surfaceText
                }

                MouseArea {
                    id: prevArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (activePlayer)
                            activePlayer.previous();

                    }
                }

            }

            // Play/Pause button
            Rectangle {
                width: 24
                height: 24
                radius: 12
                anchors.verticalCenter: parent.verticalCenter
                color: activePlayer && activePlayer.playbackState === 1 ? Theme.primary : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                visible: root.playerAvailable
                opacity: activePlayer ? 1 : 0.3

                DankIcon {
                    anchors.centerIn: parent
                    name: activePlayer && activePlayer.playbackState === 1 ? "pause" : "play_arrow"
                    size: 14
                    color: activePlayer && activePlayer.playbackState === 1 ? Theme.background : Theme.primary
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (activePlayer)
                            activePlayer.togglePlaying();

                    }
                }

            }

            // Next button
            Rectangle {
                width: 20
                height: 20
                radius: 10
                anchors.verticalCenter: parent.verticalCenter
                color: nextArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                visible: playerAvailable
                opacity: (activePlayer && activePlayer.canGoNext) ? 1 : 0.3

                DankIcon {
                    anchors.centerIn: parent
                    name: "skip_next"
                    size: 12
                    color: Theme.surfaceText
                }

                MouseArea {
                    id: nextArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (activePlayer)
                            activePlayer.next();

                    }
                }

            }

        }

    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing
        }

    }

    Behavior on width {
        NumberAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing
        }

    }

}
