import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    property string screenName: ""
    property int currentWorkspace: getDisplayActiveWorkspace()
    property var workspaceList: {
        var baseList = getDisplayWorkspaces()
        return SettingsData.showWorkspacePadding ? padWorkspaces(
                                                       baseList) : baseList
    }

    function padWorkspaces(list) {
        var padded = list.slice()
        while (padded.length < 3)
            padded.push(-1) // Use -1 as a placeholder
        return padded
    }

    function getDisplayWorkspaces() {
        if (CompositorService.isNiri) {
            if (NiriService.allWorkspaces.length === 0)
                return [1, 2]

            if (!root.screenName)
                return NiriService.getCurrentOutputWorkspaceNumbers()

            var displayWorkspaces = []
            for (var i = 0; i < NiriService.allWorkspaces.length; i++) {
                var ws = NiriService.allWorkspaces[i]
                if (ws.output === root.screenName)
                    displayWorkspaces.push(ws.idx + 1)
            }
            return displayWorkspaces.length > 0 ? displayWorkspaces : [1, 2]
        } else if (CompositorService.isHyprland) {
            var workspaces = HyprlandService.getWorkspaceDisplayNumbers()
            return workspaces.length > 0 ? workspaces : [1]
        }
        
        return [1, 2]
    }

    function getDisplayActiveWorkspace() {
        if (CompositorService.isNiri) {
            if (NiriService.allWorkspaces.length === 0)
                return 1

            if (!root.screenName)
                return NiriService.getCurrentWorkspaceNumber()

            for (var i = 0; i < NiriService.allWorkspaces.length; i++) {
                var ws = NiriService.allWorkspaces[i]
                if (ws.output === root.screenName && ws.is_active)
                    return ws.idx + 1
            }
            return 1
        } else if (CompositorService.isHyprland) {
            var activeWs = HyprlandService.getCurrentWorkspaceNumber()
            return activeWs
        }
        
        return 1
    }

    width: SettingsData.showWorkspacePadding ? Math.max(
                                                   120,
                                                   workspaceRow.implicitWidth + Theme.spacingL
                                                   * 2) : workspaceRow.implicitWidth
                                               + Theme.spacingL * 2
    height: 30
    radius: Theme.cornerRadius
    color: {
        const baseColor = Theme.surfaceTextHover
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b,
                       baseColor.a * Theme.widgetTransparency)
    }
    visible: CompositorService.isNiri || CompositorService.isHyprland

    Connections {
        function onAllWorkspacesChanged() {
            root.workspaceList
                    = SettingsData.showWorkspacePadding ? root.padWorkspaces(
                                                              root.getDisplayWorkspaces(
                                                                  )) : root.getDisplayWorkspaces()
            root.currentWorkspace = root.getDisplayActiveWorkspace()
        }

        function onFocusedWorkspaceIndexChanged() {
            root.currentWorkspace = root.getDisplayActiveWorkspace()
        }

        target: NiriService
        enabled: CompositorService.isNiri
    }

    Connections {
        function onWorkspacesUpdated() {
            root.workspaceList
                    = SettingsData.showWorkspacePadding ? root.padWorkspaces(
                                                              root.getDisplayWorkspaces(
                                                                  )) : root.getDisplayWorkspaces()
            root.currentWorkspace = root.getDisplayActiveWorkspace()
        }

        function onFocusedWorkspaceUpdated() {
            root.currentWorkspace = root.getDisplayActiveWorkspace()
        }

        function onFocusedMonitorUpdated() {
            root.currentWorkspace = root.getDisplayActiveWorkspace()
        }

        target: HyprlandService
        enabled: CompositorService.isHyprland
    }


    Connections {
        function onShowWorkspacePaddingChanged() {
            var baseList = root.getDisplayWorkspaces()
            root.workspaceList = SettingsData.showWorkspacePadding ? root.padWorkspaces(
                                                                         baseList) : baseList
        }

        target: SettingsData
    }

    Row {
        id: workspaceRow

        anchors.centerIn: parent
        spacing: Theme.spacingS

        Repeater {
            model: root.workspaceList

            Rectangle {
                property bool isActive: modelData === root.currentWorkspace
                property bool isPlaceholder: modelData === -1
                property bool isHovered: mouseArea.containsMouse
                property int sequentialNumber: index + 1
                property var workspaceData: {
                    if (isPlaceholder)
                        return null
                    
                    if (CompositorService.isNiri) {
                        for (var i = 0; i < NiriService.allWorkspaces.length; i++) {
                            var ws = NiriService.allWorkspaces[i]
                            if (ws.idx + 1 === modelData)
                                return ws
                        }
                    } else if (CompositorService.isHyprland) {
                        var hyprWorkspaces = HyprlandService.getWorkspacesForMonitor(root.screenName)
                        for (var j = 0; j < hyprWorkspaces.length; j++) {
                            var hws = hyprWorkspaces[j]
                            if (hws.id === modelData)
                                return hws
                        }
                    }
                    return null
                }
                property var iconData: workspaceData
                                       && workspaceData.name ? SettingsData.getWorkspaceNameIcon(
                                                                   workspaceData.name) : null
                property bool hasIcon: iconData !== null

                width: isActive ? Theme.spacingXL + Theme.spacingM : Theme.spacingL
                                  + Theme.spacingXS
                height: Theme.spacingL
                radius: height / 2
                color: isActive ? Theme.primary : isPlaceholder ? Theme.surfaceTextLight : isHovered ? Theme.outlineButton : Theme.surfaceTextAlpha

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent
                    hoverEnabled: !isPlaceholder
                    cursorShape: isPlaceholder ? Qt.ArrowCursor : Qt.PointingHandCursor
                    enabled: !isPlaceholder
                    onClicked: {
                        if (!isPlaceholder) {
                            if (CompositorService.isNiri) {
                                NiriService.switchToWorkspace(modelData - 1)
                            } else if (CompositorService.isHyprland) {
                                HyprlandService.switchToWorkspace(modelData)
                            }
                        }
                    }
                }

                // Icon display (priority over numbers)
                DankIcon {
                    visible: hasIcon && iconData.type === "icon"
                    anchors.centerIn: parent
                    name: hasIcon
                          && iconData.type === "icon" ? iconData.value : ""
                    size: Theme.fontSizeSmall
                    color: isActive ? Qt.rgba(Theme.surfaceContainer.r,
                                              Theme.surfaceContainer.g,
                                              Theme.surfaceContainer.b,
                                              0.95) : Theme.surfaceTextMedium
                    weight: isActive && !isPlaceholder ? 500 : 400
                }

                // Custom text display (priority over numbers)
                StyledText {
                    visible: hasIcon && iconData.type === "text"
                    anchors.centerIn: parent
                    text: hasIcon
                          && iconData.type === "text" ? iconData.value : ""
                    color: isActive ? Qt.rgba(Theme.surfaceContainer.r,
                                              Theme.surfaceContainer.g,
                                              Theme.surfaceContainer.b,
                                              0.95) : Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: isActive
                                 && !isPlaceholder ? Font.DemiBold : Font.Normal
                }

                // Number display (secondary priority, only when no icon)
                StyledText {
                    visible: SettingsData.showWorkspaceIndex && !hasIcon
                    anchors.centerIn: parent
                    text: isPlaceholder ? sequentialNumber : sequentialNumber
                    color: isActive ? Qt.rgba(
                                          Theme.surfaceContainer.r,
                                          Theme.surfaceContainer.g,
                                          Theme.surfaceContainer.b,
                                          0.95) : isPlaceholder ? Theme.surfaceTextAlpha : Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: isActive
                                 && !isPlaceholder ? Font.DemiBold : Font.Normal
                }

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.mediumDuration
                        easing.type: Theme.emphasizedEasing
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.mediumDuration
                        easing.type: Theme.emphasizedEasing
                    }
                }
            }
        }
    }
}
