import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Modules.ProcessList

ColumnLayout {
    id: processesTab
    anchors.fill: parent
    spacing: Theme.spacingM
    
    property var contextMenu: null

    SystemOverview {
        Layout.fillWidth: true
    }

    ProcessListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contextMenu: processesTab.contextMenu || localContextMenu
    }

    ProcessContextMenu {
        id: localContextMenu
    }
}