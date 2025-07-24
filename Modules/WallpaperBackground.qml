import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Widgets

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: wallpaperWindow

        property var modelData

        screen: modelData

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors.top: true
        anchors.bottom: true  
        anchors.left: true
        anchors.right: true

        visible: true
        color: "transparent"

        Image {
            id: wallpaperImage

            anchors.fill: parent
            source: Prefs.wallpaperPath ? "file://" + Prefs.wallpaperPath : ""
            fillMode: Image.PreserveAspectCrop
            visible: Prefs.wallpaperPath !== ""
            smooth: true
            cache: true

            // Smooth transition when wallpaper changes
            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }

            onStatusChanged: {
                if (status === Image.Error) {
                    console.warn("Failed to load wallpaper:", source);
                }
            }
        }

        // Fallback background color when no wallpaper is set
        StyledRect {
            anchors.fill: parent
            color: Theme.surface
            visible: !wallpaperImage.visible
        }
    }
}