import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets

Item {
    id: aboutTab

    DankFlickable {
        anchors.fill: parent
        anchors.topMargin: Theme.spacingL
        clip: true
        contentHeight: mainColumn.height
        contentWidth: width

        Column {
            id: mainColumn

            width: parent.width
            spacing: Theme.spacingXL

            // ASCII Art Header
            StyledRect {
                width: parent.width
                height: asciiSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: asciiSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Item {
                        width: parent.width
                        height: asciiText.implicitHeight

                        StyledText {
                            id: asciiText
                            
                            text: "██████╗  █████╗ ███╗   ██╗██╗  ██╗\n██╔══██╗██╔══██╗████╗  ██║██║ ██╔╝\n██║  ██║███████║██╔██╗ ██║█████╔╝ \n██║  ██║██╔══██║██║╚██╗██║██╔═██╗ \n██████╔╝██║  ██║██║ ╚████║██║  ██╗\n╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝"
                            isMonospace: true
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.primary
                            anchors.centerIn: parent
                        }
                    }

                    StyledText {
                        text: "DankMaterialShell"
                        font.pixelSize: Theme.fontSizeXLarge
                        font.weight: Font.Bold
                        color: Theme.surfaceText
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }

                    StyledText {
                        text: "A desktop shell built with <a href=\"https://quickshell.org\">Quickshell</a>"
                        font.pixelSize: Theme.fontSizeMedium
                        linkColor: Theme.primary
                        onLinkActivated: (url) => Qt.openUrlExternally(url)
                        color: Theme.surfaceVariantText
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                        wrapMode: Text.WordWrap

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                            acceptedButtons: Qt.NoButton
                            propagateComposedEvents: true
                        }
                    }

                }

            }

            // Project Information
            StyledRect {
                width: parent.width
                height: projectSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: projectSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "info"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "About"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                    }

                    StyledText {
                        text: `DankMaterialShell is a modern desktop inspired by <a href="https://m3.material.io/">MUI 3</a>.
<br /><br/>The goal is to provide a high level of functionality and customization so that it can be a suitable replacement for complete desktop environments like Gnome, KDE, or Cosmic.
                        `
                        font.pixelSize: Theme.fontSizeMedium
                        linkColor: Theme.primary
                        onLinkActivated: (url) => Qt.openUrlExternally(url)
                        color: Theme.surfaceVariantText
                        width: parent.width
                        wrapMode: Text.WordWrap

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                            acceptedButtons: Qt.NoButton
                            propagateComposedEvents: true
                        }
                    }
                }

            }

            // Technical Details
            StyledRect {
                width: parent.width
                height: techSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: techSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "code"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "Technical Details"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                    }

                    Grid {
                        width: parent.width
                        columns: 2
                        columnSpacing: Theme.spacingL
                        rowSpacing: Theme.spacingS

                        StyledText {
                            text: "Framework:"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }

                        StyledText {
                            text: "Quickshell"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            text: "Language:"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }

                        StyledText {
                            text: "QML (Qt Modeling Language)"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            text: "Compositor:"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }

                        StyledText {
                            text: "Niri (Hyprland Coming Soon™)"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            text: "Github:"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }

                        StyledText {
                            text: "<a href=\"https://github.com/AvengeMedia/DankMaterialShell\">DankMaterialShell</a> - Support Us With a Star ⭐"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceVariantText
                            linkColor: Theme.primary
                            onLinkActivated: (url) => Qt.openUrlExternally(url)

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                                acceptedButtons: Qt.NoButton
                                propagateComposedEvents: true
                            }
                        }

                        StyledText {
                            text: "System Monitoring:"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }

                        StyledText {
                            text: "<a href=\"https://github.com/AvengeMedia/dgop\">dgop</a> - Dank Stateless System Monitoring"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceVariantText
                            linkColor: Theme.primary
                            onLinkActivated: (url) => Qt.openUrlExternally(url)

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

    }

}