import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Modules
import qs.Services
import qs.Widgets

PanelWindow {
    id: root

    property var modelData
    property string screenName: modelData.name
    property real backgroundTransparency: Prefs.topBarTransparency
    readonly property int notificationCount: NotificationService.notifications.length

    screen: modelData
    implicitHeight: Theme.barHeight - 4
    color: "transparent"
    Component.onCompleted: {
        let fonts = Qt.fontFamilies();
        if (fonts.indexOf("Material Symbols Rounded") === -1)
            ToastService.showError("Please install Material Symbols Rounded and Restart your Shell. See README.md for instructions");

    }

    Connections {
        function onTopBarTransparencyChanged() {
            root.backgroundTransparency = Prefs.topBarTransparency;
        }

        target: Prefs
    }

    QtObject {
        id: notificationHistory

        property int count: 0
    }

    anchors {
        top: true
        left: true
        right: true
    }

    Item {
        anchors.fill: parent
        anchors.margins: 2
        anchors.topMargin: 6
        anchors.bottomMargin: 0
        anchors.leftMargin: 8
        anchors.rightMargin: 8

        Rectangle {
            anchors.fill: parent
            radius: Theme.cornerRadiusXLarge
            color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, root.backgroundTransparency)
            layer.enabled: true

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: Theme.outlineMedium
                border.width: 1
                radius: parent.radius
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(Theme.surfaceTint.r, Theme.surfaceTint.g, Theme.surfaceTint.b, 0.04)
                radius: parent.radius

                SequentialAnimation on opacity {
                    running: false
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: 0.08
                        duration: Theme.extraLongDuration
                        easing.type: Theme.standardEasing
                    }

                    NumberAnimation {
                        to: 0.02
                        duration: Theme.extraLongDuration
                        easing.type: Theme.standardEasing
                    }

                }

            }

            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 4
                shadowBlur: 0.5 // radius/32, adjusted for visual match
                shadowColor: Qt.rgba(0, 0, 0, 0.15)
                shadowOpacity: 0.15
            }

        }

        Item {
            id: topBarContent

            readonly property int availableWidth: width
            // Use estimated fixed widths to break circular dependencies
            readonly property int launcherButtonWidth: 40
            readonly property int workspaceSwitcherWidth: 120 // Approximate
            readonly property int focusedAppMaxWidth: focusedApp.visible ? 456 : 0
            readonly property int estimatedLeftSectionWidth: launcherButtonWidth + workspaceSwitcherWidth + focusedAppMaxWidth + (Theme.spacingXS * 2)
            readonly property int rightSectionWidth: rightSection.width
            readonly property int clockWidth: clock.width
            readonly property int mediaMaxWidth: media.visible ? 280 : 0 // Normal max width
            readonly property int weatherWidth: weather.visible ? weather.width : 0
            readonly property bool validLayout: availableWidth > 100 && estimatedLeftSectionWidth > 0 && rightSectionWidth > 0
            readonly property int clockLeftEdge: (availableWidth - clockWidth) / 2
            readonly property int clockRightEdge: clockLeftEdge + clockWidth
            readonly property int leftSectionRightEdge: estimatedLeftSectionWidth
            readonly property int mediaLeftEdge: clockLeftEdge - mediaMaxWidth - Theme.spacingS
            readonly property int rightSectionLeftEdge: availableWidth - rightSectionWidth
            readonly property int leftToClockGap: Math.max(0, clockLeftEdge - leftSectionRightEdge)
            readonly property int leftToMediaGap: mediaMaxWidth > 0 ? Math.max(0, mediaLeftEdge - leftSectionRightEdge) : leftToClockGap
            readonly property int mediaToClockGap: mediaMaxWidth > 0 ? Theme.spacingS : 0
            readonly property int clockToRightGap: validLayout ? Math.max(0, rightSectionLeftEdge - clockRightEdge) : 1000
            readonly property bool spacingTight: validLayout && (leftToMediaGap < 150 || clockToRightGap < 100)
            readonly property bool overlapping: validLayout && (leftToMediaGap < 100 || clockToRightGap < 50)

            anchors.fill: parent
            anchors.leftMargin: Theme.spacingM
            anchors.rightMargin: Theme.spacingM
            anchors.topMargin: Theme.spacingXS
            anchors.bottomMargin: Theme.spacingXS
            clip: true

            Row {
                id: leftSection

                height: parent.height
                spacing: Theme.spacingXS
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                LauncherButton {
                    anchors.verticalCenter: parent.verticalCenter
                    isActive: appDrawerPopout ? appDrawerPopout.isVisible : false
                    onClicked: {
                        if (appDrawerPopout)
                            appDrawerPopout.toggle();

                    }
                }

                WorkspaceSwitcher {
                    anchors.verticalCenter: parent.verticalCenter
                    screenName: root.screenName
                }

                FocusedApp {
                    id: focusedApp

                    anchors.verticalCenter: parent.verticalCenter
                    visible: Prefs.showFocusedWindow
                    compactMode: topBarContent.spacingTight
                    availableWidth: topBarContent.leftToMediaGap
                }

            }

            Clock {
                id: clock

                anchors.centerIn: parent
                compactMode: topBarContent.overlapping
                onClockClicked: {
                    centcomPopout.calendarVisible = !centcomPopout.calendarVisible;
                }
            }

            Media {
                id: media

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: clock.left
                anchors.rightMargin: Theme.spacingS
                visible: Prefs.showMusic && MprisController.activePlayer
                compactMode: topBarContent.spacingTight || topBarContent.overlapping
                onClicked: {
                    centcomPopout.calendarVisible = !centcomPopout.calendarVisible;
                }
            }

            Weather {
                id: weather

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: clock.right
                anchors.leftMargin: Theme.spacingS
                visible: Prefs.showWeather && WeatherService.weather.available && WeatherService.weather.temp > 0 && WeatherService.weather.tempF > 0
                onClicked: {
                    centcomPopout.calendarVisible = !centcomPopout.calendarVisible;
                }
            }

            Row {
                id: rightSection

                height: parent.height
                spacing: Theme.spacingXS
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                SystemTrayBar {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Prefs.showSystemTray
                    onMenuRequested: (menu, item, x, y) => {
                        systemTrayContextMenu.currentTrayMenu = menu;
                        systemTrayContextMenu.currentTrayItem = item;
                        systemTrayContextMenu.contextMenuX = rightSection.x + rightSection.width - 400 - Theme.spacingL;
                        systemTrayContextMenu.contextMenuY = Theme.barHeight - Theme.spacingXS;
                        systemTrayContextMenu.showContextMenu = true;
                        menu.menuVisible = true;
                    }
                }

                Rectangle {
                    width: 40
                    height: 30
                    radius: Theme.cornerRadius
                    color: {
                        const baseColor = clipboardArea.containsMouse ? Theme.primaryHover : Theme.secondaryHover;
                        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, baseColor.a * Theme.widgetTransparency);
                    }
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Prefs.showClipboard

                    DankIcon {
                        anchors.centerIn: parent
                        name: "content_paste"
                        size: Theme.iconSize - 6
                        color: Theme.surfaceText
                    }

                    MouseArea {
                        id: clipboardArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            clipboardHistoryModalPopup.toggle();
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.shortDuration
                            easing.type: Theme.standardEasing
                        }

                    }

                }

                Loader {
                    anchors.verticalCenter: parent.verticalCenter
                    active: Prefs.showSystemResources

                    sourceComponent: Component {
                        CpuMonitor {
                            toggleProcessList: () => {
                                return processListPopout.toggle();
                            }
                        }

                    }

                }

                Loader {
                    anchors.verticalCenter: parent.verticalCenter
                    active: Prefs.showSystemResources

                    sourceComponent: Component {
                        RamMonitor {
                            toggleProcessList: () => {
                                return processListPopout.toggle();
                            }
                        }

                    }

                }

                NotificationCenterButton {
                    anchors.verticalCenter: parent.verticalCenter
                    hasUnread: root.notificationCount > 0
                    isActive: notificationCenter.notificationHistoryVisible
                    onClicked: {
                        notificationCenter.notificationHistoryVisible = !notificationCenter.notificationHistoryVisible;
                    }
                }

                Battery {
                    anchors.verticalCenter: parent.verticalCenter
                    batteryPopupVisible: batteryPopout.batteryPopupVisible
                    onToggleBatteryPopup: {
                        batteryPopout.batteryPopupVisible = !batteryPopout.batteryPopupVisible;
                    }
                }

                ControlCenterButton {
                    anchors.verticalCenter: parent.verticalCenter
                    isActive: controlCenterPopout.controlCenterVisible
                    onClicked: {
                        controlCenterPopout.controlCenterVisible = !controlCenterPopout.controlCenterVisible;
                        if (controlCenterPopout.controlCenterVisible) {
                            if (NetworkService.wifiEnabled)
                                NetworkService.scanWifi();

                        }
                    }
                }

            }

        }

    }

}
