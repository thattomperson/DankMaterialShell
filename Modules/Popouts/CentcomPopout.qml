import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Modules.CentcomCenter

PanelWindow {
    id: root

    readonly property bool hasActiveMedia: MprisController.activePlayer !== null
    property bool calendarVisible: false
    property bool internalVisible: false

    visible: internalVisible
    
    onCalendarVisibleChanged: {
        if (calendarVisible) {
            internalVisible = true
            Qt.callLater(() => {
                // This ensures opacity changes after window is visible
                internalVisible = true // Force re-trigger if needed
            })
        } else {
            internalVisible = false
        }
    }
    onVisibleChanged: {
        if (visible && CalendarService)
            CalendarService.loadCurrentMonth();
    }
    
    implicitWidth: 480
    implicitHeight: 600
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Rectangle {
        id: mainContainer

        function calculateWidth() {
            let baseWidth = 320;
            if (leftWidgets.hasAnyWidgets)
                return Math.min(parent.width * 0.9, 600);

            return Math.min(parent.width * 0.7, 400);
        }

        function calculateHeight() {
            let contentHeight = Theme.spacingM * 2; // margins
            // Main row with widgets and calendar
            let widgetHeight = 160;
            // Media widget always present
            widgetHeight += 140 + Theme.spacingM;
            // Weather widget always present
            let calendarHeight = 300;
            let mainRowHeight = Math.max(widgetHeight, calendarHeight);
            contentHeight += mainRowHeight + Theme.spacingM;
            // Add events widget height - use calculated height instead of actual
            if (CalendarService && CalendarService.khalAvailable) {
                let hasEvents = events.selectedDateEvents && events.selectedDateEvents.length > 0;
                let eventsHeight = hasEvents ? Math.min(300, 80 + events.selectedDateEvents.length * 60) : 120;
                contentHeight += eventsHeight;
            }
            return Math.min(contentHeight, parent.height * 0.9);
        }

        readonly property real targetWidth: Math.min(Screen.width * 0.9, 600)
        width: targetWidth
        height: calculateHeight()
        color: Theme.surfaceContainer
        radius: Theme.cornerRadiusLarge
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
        border.width: 1
        layer.enabled: true
        opacity: calendarVisible ? 1 : 0
        x: (Screen.width - targetWidth) / 2
        y: Theme.barHeight + 4

        Behavior on opacity {
            NumberAnimation {
                duration: Anims.durShort
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Theme.surfaceTint.r, Theme.surfaceTint.g, Theme.surfaceTint.b, 0.04)
            radius: parent.radius

            SequentialAnimation on opacity {
                running: calendarVisible
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

        Connections {
            function onEventsByDateChanged() {
                mainContainer.height = mainContainer.calculateHeight();
            }

            function onKhalAvailableChanged() {
                mainContainer.height = mainContainer.calculateHeight();
            }

            target: CalendarService
            enabled: CalendarService !== null
        }

        Connections {
            function onSelectedDateEventsChanged() {
                mainContainer.height = mainContainer.calculateHeight();
            }

            target: events
            enabled: events !== null
        }


        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingM

            // Main row with widgets and calendar
            Row {
                width: parent.width
                height: {
                    let widgetHeight = 160; // Media widget always present
                    widgetHeight += 140 + Theme.spacingM; // Weather widget always present
                    let calendarHeight = 300;
                    return Math.max(widgetHeight, calendarHeight);
                }
                spacing: Theme.spacingM

                // Left section for widgets
                Column {
                    id: leftWidgets

                    property bool hasAnyWidgets: true // Always show media widget and weather widget

                    width: hasAnyWidgets ? parent.width * 0.45 : 0
                    height: childrenRect.height
                    spacing: Theme.spacingM
                    visible: hasAnyWidgets
                    anchors.top: parent.top

                    MediaPlayer {
                        visible: true // Always visible - shows placeholder when no media
                        width: parent.width
                        height: 160
                    }

                    Weather {
                        visible: true // Always visible - shows placeholder when no weather
                        width: parent.width
                        height: 140
                    }

                }

                // Right section for calendar
                CalendarGrid {
                    id: calendarGrid

                    width: leftWidgets.hasAnyWidgets ? parent.width * 0.55 - Theme.spacingL : parent.width
                    height: parent.height
                }

            }

            // Full-width events widget below
            Events {
                id: events

                width: parent.width
                selectedDate: calendarGrid.selectedDate
            }

        }

        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 4
            shadowBlur: 0.5
            shadowColor: Qt.rgba(0, 0, 0, 0.15)
            shadowOpacity: 0.15
        }



    }

    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: calendarVisible
        onClicked: {
            calendarVisible = false;
        }
    }

}
