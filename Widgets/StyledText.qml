import QtQuick
import qs.Common

Text {
    id: root

    color: Theme.surfaceText
    font.pixelSize: Appearance.fontSize.normal
    wrapMode: Text.WordWrap
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    // Font rendering improvements for crisp text
    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    antialiasing: true

    Behavior on color {
        ColorAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }

    }

    Behavior on opacity {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }

    }

}
