import QtQuick
import qs.Common
import qs.Services

Text {
    id: root

    property bool isMonospace: false

    color: Theme.surfaceText
    font.pixelSize: Appearance.fontSize.normal
    font.family: {
        var requestedFont = isMonospace ? Prefs.monoFontFamily : Prefs.fontFamily;
        var defaultFont = isMonospace ? Prefs.defaultMonoFontFamily : Prefs.defaultFontFamily;
        // If user hasn't overridden the font and we're using the default
        if (requestedFont === defaultFont) {
            var availableFonts = Qt.fontFamilies();
            if (!availableFonts.includes(requestedFont))
                // Use system default
                return isMonospace ? "Monospace" : "DejaVu Sans";

        }
        // Either user overrode it, or default font is available
        return requestedFont;
    }
    font.weight: Prefs.fontWeight
    wrapMode: Text.WordWrap
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
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
