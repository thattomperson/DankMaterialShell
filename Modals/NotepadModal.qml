import QtQuick
import QtQuick.Controls
import QtCore
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modals.Common
import qs.Services
import qs.Widgets
import qs.Modals.FileBrowser

pragma ComponentBehavior: Bound

DankModal {
    id: root

    property bool notepadModalVisible: false
    property bool fileDialogOpen: false
    property string currentFileName: ""
    property bool hasUnsavedChanges: false
    property url currentFileUrl

    function show() {
        notepadModalVisible = true
        shouldHaveFocus = Qt.binding(() => {
            return notepadModalVisible && !fileDialogOpen
        })
        open()
    }

    function hide() {
        if (hasUnsavedChanges) {
            // Could add unsaved changes dialog here
        }
        notepadModalVisible = false
        currentFileName = ""
        currentFileUrl = ""
        hasUnsavedChanges = false
        close()
    }

    function toggle() {
        if (notepadModalVisible)
            hide()
        else
            show()
    }

    visible: notepadModalVisible
    width: 700
    height: 520
    enableShadow: true
    onShouldHaveFocusChanged: {
    }
    onBackgroundClicked: hide()

    content: Component {
        Item {
            id: contentItem

            anchors.fill: parent
            property alias textArea: textArea
            
            Connections {
                target: root
                function onNotepadModalVisibleChanged() {
                    if (root.notepadModalVisible) {
                        Qt.callLater(() => {
                            textArea.forceActiveFocus()
                        })
                    }
                }
            }

            function newDocument() {
                if (root.hasUnsavedChanges) {
                    // Could add confirmation dialog here
                }
                textArea.text = ""
                SessionData.notepadContent = ""
                root.currentFileName = ""
                root.currentFileUrl = ""
                root.hasUnsavedChanges = false
            }
            
            function openSaveDialog() {
                root.allowFocusOverride = true
                root.shouldHaveFocus = false
                root.fileDialogOpen = true
                saveBrowser.open()
            }
            
            function openLoadDialog() {
                root.allowFocusOverride = true
                root.shouldHaveFocus = false
                root.fileDialogOpen = true
                loadBrowser.open()
            }
            
            function saveToCurrentFile() {
                if (root.currentFileUrl.toString()) {
                    saveToFile(root.currentFileUrl)
                } else {
                    openSaveDialog()
                }
            }
            
            function saveToFile(fileUrl) {
                const content = textArea.text
                const cleanPath = fileUrl.toString().replace(/^file:\/\//, '')
                // Use printf to safely handle special characters and escape single quotes
                const escapedContent = content.replace(/'/g, "'\\''")
                fileWriter.command = ["sh", "-c", "printf '%s' '" + escapedContent + "' > '" + cleanPath + "'"]
                fileWriter.running = true
            }
            
            function loadFromFile(fileUrl) {
                const cleanPath = fileUrl.toString().replace(/^file:\/\//, '')
                fileReader.command = ["cat", cleanPath]
                fileReader.running = true
            }

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    height: 40

                    Row {
                        width: parent.width - closeButton.width
                        spacing: Theme.spacingM

                        Column {
                            spacing: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter
                            
                            StyledText {
                                text: qsTr("Notepad")
                                font.pixelSize: Theme.fontSizeLarge
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                            }
                            
                            StyledText {
                                text: (root.hasUnsavedChanges ? "● " : "") + (root.currentFileName || qsTr("Untitled"))
                                font.pixelSize: Theme.fontSizeSmall
                                color: root.hasUnsavedChanges ? Theme.primary : Theme.surfaceTextMedium
                                visible: root.currentFileName !== "" || root.hasUnsavedChanges
                                elide: Text.ElideMiddle
                                maximumLineCount: 1
                                width: 200
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            
                            StyledText {
                                text: SessionData.notepadContent.length > 0 ? qsTr("%1 characters").arg(SessionData.notepadContent.length) : qsTr("Empty")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceTextMedium
                            }
                            
                            StyledText {
                                text: qsTr("Lines: %1").arg(textArea.lineCount)
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceTextMedium
                                visible: SessionData.notepadContent.length > 0
                            }
                        }

                    }

                    DankActionButton {
                        id: closeButton

                        iconName: "close"
                        iconSize: Theme.iconSize - 4
                        iconColor: Theme.surfaceText
                        onClicked: root.hide()
                    }

                }

                StyledRect {
                    width: parent.width
                    height: parent.height - 90
                    color: Theme.surface
                    border.color: Theme.outlineMedium
                    border.width: 1
                    radius: Theme.cornerRadius

                    ScrollView {
                        id: scrollView

                        anchors.fill: parent
                        anchors.margins: 1
                        clip: true

                        TextArea {
                            id: textArea

                            text: SessionData.notepadContent
                            placeholderText: qsTr("Start typing your notes here...")
                            font.family: SettingsData.monoFontFamily
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                            selectByMouse: true
                            selectByKeyboard: true
                            wrapMode: TextArea.Wrap
                            focus: root.notepadModalVisible
                            activeFocusOnTab: true
                            textFormat: TextEdit.PlainText
                            persistentSelection: true
                            tabStopDistance: 40
                            leftPadding: Theme.spacingM
                            topPadding: Theme.spacingM
                            rightPadding: Theme.spacingM
                            bottomPadding: Theme.spacingM
                            
                            onTextChanged: {
                                if (text !== SessionData.notepadContent) {
                                    SessionData.notepadContent = text
                                    root.hasUnsavedChanges = true
                                    saveTimer.restart()
                                }
                            }
                            
                            Keys.onEscapePressed: (event) => {
                                root.hide()
                                event.accepted = true
                            }
                            
                            Keys.onPressed: (event) => {
                                if (event.modifiers & Qt.ControlModifier) {
                                    switch (event.key) {
                                    case Qt.Key_S:
                                        event.accepted = true
                                        if (root.currentFileUrl.toString()) {
                                            contentItem.saveToCurrentFile()
                                        } else {
                                            contentItem.openSaveDialog()
                                        }
                                        break
                                    case Qt.Key_O:
                                        event.accepted = true
                                        contentItem.openLoadDialog()
                                        break
                                    case Qt.Key_N:
                                        event.accepted = true
                                        contentItem.newDocument()
                                        break
                                    case Qt.Key_A:
                                        event.accepted = true
                                        selectAll()
                                        break
                                    }
                                }
                            }
                            
                            Component.onCompleted: {
                                if (root.notepadModalVisible) {
                                    Qt.callLater(() => {
                                        forceActiveFocus()
                                    })
                                }
                            }

                            background: Rectangle {
                                color: "transparent"
                            }

                        }

                    }

                }

                Row {
                    width: parent.width
                    height: 40
                    spacing: Theme.spacingL

                    Row {
                        spacing: Theme.spacingS

                        DankActionButton {
                            iconName: "save"
                            iconSize: Theme.iconSize - 2
                            iconColor: Theme.primary
                            enabled: root.hasUnsavedChanges || SessionData.notepadContent.length > 0
                            onClicked: contentItem.saveToCurrentFile()
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.currentFileUrl.toString() ? qsTr("Save") : qsTr("Save as...")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceTextMedium
                        }
                    }

                    Row {
                        spacing: Theme.spacingS

                        DankActionButton {
                            iconName: "folder_open"
                            iconSize: Theme.iconSize - 2
                            iconColor: Theme.secondary
                            onClicked: contentItem.openLoadDialog()
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Open file")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceTextMedium
                        }
                    }

                    Row {
                        spacing: Theme.spacingS

                        DankActionButton {
                            iconName: "note_add"
                            iconSize: Theme.iconSize - 2
                            iconColor: Theme.surfaceText
                            onClicked: contentItem.newDocument()
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("New")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceTextMedium
                        }
                    }

                    Item {
                        width: 1
                        height: 1
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: saveTimer.running ? qsTr("Auto-saving...") : (root.hasUnsavedChanges ? qsTr("Unsaved changes") : qsTr("Auto-saved"))
                        font.pixelSize: Theme.fontSizeSmall
                        color: root.hasUnsavedChanges ? Theme.warning : (saveTimer.running ? Theme.primary : Theme.surfaceTextMedium)
                        opacity: SessionData.notepadContent.length > 0 ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.shortDuration
                                easing.type: Theme.standardEasing
                            }
                        }
                    }
                }

            }

            Timer {
                id: saveTimer

                interval: 1000
                repeat: false
                onTriggered: {
                    SessionData.saveSettings()
                    root.hasUnsavedChanges = false
                }
            }

            // Improved file I/O using Quickshell Process with better safety
            Process {
                id: fileWriter
                
                onExited: (exitCode) => {
                    if (exitCode === 0) {
                        root.hasUnsavedChanges = false
                    } else {
                        console.warn("Notepad: Failed to save file, exit code:", exitCode)
                    }
                }
            }

            Process {
                id: fileReader
                
                stdout: StdioCollector {
                    onStreamFinished: {
                        textArea.text = text
                        SessionData.notepadContent = text
                        root.hasUnsavedChanges = false
                    }
                }
                
                onExited: (exitCode) => {
                    if (exitCode !== 0) {
                        console.warn("Notepad: Failed to load file, exit code:", exitCode)
                    }
                }
            }

            FileBrowserModal {
                id: saveBrowser

                browserTitle: qsTr("Save Notepad File")
                browserIcon: "save"
                browserType: "notepad_save"
                fileExtensions: ["*.txt", "*.md", "*.*"]
                allowStacking: true
                saveMode: true
                defaultFileName: "note.txt"
                
                onFileSelected: (path) => {
                    root.fileDialogOpen = false
                    const cleanPath = path.toString().replace(/^file:\/\//, '')
                    const fileName = cleanPath.split('/').pop()
                    const fileUrl = "file://" + cleanPath
                    
                    root.currentFileName = fileName
                    root.currentFileUrl = fileUrl
                    
                    contentItem.saveToFile(fileUrl)
                    close()
                    
                    // Restore modal focus
                    root.allowFocusOverride = false
                    root.shouldHaveFocus = Qt.binding(() => {
                        return root.notepadModalVisible && !root.fileDialogOpen
                    })
                    Qt.callLater(() => {
                        textArea.forceActiveFocus()
                    })
                }
                
                onDialogClosed: {
                    root.fileDialogOpen = false
                    // Restore modal focus
                    root.allowFocusOverride = false
                    root.shouldHaveFocus = Qt.binding(() => {
                        return root.notepadModalVisible && !root.fileDialogOpen
                    })
                    Qt.callLater(() => {
                        textArea.forceActiveFocus()
                    })
                }
            }

            FileBrowserModal {
                id: loadBrowser

                browserTitle: qsTr("Open Notepad File")
                browserIcon: "folder_open"
                browserType: "notepad_load"
                fileExtensions: ["*.txt", "*.md", "*.*"]
                allowStacking: true
                
                onFileSelected: (path) => {
                    root.fileDialogOpen = false
                    const cleanPath = path.toString().replace(/^file:\/\//, '')
                    const fileName = cleanPath.split('/').pop()
                    const fileUrl = "file://" + cleanPath
                    
                    root.currentFileName = fileName
                    root.currentFileUrl = fileUrl
                    
                    contentItem.loadFromFile(fileUrl)
                    close()
                    
                    // Restore modal focus
                    root.allowFocusOverride = false
                    root.shouldHaveFocus = Qt.binding(() => {
                        return root.notepadModalVisible && !root.fileDialogOpen
                    })
                    Qt.callLater(() => {
                        textArea.forceActiveFocus()
                    })
                }
                
                onDialogClosed: {
                    root.fileDialogOpen = false
                    // Restore modal focus
                    root.allowFocusOverride = false
                    root.shouldHaveFocus = Qt.binding(() => {
                        return root.notepadModalVisible && !root.fileDialogOpen
                    })
                    Qt.callLater(() => {
                        textArea.forceActiveFocus()
                    })
                }
            }

        }

    }

}