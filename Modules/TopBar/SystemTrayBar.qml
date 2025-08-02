import QtQuick
import Quickshell.Services.SystemTray
import qs.Common

Rectangle {
    id: root

    readonly property int calculatedWidth: SystemTray.items.values.length > 0 ? SystemTray.items.values.length * 24 + (SystemTray.items.values.length - 1) * Theme.spacingXS + Theme.spacingS * 2 : 0

    signal menuRequested(var menu, var item, real x, real y)

    width: calculatedWidth
    height: 30
    radius: Theme.cornerRadius
    color: {
        if (SystemTray.items.values.length === 0)
            return "transparent";

        const baseColor = Theme.secondaryHover;
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, baseColor.a * Theme.widgetTransparency);
    }
    visible: SystemTray.items.values.length > 0

    Row {
        id: systemTrayRow

        anchors.centerIn: parent
        spacing: Theme.spacingXS

        Repeater {
            model: SystemTray.items.values

            delegate: Item {
                property var trayItem: modelData
                property string iconSource: {
                    let icon = trayItem && trayItem.icon;
                    if (typeof icon === 'string' || icon instanceof String) {
                        if (icon.includes("?path=")) {
                            const [name, path] = icon.split("?path=");
                            const fileName = name.substring(name.lastIndexOf("/") + 1);
                            return `file://${path}/${fileName}`;
                        }
                        return icon;
                    }
                    return "";
                }

                width: 24
                height: 24

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.cornerRadiusSmall
                    color: trayItemArea.containsMouse ? Theme.primaryHover : "transparent"

                    Behavior on color {
                        enabled: trayItemArea.containsMouse !== undefined

                        ColorAnimation {
                            duration: Theme.shortDuration
                            easing.type: Theme.standardEasing
                        }

                    }

                }

                Image {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: parent.iconSource
                    asynchronous: true
                    smooth: true
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: trayItemArea

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        if (!trayItem)
                            return ;

                        if (mouse.button === Qt.LeftButton) {
                            if (!trayItem.onlyMenu)
                                trayItem.activate();

                        } else if (mouse.button === Qt.RightButton) {
                            if (trayItem && trayItem.hasMenu)
                                root.menuRequested(null, trayItem, mouse.x, mouse.y);

                        }
                    }
                }

            }

        }

    }

}
