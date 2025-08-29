pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Common

Singleton {
    id: root

    property bool automationAvailable: false
    property bool locationProviderAvailable: false
    property var availableProviders: []
    property string currentProvider: ""
    property bool isAutomaticNightTime: false
    property string currentLocation: ""
    property real latitude: 0.0
    property real longitude: 0.0

    function testGeoclueConnection() {
        geoclueTestProcess.running = false
        geoclueTestProcess.command = [
            "timeout", "32",
            "gammastep", 
            "-m", "wayland",
            "-l", "geoclue2",
            "-O", "6500",
            "-v"
        ]
        geoclueTestProcess.running = true
    }

    Component.onCompleted: {
        checkAvailability()
        updateFromSessionData()
        
        if (typeof globalThis !== 'undefined') {
            globalThis.testNightMode = manualNightModeTest
            globalThis.resetNightMode = manualResetTest
            globalThis.clearNightModeLocation = clearLocation
            globalThis.nightModeService = root
        }
    }

    function checkAvailability() {
        gammaStepTestProcess.running = true
    }

    function startAutomation() {
        if (!automationAvailable) {
            console.warn("NightModeAutomationService: Gammastep not available")
            return
        }

        // Stop any existing automation processes first
        stopAutomation()

        const mode = SessionData.nightModeAutoMode || "manual"
        
        switch (mode) {
            case "time":
                startTimeBasedMode()
                break
            case "location":
                startLocationBasedMode()
                break
            case "manual":
            default:
                stopAutomation()
                break
        }
    }

    function stopAutomation() {
        
        // Stop the unified process
        gammaStepProcess.running = false
        
        isAutomaticNightTime = false
    }

    function startTimeBasedMode() {
        checkTimeBasedMode()
    }

    function startLocationBasedMode() {
        gammaStepProcess.running = false
        
        const temperature = SessionData.nightModeTemperature || 4500
        const dayTemp = 6500
        
        gammaStepProcess.processType = "automation"
        
        if (latitude !== 0.0 && longitude !== 0.0) {
            gammaStepProcess.command = buildGammastepCommand([
                "-m", "wayland",
                "-l", `${latitude.toFixed(6)}:${longitude.toFixed(6)}`,
                "-t", `${dayTemp}:${temperature}`,
                "-v"
            ])
            gammaStepProcess.running = true
            return
        }
        
        // Check if location providers are available
        if (!locationProviderAvailable) {
            console.warn("NightModeAutomationService: No location provider available, falling back to time-based mode")
            SessionData.setNightModeAutoMode("time")
            startTimeBasedMode()
            return
        }
        
        if (currentProvider === "geoclue2") {
            const temperature = SessionData.nightModeTemperature || 4500
            const dayTemp = 6500
            
            gammaStepProcess.processType = "automation"
            gammaStepProcess.command = buildGammastepCommand([
                "-m", "wayland",
                "-l", "geoclue2",
                "-t", `${dayTemp}:${temperature}`,
                "-v"
            ])
            gammaStepProcess.running = true
            return
        } else {
            console.warn("NightModeAutomationService: No working location provider, falling back to time-based mode")
            SessionData.setNightModeAutoMode("time")
            startTimeBasedMode()
            return
        }
    }

    function checkTimeBasedMode() {
        if (!SessionData.nightModeAutoEnabled || SessionData.nightModeAutoMode !== "time") {
            return
        }

        const now = new Date()
        const currentHour = now.getHours()
        const currentMinute = now.getMinutes()
        const currentTime = currentHour * 60 + currentMinute

        const startTime = SessionData.nightModeStartTime || "20:00"
        const endTime = SessionData.nightModeEndTime || "06:00"
        
        const startParts = startTime.split(":")
        const endParts = endTime.split(":")
        
        const startMinutes = parseInt(startParts[0]) * 60 + parseInt(startParts[1])
        const endMinutes = parseInt(endParts[0]) * 60 + parseInt(endParts[1])

        let shouldBeNight = false
        
        if (startMinutes > endMinutes) {
            shouldBeNight = (currentTime >= startMinutes) || (currentTime < endMinutes)
        } else {
            shouldBeNight = (currentTime >= startMinutes) && (currentTime < endMinutes)
        }

        if (shouldBeNight !== isAutomaticNightTime) {
            isAutomaticNightTime = shouldBeNight
            
            if (shouldBeNight) {
                requestNightModeActivation()
            } else {
                requestNightModeDeactivation()
            }
        }
    }

    function requestNightModeActivation() {
        const temperature = SessionData.nightModeTemperature || 4500
        
        gammaStepProcess.running = false
        gammaStepProcess.processType = "activate"
        
        gammaStepProcess.command = buildGammastepCommand([
            "-m", "wayland", 
            "-O", String(temperature)
        ])
        gammaStepProcess.running = true
        
        if (SessionData.nightModeAutoEnabled && SessionData.nightModeAutoMode !== "manual") {
            SessionData.setNightModeEnabled(true)
        }
    }

    function requestNightModeDeactivation() {
        gammaStepProcess.running = false
        
        gammaStepProcess.processType = "reset"
        gammaStepProcess.command = buildGammastepCommand([
            "-m", "wayland", 
            "-O", "6500"
        ])
        gammaStepProcess.running = true
        
        if (SessionData.nightModeAutoEnabled && SessionData.nightModeAutoMode !== "manual") {
            SessionData.setNightModeEnabled(false)
        }
    }

    function setLocation(lat, lon) {
        latitude = lat
        longitude = lon
        currentLocation = `${lat.toFixed(6)},${lon.toFixed(6)}`
        
        if (SessionData.nightModeAutoEnabled && SessionData.nightModeAutoMode === "location") {
            startLocationBasedMode()
        }
    }

    function clearLocation() {
        latitude = 0.0
        longitude = 0.0
        currentLocation = ""
        
        SessionData.setLatitude(0.0)
        SessionData.setLongitude(0.0)
        SessionData.saveSettings()
        
        if (SessionData.nightModeAutoEnabled && SessionData.nightModeAutoMode === "location") {
            startLocationBasedMode()
        }
    }

    function buildGammastepCommand(gammastepArgs) {
        const commandStr = "pkill gammastep; " + ["gammastep"].concat(gammastepArgs).join(" ")
        return ["sh", "-c", commandStr]
    }


    function updateFromSessionData() {
        if (SessionData.latitude !== 0.0 && SessionData.longitude !== 0.0) {
            setLocation(SessionData.latitude, SessionData.longitude)
        } else {
            latitude = 0.0
            longitude = 0.0
            currentLocation = ""
        }
    }

    function detectLocationProviders() {
        locationProviderDetectionProcess.running = true
    }


    function manualNightModeTest() {
        const temperature = SessionData.nightModeTemperature || 4500
        
        gammaStepProcess.running = false
        gammaStepProcess.processType = "test"
        gammaStepProcess.command = buildGammastepCommand([
            "-m", "wayland", 
            "-O", String(temperature)
        ])
        gammaStepProcess.running = true
        
        testFeedbackTimer.interval = 2000
        testFeedbackTimer.feedbackMessage = "Night mode test applied"
        testFeedbackTimer.start()
    }

    function manualResetTest() {
        gammaStepProcess.running = false
        gammaStepProcess.processType = "test"
        gammaStepProcess.command = buildGammastepCommand([
            "-m", "wayland", 
            "-O", "6500"
        ])
        gammaStepProcess.running = true
        
        testFeedbackTimer.interval = 2000
        testFeedbackTimer.feedbackMessage = "Screen reset to normal temperature"
        testFeedbackTimer.start()
    }

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
        onDateChanged: {
            if (SessionData.nightModeAutoEnabled && SessionData.nightModeAutoMode === "time") {
                checkTimeBasedMode()
            }
        }
    }

    Process {
        id: gammaStepTestProcess
        command: ["which", "gammastep"]
        running: false
        
        onExited: function(exitCode) {
            automationAvailable = (exitCode === 0)
            if (automationAvailable) {
                detectLocationProviders()
                
                if (SessionData.nightModeAutoEnabled) {
                    startAutomation()
                }
            }
        }
    }

    Process {
        id: locationProviderDetectionProcess
        command: ["gammastep", "-l", "list"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    // Parse provider names - they start with whitespace and are single words
                    const lines = text.trim().split('\n')
                    const providers = lines.filter(line => {
                        const trimmed = line.trim()
                        // Provider names are single words that start with whitespace in original line
                        return line.startsWith('  ') && 
                               trimmed.length > 0 && 
                               !trimmed.includes(' ') && 
                               !trimmed.includes(':') &&
                               !trimmed.includes('.')
                    }).map(line => line.trim())
                    
                    availableProviders = providers
                    locationProviderAvailable = providers.length > 0
                    
                    if (locationProviderAvailable && !currentProvider) {
                        currentProvider = providers[0]
                    }
                    
                    // Providers detected
                }
            }
        }

        onExited: function(exitCode) {
            if (exitCode !== 0) {
                locationProviderAvailable = false
            }
        }
    }

    Process {
        id: geoclueTestProcess
        running: false
        
        onExited: function(exitCode) {
            if (exitCode === 0) {
                const temperature = SessionData.nightModeTemperature || 4500
                const dayTemp = 6500
                
                gammaStepProcess.processType = "automation"
                gammaStepProcess.command = buildGammastepCommand([
                    "-m", "wayland",
                    "-l", "geoclue2",
                    "-t", `${dayTemp}:${temperature}`,
                    "-v"
                ])
                gammaStepProcess.running = true
            } else {
                SessionData.setNightModeAutoMode("time")
                startTimeBasedMode()
            }
        }
    }

    Process {
        id: gammaStepProcess
        running: false
        
        property string processType: "" // "automation", "activate", "reset", "test"
        
        stdout: StdioCollector {
            onStreamFinished: {}
        }
        
        stderr: StdioCollector {
            onStreamFinished: {}
        }
        
        onRunningChanged: {
            if (running) {
                // Start timeout only for test commands - automation, activate, and reset should not timeout
                if (processType === "test") {
                    processTimeoutTimer.start()
                }
            } else {
                // Stop timeout when process ends
                processTimeoutTimer.stop()
            }
        }
        
        onExited: function(exitCode) {
            processTimeoutTimer.stop()
            
            const isSuccessfulCompletion = (exitCode === 0) || 
                                         ((processType === "activate" || processType === "reset") && exitCode === 15)
            
            if (!isSuccessfulCompletion) {
                switch(processType) {
                    case "automation":
                        if (SessionData.nightModeAutoEnabled && SessionData.nightModeAutoMode === "location") {
                            if (exitCode === 15 || exitCode === 124) {
                                SessionData.setNightModeAutoMode("time")
                                startTimeBasedMode()
                            } else {
                                restartTimer.start()
                            }
                        } else if (SessionData.nightModeAutoEnabled && SessionData.nightModeAutoMode === "time") {
                            restartTimer.start()
                        }
                        break
                }
            }
        }
    }

    Timer {
        id: processTimeoutTimer
        interval: 30000 // 30 second timeout (increased from 10s for one-shot commands)
        running: false
        repeat: false
        onTriggered: {
            if (gammaStepProcess.running) {
                console.warn("NightModeAutomationService: Test process timed out, killing process")
                // Only kill test processes that have timed out
                if (gammaStepProcess.processType === "test") {
                    gammaStepProcess.running = false
                } else {
                    console.warn("NightModeAutomationService: Non-test process still running after timeout, but not killing")
                }
            }
        }
    }

    Timer {
        id: restartTimer
        interval: 10000
        running: false
        repeat: false
        onTriggered: {
            if (SessionData.nightModeAutoEnabled && SessionData.nightModeAutoMode === "location") {
                startLocationBasedMode()
            }
        }
    }

    Timer {
        id: testFeedbackTimer
        interval: 2000
        running: false
        repeat: false
        property string feedbackMessage: ""
        onTriggered: {
            if (feedbackMessage.length > 0) {
                console.log(feedbackMessage)
                feedbackMessage = ""
            }
        }
    }

    Connections {
        target: SessionData
        function onNightModeAutoEnabledChanged() {
            console.log("NightModeAutomationService: Auto enabled changed to", SessionData.nightModeAutoEnabled)
            if (SessionData.nightModeAutoEnabled) {
                startAutomation()
            } else {
                stopAutomation()
            }
        }
        function onNightModeAutoModeChanged() {
            if (SessionData.nightModeAutoEnabled) {
                startAutomation()
            }
        }
        function onNightModeStartTimeChanged() {
            console.log("NightModeAutomationService: Start time changed to", SessionData.nightModeStartTime)
            if (SessionData.nightModeAutoEnabled && SessionData.nightModeAutoMode === "time") {
                checkTimeBasedMode()
            }
        }
        function onNightModeEndTimeChanged() {
            console.log("NightModeAutomationService: End time changed to", SessionData.nightModeEndTime)
            if (SessionData.nightModeAutoEnabled && SessionData.nightModeAutoMode === "time") {
                checkTimeBasedMode()
            }
        }
        function onNightModeTemperatureChanged() {
            if (SessionData.nightModeAutoEnabled) {
                startAutomation()
            }
        }
        function onLatitudeChanged() {
            updateFromSessionData()
        }
        function onLongitudeChanged() {
            updateFromSessionData()
        }
    }
}