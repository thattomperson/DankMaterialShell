import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modules.Settings
import qs.Widgets
pragma ComponentBehavior

DankModal {
    id: settingsModal

    property Component settingsContent

    signal closingModal()

    function show() {
        open();
    }

    function hide() {
        close();
    }

    function toggle() {
        if (shouldBeVisible)
            hide();
        else
            show();
    }

    objectName: "settingsModal"
    width: 750
    height: 750
    visible: false
    onBackgroundClicked: hide()
    content: settingsContent

    IpcHandler {
        function open() {
            settingsModal.show();
            return "SETTINGS_OPEN_SUCCESS";
        }

        function close() {
            settingsModal.hide();
            return "SETTINGS_CLOSE_SUCCESS";
        }

        function toggle() {
            settingsModal.toggle();
            return "SETTINGS_TOGGLE_SUCCESS";
        }

        target: "settings"
    }

    settingsContent: Component {
        Item {
            anchors.fill: parent
            focus: true

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingS

                // Header row with title and close button
                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    DankIcon {
                        name: "settings"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "Settings"
                        font.pixelSize: Theme.fontSizeXLarge
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        width: parent.width - 175
                        height: 1
                    }

                    DankActionButton {
                        circular: false
                        iconName: "close"
                        iconSize: Theme.iconSize - 4
                        iconColor: Theme.surfaceText
                        hoverColor: Theme.errorHover
                        onClicked: settingsModal.hide()
                    }

                }

                // Main content with side navigation
                Row {
                    width: parent.width
                    height: parent.height - 65
                    spacing: 0

                    // Left sidebar navigation
                    Rectangle {
                        id: sidebarContainer

                        property int currentIndex: 0

                        width: 220
                        height: parent.height
                        color: Theme.surfaceContainer
                        radius: Theme.cornerRadius

                        Column {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingS
                            anchors.rightMargin: Theme.spacingS
                            anchors.bottomMargin: Theme.spacingS
                            anchors.topMargin: Theme.spacingM + 2
                            spacing: Theme.spacingXS

                            Repeater {
                                id: sidebarRepeater

                                model: [{
                                    "text": "Personalization",
                                    "icon": "person"
                                }, {
                                    "text": "Time & Date",
                                    "icon": "schedule"
                                }, {
                                    "text": "Weather",
                                    "icon": "cloud"
                                }, {
                                    "text": "Top Bar",
                                    "icon": "toolbar"
                                }, {
                                    "text": "Widgets",
                                    "icon": "widgets"
                                }, {
                                    "text": "Dock",
                                    "icon": "dock_to_bottom"
                                }, {
                                    "text": "Recent Apps",
                                    "icon": "history"
                                }, {
                                    "text": "Theme & Colors",
                                    "icon": "palette"
                                }, {
                                    "text": "About",
                                    "icon": "info"
                                }]

                                Rectangle {
                                    property bool isActive: sidebarContainer.currentIndex === index

                                    width: parent.width - Theme.spacingS * 2
                                    height: 44
                                    radius: Theme.cornerRadius
                                    color: isActive ? Theme.surfaceContainerHigh : tabMouseArea.containsMouse ? Theme.surfaceHover : "transparent"

                                    Row {
                                        anchors.left: parent.left
                                        anchors.leftMargin: Theme.spacingM
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: Theme.spacingM

                                        DankIcon {
                                            name: modelData.icon || ""
                                            size: Theme.iconSize - 2
                                            color: parent.parent.isActive ? Theme.primary : Theme.surfaceText
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        StyledText {
                                            text: modelData.text || ""
                                            font.pixelSize: Theme.fontSizeMedium
                                            color: parent.parent.isActive ? Theme.primary : Theme.surfaceText
                                            font.weight: parent.parent.isActive ? Font.Medium : Font.Normal
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                    }

                                    MouseArea {
                                        id: tabMouseArea

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            sidebarContainer.currentIndex = index;
                                        }
                                    }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Theme.shortDuration
                                            easing.type: Theme.standardEasing
                                        }

                                    }

                                }

                            }

                        }

                    }

                    // Main content area
                    Item {
                        width: parent.width - sidebarContainer.width
                        height: parent.height

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            anchors.bottomMargin: Theme.spacingM
                            anchors.topMargin: 0
                            color: "transparent"

                            Loader {
                                id: personalizationLoader

                                anchors.fill: parent
                                active: sidebarContainer.currentIndex === 0
                                visible: active
                                asynchronous: true

                                sourceComponent: Component {
                                    PersonalizationTab {
                                        parentModal: settingsModal
                                    }

                                }

                            }

                            Loader {
                                id: timeLoader

                                anchors.fill: parent
                                active: sidebarContainer.currentIndex === 1
                                visible: active
                                asynchronous: true

                                sourceComponent: TimeTab {}
                            }

                            Loader {
                                id: weatherLoader

                                anchors.fill: parent
                                active: sidebarContainer.currentIndex === 2
                                visible: active
                                asynchronous: true

                                sourceComponent: WeatherTab {}
                            }

                            Loader {
                                id: topBarLoader

                                anchors.fill: parent
                                active: sidebarContainer.currentIndex === 3
                                visible: active
                                asynchronous: true

                                sourceComponent: TopBarTab {}
                            }

                            Loader {
                                id: widgetsLoader

                                anchors.fill: parent
                                active: sidebarContainer.currentIndex === 4
                                visible: active
                                asynchronous: true
                                sourceComponent: WidgetTweaksTab {}
                            }

                            Loader {
                                id: dockLoader

                                anchors.fill: parent
                                active: sidebarContainer.currentIndex === 5
                                visible: active
                                asynchronous: true

                                sourceComponent: Component {
                                    DockTab {
                                    }

                                }

                            }

                            Loader {
                                id: recentAppsLoader

                                anchors.fill: parent
                                active: sidebarContainer.currentIndex === 6
                                visible: active
                                asynchronous: true
                                sourceComponent: RecentAppsTab {}
                            }

                            Loader {
                                id: themeColorsLoader

                                anchors.fill: parent
                                active: sidebarContainer.currentIndex === 7
                                visible: active
                                asynchronous: true
                                sourceComponent: ThemeColorsTab {}
                            }

                            Loader {
                                id: aboutLoader

                                anchors.fill: parent
                                active: sidebarContainer.currentIndex === 8
                                visible: active
                                asynchronous: true
                                sourceComponent: AboutTab {}
                            }

                        }

                    }

                }

                // Footer
                StyledText {
                    id: footerText

                    width: parent.width
                    text: `DankMaterialShell - <a href="https://github.com/AvengeMedia/DankMaterialShell">github</a> - optimized for <a href="https://github.com/YaLTeR/niri">niri</a> - <a href="https://matrix.to/#/#niri:matrix.org">niri matrix</a> - <a href="https://discord.gg/vT8Sfjy7sx">niri discord</a>`
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    linkColor: Theme.primary
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    onLinkActivated: link => Qt.openUrlExternally(link)

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                        acceptedButtons: Qt.NoButton
                        propagateComposedEvents: true
                    }

                }

            }

        }

    }

}
