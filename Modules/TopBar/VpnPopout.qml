import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Widgets
import qs.Common
import qs.Services
import qs.Modules.ControlCenter.Details 1.0 as Details

DankPopout {
    id: root

    property string triggerSection: "right"
    property var triggerScreen: null

    function setTriggerPosition(x, y, width, section, screen) {
        triggerX = x
        triggerY = y
        triggerWidth = width
        triggerSection = section
        triggerScreen = screen
    }

    popupWidth: 360
    popupHeight: contentLoader.item ? contentLoader.item.implicitHeight : 260
    triggerX: Screen.width - 400 - Theme.spacingL
    triggerY: Theme.barHeight - 4 + SettingsData.topBarSpacing + Theme.spacingS
    triggerWidth: 70
    positioning: "center"
    WlrLayershell.namespace: "quickshell-vpn"
    screen: triggerScreen
    shouldBeVisible: false
    visible: shouldBeVisible

    content: Component {
        Rectangle {
            id: content
            implicitHeight: contentColumn.height + Theme.spacingL * 2
            color: Theme.popupBackground()
            radius: Theme.cornerRadius
            border.color: Theme.outlineMedium
            border.width: 1
            antialiasing: true
            smooth: true
            focus: true

            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                }
            }

            Column {
                id: contentColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                Item {
                    width: parent.width
                    height: 28
                    StyledText {
                        text: "VPN Connections"
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Details.VpnDetail {
                    width: parent.width
                }
            }
        }
    }
}
