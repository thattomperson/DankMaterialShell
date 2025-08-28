pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
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

    Component.onCompleted: {
        console.log("NightModeAutomationService: Component completed")
        checkAvailability()
        updateFromSessionData()
        if (SessionData.nightModeAutoEnabled) {
            console.log("NightModeAutomationService: Auto-starting automation on init")
            startAutomation()
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
        automationTimer.stop()
        locationTimer.stop()
        if (gammaStepAutomationProcess.running) {
            gammaStepAutomationProcess.kill()
        }
        isAutomaticNightTime = false
    }

    function startTimeBasedMode() {
        console.log("NightModeAutomationService: Starting time-based automation")
        automationTimer.start()
        checkTimeBasedMode()
    }

    function startLocationBasedMode() {
        if (!locationProviderAvailable) {
            console.warn("NightModeAutomationService: No location provider available, falling back to time-based mode")
            startTimeBasedMode()
            return
        }

        console.log("NightModeAutomationService: Starting location-based automation")
        
        const temperature = SessionData.nightModeTemperature || 4500
        const dayTemp = 6500
        
        if (latitude !== 0.0 && longitude !== 0.0) {
            gammaStepAutomationProcess.command = [
                "gammastep", 
                "-m", "wayland",
                "-l", `${latitude.toFixed(6)}:${longitude.toFixed(6)}`,
                "-t", `${dayTemp}:${temperature}`,
                "-v"
            ]
        } else {
            gammaStepAutomationProcess.command = [
                "gammastep", 
                "-m", "wayland",
                "-l", currentProvider || "manual",
                "-t", `${dayTemp}:${temperature}`,
                "-v"
            ]
        }
        
        gammaStepAutomationProcess.running = true
        locationTimer.start()
    }

    function checkTimeBasedMode() {
        if (!SessionData.nightModeAutoEnabled || SessionData.nightModeAutoMode !== "time") {
            console.log("NightModeAutomationService: checkTimeBasedMode - not enabled or wrong mode")
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

        console.log(`NightModeAutomationService: Time check - Current: ${currentHour}:${currentMinute.toString().padStart(2, '0')} (${currentTime}), Range: ${startTime}-${endTime} (${startMinutes}-${endMinutes}), Should be night: ${shouldBeNight}`)

        if (shouldBeNight !== isAutomaticNightTime) {
            isAutomaticNightTime = shouldBeNight
            console.log("NightModeAutomationService: Automatic night time status changed to:", shouldBeNight)
            
            if (shouldBeNight) {
                requestNightModeActivation()
            } else {
                requestNightModeDeactivation()
            }
        } else {
            console.log("NightModeAutomationService: No change needed, isAutomaticNightTime already:", isAutomaticNightTime)
        }
    }

    function requestNightModeActivation() {
        console.log("NightModeAutomationService: Requesting night mode activation")
        const temperature = SessionData.nightModeTemperature || 4500
        console.log("NightModeAutomationService: Using temperature:", temperature + "K")
        
        gammaStepOneTimeProcess.command = [
            "gammastep", 
            "-m", "wayland", 
            "-O", String(temperature),
            "-P"
        ]
        console.log("NightModeAutomationService: Running gamma command:", gammaStepOneTimeProcess.command.join(" "))
        gammaStepOneTimeProcess.running = true
        
        SessionData.setNightModeEnabled(true)
    }

    function requestNightModeDeactivation() {
        console.log("NightModeAutomationService: Requesting night mode deactivation")
        
        gammaStepResetProcess.command = [
            "gammastep", 
            "-m", "wayland", 
            "-O", "6500",
            "-P"
        ]
        gammaStepResetProcess.running = true
        
        SessionData.setNightModeEnabled(false)
    }

    function setLocation(lat, lon) {
        latitude = lat
        longitude = lon
        currentLocation = `${lat.toFixed(6)},${lon.toFixed(6)}`
        
        if (SessionData.nightModeAutoEnabled && SessionData.nightModeAutoMode === "location") {
            startLocationBasedMode()
        }
    }

    function updateFromSessionData() {
        console.log("NightModeAutomationService: Updating from SessionData - lat:", SessionData.latitude, "lng:", SessionData.longitude)
        if (SessionData.latitude !== 0.0 && SessionData.longitude !== 0.0) {
            setLocation(SessionData.latitude, SessionData.longitude)
        }
    }

    function detectLocationProviders() {
        locationProviderDetectionProcess.running = true
    }

    function testAutomationNow() {
        console.log("NightModeAutomationService: Manual test triggered")
        console.log("NightModeAutomationService: Current settings - autoEnabled:", SessionData.nightModeAutoEnabled, "mode:", SessionData.nightModeAutoMode)
        if (SessionData.nightModeAutoMode === "time") {
            checkTimeBasedMode()
        } else if (SessionData.nightModeAutoMode === "location") {
            console.log("NightModeAutomationService: Location mode - coordinates:", latitude, longitude)
        }
    }

    Timer {
        id: automationTimer
        interval: 60000
        running: false
        repeat: true
        onTriggered: {
            checkTimeBasedMode()
        }
    }

    Timer {
        id: locationTimer
        interval: 300000
        running: false
        repeat: true
        onTriggered: {
            if (SessionData.nightModeAutoEnabled && SessionData.nightModeAutoMode === "location") {
                detectLocationProviders()
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
                console.log("NightModeAutomationService: Gammastep available")
                detectLocationProviders()
            } else {
                console.warn("NightModeAutomationService: Gammastep not available")
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
                    availableProviders = text.trim().split('\n').filter(line => line.trim().length > 0)
                    locationProviderAvailable = availableProviders.length > 0
                    
                    if (locationProviderAvailable && !currentProvider) {
                        currentProvider = availableProviders[0]
                    }
                    
                    console.log("NightModeAutomationService: Available providers:", availableProviders)
                }
            }
        }

        onExited: function(exitCode) {
            if (exitCode !== 0) {
                console.warn("NightModeAutomationService: Failed to detect location providers")
                locationProviderAvailable = false
            }
        }
    }

    Process {
        id: gammaStepAutomationProcess
        running: false
        
        onExited: function(exitCode) {
            if (SessionData.nightModeAutoEnabled && SessionData.nightModeAutoMode === "location" && exitCode !== 0) {
                console.warn("NightModeAutomationService: Location-based automation failed, exit code:", exitCode)
                restartTimer.start()
            }
        }
    }

    Process {
        id: gammaStepOneTimeProcess
        running: false
        
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                console.warn("NightModeAutomationService: Failed to enable night mode, exit code:", exitCode)
            }
        }
    }

    Process {
        id: gammaStepResetProcess
        running: false
        
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                console.warn("NightModeAutomationService: Failed to reset gamma, exit code:", exitCode)
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