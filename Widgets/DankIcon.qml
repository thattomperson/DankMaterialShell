import QtQuick
import qs.Common

Text {
    id: icon
    
    property alias name: icon.text
    property alias size: icon.font.pixelSize
    property alias color: icon.color
    property bool filled: false
    readonly property string iconFont : {
        var families = Qt.fontFamilies();
        if (families.indexOf("Material Symbols Rounded") !== -1) {
            return "Material Symbols Rounded";
        } else {
            return "Material Icons Round";
        } 
    }

    font.family: iconFont
    font.pixelSize: Theme.iconSize
    font.weight: filled ? Font.Medium : Font.Normal
    color: Theme.surfaceText
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}