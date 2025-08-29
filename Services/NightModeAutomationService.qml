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

    // Expose these functions to global scope for console debugging
    function testGeoclueConnection() {
        console.log("NightModeAutomationService: Testing geoclue2 connection...")
        if (geoclueTestProcess.running) {
            geoclueTestProcess.running = false
        }
        
        geoclueTestProcess.command = [
            "timeout", "32", // Increased to 32 seconds for geoclue location fix
            "gammastep", 
            "-m", "wayland",
            "-l", "geoclue2",
            "-O", "6500", // One-shot mode to test location quickly
            "-v"
        ]
        geoclueTestProcess.running = true
    }

    function debugTimeBasedMode() {
        const now = new Date()
        const currentHour = now.getHours()
        const currentMinute = now.getMinutes()
        const currentTime = currentHour * 60 + currentMinute

        const startTime = SessionData.nightModeStartTime || "20:00"
        const endTime = SessionData.nightModeEndTime || "06:00"
        
        console.log("=== DEBUG TIME BASED MODE ===")
        console.log("Current time:", now.toLocaleTimeString())
        console.log("Current minutes since midnight:", currentTime)
        console.log("Night mode start time:", startTime)
        console.log("Night mode end time:", endTime)
        console.log("Auto enabled:", SessionData.nightModeAutoEnabled)
        console.log("Auto mode:", SessionData.nightModeAutoMode)
        console.log("Temperature:", SessionData.nightModeTemperature + "K")
        console.log("isAutomaticNightTime:", isAutomaticNightTime)
        console.log("automationTimer running:", automationTimer.running)
        console.log("gammaStepProcess running:", gammaStepProcess.running)
        console.log("gammaStepProcess type:", gammaStepProcess.processType)
        
        // Force a check
        console.log("Forcing checkTimeBasedMode()...")
        checkTimeBasedMode()
    }

    Component.onCompleted: {
        console.log("NightModeAutomationService: Component completed")
        // Kill any straggling gammastep processes to prevent conflicts
        pkillProcess.running = true
        checkAvailability()
        updateFromSessionData()
        
        // Debug current SessionData values
        console.log("NightModeAutomationService: === SESSIONDATA DEBUG ===")
        console.log("NightModeAutomationService: nightModeAutoEnabled:", SessionData.nightModeAutoEnabled)
        console.log("NightModeAutomationService: nightModeAutoMode:", SessionData.nightModeAutoMode)
        console.log("NightModeAutomationService: nightModeStartTime:", SessionData.nightModeStartTime)
        console.log("NightModeAutomationService: nightModeEndTime:", SessionData.nightModeEndTime)
        console.log("NightModeAutomationService: nightModeTemperature:", SessionData.nightModeTemperature)
        console.log("NightModeAutomationService: nightModeEnabled:", SessionData.nightModeEnabled)
        console.log("NightModeAutomationService: === END SESSIONDATA DEBUG ===")
        
        // Expose debug functions globally
        if (typeof globalThis !== 'undefined') {
            globalThis.debugNightMode = debugTimeBasedMode
            globalThis.testNightMode = manualNightModeTest
            globalThis.resetNightMode = manualResetTest
            globalThis.clearNightModeLocation = clearLocation
            globalThis.debugLocationMode = debugLocationMode
            globalThis.nightModeService = root
        }
        
        // Don't start automation here - wait for Gammastep availability check to complete
        // The gammaStepTestProcess.onExited will start automation when ready
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
        automationTimer.stop()
        locationTimer.stop()
        
        // Stop the unified process
        if (gammaStepProcess.running) {
            gammaStepProcess.running = false
        }
        
        isAutomaticNightTime = false
    }

    function startTimeBasedMode() {
        console.log("NightModeAutomationService: === Starting time-based automation ===")
        console.log("NightModeAutomationService: automationTimer.running before start:", automationTimer.running)
        automationTimer.start()
        console.log("NightModeAutomationService: automationTimer.running after start:", automationTimer.running)
        console.log("NightModeAutomationService: automationTimer.interval:", automationTimer.interval, "ms")
        console.log("NightModeAutomationService: Now calling initial checkTimeBasedMode...")
        checkTimeBasedMode()
        console.log("NightModeAutomationService: === Time-based automation startup complete ===")
    }

    function startLocationBasedMode() {
        console.log("NightModeAutomationService: Starting location-based automation")
        
        // Stop the process first, then change command, then start
        if (gammaStepProcess.running) {
            gammaStepProcess.running = false
        }
        
        const temperature = SessionData.nightModeTemperature || 4500
        const dayTemp = 6500
        
        gammaStepProcess.processType = "automation"
        
        // Check manual coordinates first (highest priority)
        if (latitude !== 0.0 && longitude !== 0.0) {
            console.log(`NightModeAutomationService: Using manual coordinates: ${latitude.toFixed(6)},${longitude.toFixed(6)}`)
            gammaStepProcess.command = [
                "gammastep", 
                "-m", "wayland",
                "-l", `${latitude.toFixed(6)}:${longitude.toFixed(6)}`,
                "-t", `${dayTemp}:${temperature}`,
                "-v"
            ]
            gammaStepProcess.running = true
            locationTimer.start()
            return
        }
        
        // Check if location providers are available
        if (!locationProviderAvailable) {
            console.warn("NightModeAutomationService: No location provider available, falling back to time-based mode")
            SessionData.setNightModeAutoMode("time")
            startTimeBasedMode()
            return
        }
        
        // Use automatic location provider (geoclue2)
        if (currentProvider === "geoclue2") {
            console.log("NightModeAutomationService: Starting geoclue2 location provider...")
            
            // Kill any existing gammastep processes to prevent conflicts
            pkillProcess.running = true
            
            // Wait longer for geoclue2 to be ready and acquire location
            cleanupTimer.interval = 5000 // 5 second delay for geoclue2 location acquisition
            cleanupTimer.repeat = false // Single shot
            cleanupTimer.triggered.connect(function() {
                console.log("NightModeAutomationService: Starting geoclue2 after cleanup...")
                const temperature = SessionData.nightModeTemperature || 4500
                const dayTemp = 6500
                
                gammaStepProcess.processType = "automation"
                gammaStepProcess.command = [
                    "gammastep", 
                    "-m", "wayland",
                    "-l", "geoclue2",
                    "-t", `${dayTemp}:${temperature}`,
                    "-v"
                ]
                console.log("NightModeAutomationService: Geoclue2 command:", gammaStepProcess.command.join(" "))
                gammaStepProcess.running = true
                locationTimer.start()
            })
            cleanupTimer.start()
            return
        } else {
            console.warn("NightModeAutomationService: No working location provider, falling back to time-based mode")
            SessionData.setNightModeAutoMode("time")
            startTimeBasedMode()
            return
        }
    }

    function checkTimeBasedMode() {
        console.log("NightModeAutomationService: === checkTimeBasedMode CALLED ===")
        console.log("NightModeAutomationService: nightModeAutoEnabled:", SessionData.nightModeAutoEnabled)
        console.log("NightModeAutomationService: nightModeAutoMode:", SessionData.nightModeAutoMode)
        
        if (!SessionData.nightModeAutoEnabled || SessionData.nightModeAutoMode !== "time") {
            console.log("NightModeAutomationService: checkTimeBasedMode - not enabled or wrong mode")
            console.log("NightModeAutomationService: - autoEnabled:", SessionData.nightModeAutoEnabled)
            console.log("NightModeAutomationService: - autoMode:", SessionData.nightModeAutoMode)
            return
        }

        const now = new Date()
        const currentHour = now.getHours()
        const currentMinute = now.getMinutes()
        const currentTime = currentHour * 60 + currentMinute

        const startTime = SessionData.nightModeStartTime || "20:00"
        const endTime = SessionData.nightModeEndTime || "06:00"
        
        console.log("NightModeAutomationService: Raw start time from SessionData:", SessionData.nightModeStartTime)
        console.log("NightModeAutomationService: Raw end time from SessionData:", SessionData.nightModeEndTime)
        console.log("NightModeAutomationService: Using start time:", startTime)
        console.log("NightModeAutomationService: Using end time:", endTime)
        
        const startParts = startTime.split(":")
        const endParts = endTime.split(":")
        
        const startMinutes = parseInt(startParts[0]) * 60 + parseInt(startParts[1])
        const endMinutes = parseInt(endParts[0]) * 60 + parseInt(endParts[1])

        let shouldBeNight = false
        
        if (startMinutes > endMinutes) {
            // Crosses midnight (e.g., 20:00 to 06:00)
            shouldBeNight = (currentTime >= startMinutes) || (currentTime < endMinutes)
            console.log("NightModeAutomationService: Time range crosses midnight")
        } else {
            // Same day (e.g., 16:00 to 18:36)
            shouldBeNight = (currentTime >= startMinutes) && (currentTime < endMinutes)
            console.log("NightModeAutomationService: Time range within same day")
        }

        console.log(`NightModeAutomationService: === TIME CALCULATION ===`)
        console.log(`NightModeAutomationService: Current: ${currentHour}:${currentMinute.toString().padStart(2, '0')} (${currentTime} minutes)`)
        console.log(`NightModeAutomationService: Range: ${startTime} (${startMinutes} minutes) to ${endTime} (${endMinutes} minutes)`)
        console.log(`NightModeAutomationService: Should be night: ${shouldBeNight}`)
        console.log(`NightModeAutomationService: Current isAutomaticNightTime: ${isAutomaticNightTime}`)

        if (shouldBeNight !== isAutomaticNightTime) {
            isAutomaticNightTime = shouldBeNight
            console.log("NightModeAutomationService: *** NIGHT TIME STATUS CHANGED TO:", shouldBeNight, "***")
            
            if (shouldBeNight) {
                console.log("NightModeAutomationService: >>> ACTIVATING NIGHT MODE <<<")
                requestNightModeActivation()
            } else {
                console.log("NightModeAutomationService: >>> DEACTIVATING NIGHT MODE <<<")
                requestNightModeDeactivation()
            }
        } else {
            console.log("NightModeAutomationService: No change needed, isAutomaticNightTime already:", isAutomaticNightTime)
        }
        console.log("NightModeAutomationService: === checkTimeBasedMode END ===")
    }

    function requestNightModeActivation() {
        console.log("NightModeAutomationService: Requesting night mode activation")
        const temperature = SessionData.nightModeTemperature || 4500
        console.log("NightModeAutomationService: Using temperature:", temperature + "K")
        
        // Stop process first, change command, then start
        if (gammaStepProcess.running) {
            gammaStepProcess.running = false
        }
        
        // For time-based mode, use continuous process like location mode
        if (SessionData.nightModeAutoMode === "time") {
            gammaStepProcess.processType = "automation"  // Use automation type for continuous process
        } else {
            gammaStepProcess.processType = "activate"    // Keep activate for other modes
        }
        
        gammaStepProcess.command = [
            "gammastep", 
            "-m", "wayland", 
            "-O", String(temperature)
            // This runs continuously, no timeout needed
        ]
        console.log("NightModeAutomationService: Running gamma command:", gammaStepProcess.command.join(" "))
        gammaStepProcess.running = true
        
        // Only update SessionData manual toggle if we're in automation mode
        // This prevents automation from interfering with manual UI settings
        if (SessionData.nightModeAutoEnabled && SessionData.nightModeAutoMode !== "manual") {
            console.log("NightModeAutomationService: Updating SessionData nightModeEnabled to true (automation mode)")
            SessionData.setNightModeEnabled(true)
        } else {
            console.log("NightModeAutomationService: Not updating SessionData (manual mode or automation disabled)")
        }
    }

    function requestNightModeDeactivation() {
        console.log("NightModeAutomationService: Requesting night mode deactivation")
        
        // Always stop any running process first
        if (gammaStepProcess.running) {
            console.log("NightModeAutomationService: Stopping current gamma process")
            gammaStepProcess.running = false
        }
        
        // For time-based mode, we need to explicitly reset gamma
        if (SessionData.nightModeAutoMode === "time") {
            console.log("NightModeAutomationService: Time-based deactivation - resetting gamma to normal")
            // Use automation type for continuous reset process (no timeout)
            gammaStepProcess.processType = "automation"
            gammaStepProcess.command = [
                "gammastep", 
                "-m", "wayland", 
                "-O", "6500"
                // This will run continuously to maintain normal temperature
            ]
            gammaStepProcess.running = true
        } else {
            // For other modes, use the reset approach with timeout protection
            gammaStepProcess.processType = "reset"
            gammaStepProcess.command = [
                "gammastep", 
                "-m", "wayland", 
                "-O", "6500"
            ]
            gammaStepProcess.running = true
        }
        
        // Only update SessionData manual toggle if we're in automation mode
        // This prevents automation from interfering with manual UI settings
        if (SessionData.nightModeAutoEnabled && SessionData.nightModeAutoMode !== "manual") {
            console.log("NightModeAutomationService: Updating SessionData nightModeEnabled to false (automation mode)")
            SessionData.setNightModeEnabled(false)
        } else {
            console.log("NightModeAutomationService: Not updating SessionData (manual mode or automation disabled)")
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
        console.log("NightModeAutomationService: === CLEARING LOCATION COORDINATES ===")
        console.log("NightModeAutomationService: Before - service lat:", latitude, "lng:", longitude)
        console.log("NightModeAutomationService: Before - SessionData lat:", SessionData.latitude, "lng:", SessionData.longitude)
        
        // Clear local service coordinates
        latitude = 0.0
        longitude = 0.0
        currentLocation = ""
        
        // Update SessionData to reflect cleared coordinates  
        SessionData.setLatitude(0.0)
        SessionData.setLongitude(0.0)
        
        console.log("NightModeAutomationService: After clearing - service lat:", latitude, "lng:", longitude)
        console.log("NightModeAutomationService: After clearing - SessionData lat:", SessionData.latitude, "lng:", SessionData.longitude)
        
        // Force SessionData to save changes
        SessionData.saveSettings()
        
        console.log("NightModeAutomationService: Settings saved")
        console.log("NightModeAutomationService: Current automation mode:", SessionData.nightModeAutoMode)
        console.log("NightModeAutomationService: Automation enabled:", SessionData.nightModeAutoEnabled)
        
        // If location mode is active, restart it (will fallback to provider or time-based)
        if (SessionData.nightModeAutoEnabled && SessionData.nightModeAutoMode === "location") {
            console.log("NightModeAutomationService: Restarting location automation after clearing coordinates")
            startLocationBasedMode()
        } else {
            console.log("NightModeAutomationService: Not in location mode, coordinates cleared but automation not restarted")
        }
        
        console.log("NightModeAutomationService: === LOCATION CLEARING COMPLETE ===")
    }

    function debugLocationMode() {
        console.log("=== DEBUG LOCATION MODE ===")
        console.log("Manual coordinates - lat:", latitude, "lng:", longitude)
        console.log("SessionData coordinates - lat:", SessionData.latitude, "lng:", SessionData.longitude)
        console.log("Current location string:", currentLocation)
        console.log("Location providers available:", locationProviderAvailable)
        console.log("Available providers:", availableProviders)
        console.log("Current provider:", currentProvider)
        console.log("Auto enabled:", SessionData.nightModeAutoEnabled)
        console.log("Auto mode:", SessionData.nightModeAutoMode)
        console.log("Temperature:", SessionData.nightModeTemperature + "K")
        console.log("gammaStepProcess running:", gammaStepProcess.running)
        console.log("gammaStepProcess type:", gammaStepProcess.processType)
        console.log("gammaStepProcess command:", gammaStepProcess.command)
        
        // Force location mode test if enabled
        if (SessionData.nightModeAutoMode === "location") {
            console.log("Forcing startLocationBasedMode()...")
            startLocationBasedMode()
        }
        console.log("=== END DEBUG LOCATION MODE ===")
    }

    function updateFromSessionData() {
        console.log("NightModeAutomationService: Updating from SessionData - lat:", SessionData.latitude, "lng:", SessionData.longitude)
        
        // Only update coordinates if they're non-zero (user has set manual coordinates)
        // If they're 0.0, leave them cleared to allow automatic location detection
        if (SessionData.latitude !== 0.0 && SessionData.longitude !== 0.0) {
            console.log("NightModeAutomationService: Loading manual coordinates from SessionData")
            setLocation(SessionData.latitude, SessionData.longitude)
        } else {
            console.log("NightModeAutomationService: No manual coordinates in SessionData, keeping coordinates cleared for auto-detection")
            latitude = 0.0
            longitude = 0.0
            currentLocation = ""
        }
    }

    function detectLocationProviders() {
        locationProviderDetectionProcess.running = true
    }

    function testAutomationNow() {
        console.log("NightModeAutomationService: Manual test triggered")
        console.log("NightModeAutomationService: Current settings - autoEnabled:", SessionData.nightModeAutoEnabled, "mode:", SessionData.nightModeAutoMode)
        console.log("NightModeAutomationService: Time range:", SessionData.nightModeStartTime, "to", SessionData.nightModeEndTime)
        console.log("NightModeAutomationService: Temperature:", SessionData.nightModeTemperature + "K")
        
        if (SessionData.nightModeAutoMode === "time") {
            console.log("NightModeAutomationService: Testing time-based mode now...")
            checkTimeBasedMode()
        } else if (SessionData.nightModeAutoMode === "location") {
            console.log("NightModeAutomationService: Location mode - coordinates:", latitude, longitude)
        }
    }

    function manualNightModeTest() {
        console.log("NightModeAutomationService: Manual night mode test - forcing activation")
        const temperature = SessionData.nightModeTemperature || 4500
        
        if (gammaStepProcess.running) {
            console.log("NightModeAutomationService: Stopping existing process first...")
            gammaStepProcess.running = false
        }
        
        gammaStepProcess.processType = "test"
        gammaStepProcess.command = [
            "gammastep", 
            "-m", "wayland", 
            "-O", String(temperature)
            // Removed -P flag to prevent hanging
        ]
        console.log("NightModeAutomationService: Test gamma command:", gammaStepProcess.command.join(" "))
        gammaStepProcess.running = true
        
        // Use the existing timer approach
        testFeedbackTimer.interval = 2000
        testFeedbackTimer.feedbackMessage = "NightModeAutomationService: Night mode test command sent. Check if screen temperature changed."
        testFeedbackTimer.start()
    }

    function manualResetTest() {
        console.log("NightModeAutomationService: Manual reset test - forcing reset to 6500K")
        
        if (gammaStepProcess.running) {
            console.log("NightModeAutomationService: Stopping existing process first...")
            gammaStepProcess.running = false
        }
        
        gammaStepProcess.processType = "test"
        gammaStepProcess.command = [
            "gammastep", 
            "-m", "wayland", 
            "-O", "6500"
            // Removed -P flag to prevent hanging
        ]
        console.log("NightModeAutomationService: Test reset command:", gammaStepProcess.command.join(" "))
        gammaStepProcess.running = true
        
        // Use the existing timer approach
        testFeedbackTimer.interval = 2000
        testFeedbackTimer.feedbackMessage = "NightModeAutomationService: Reset test command sent. Screen should return to normal temperature."
        testFeedbackTimer.start()
    }

    Timer {
        id: automationTimer
        interval: 60000
        running: false
        repeat: true
        onTriggered: {
            console.log("NightModeAutomationService: *** AUTOMATION TIMER FIRED ***", new Date().toLocaleTimeString())
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
        id: pkillProcess
        command: ["pkill", "gammastep"]
        running: false
        
        onExited: function(exitCode) {
            console.log("NightModeAutomationService: Cleaned up straggling gammastep processes")
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
                
                // Start automation now that Gammastep is confirmed available
                if (SessionData.nightModeAutoEnabled) {
                    console.log("NightModeAutomationService: Starting automation after confirming Gammastep availability")
                    startAutomation()
                }
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
                    
                    console.log("NightModeAutomationService: Parsed providers:", providers)
                    console.log("NightModeAutomationService: Location provider available:", locationProviderAvailable)
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
        id: geoclueTestProcess
        running: false
        
        onExited: function(exitCode) {
            console.log("NightModeAutomationService: Geoclue2 test exited with code:", exitCode)
            
            if (exitCode === 0) {
                console.log("NightModeAutomationService: Geoclue2 working, starting location automation")
                // Start the actual location automation
                const temperature = SessionData.nightModeTemperature || 4500
                const dayTemp = 6500
                
                gammaStepProcess.processType = "automation"
                gammaStepProcess.command = [
                    "gammastep", 
                    "-m", "wayland",
                    "-l", "geoclue2",
                    "-t", `${dayTemp}:${temperature}`,
                    "-v"
                ]
                gammaStepProcess.running = true
                locationTimer.start()
            } else {
                console.warn(`NightModeAutomationService: Geoclue2 test failed with exit code ${exitCode}, falling back to time-based mode`)
                if (exitCode === 124) {
                    console.warn("NightModeAutomationService: Geoclue2 timed out - likely no location services available")
                } else if (exitCode === 15) {
                    console.warn("NightModeAutomationService: Geoclue2 terminated - permission or service issues")
                }
                
                // Fallback to time-based mode
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
            onStreamFinished: {
                if (text.trim()) {
                    console.log("NightModeAutomationService: Gammastep stdout:", text.trim())
                }
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    console.warn("NightModeAutomationService: Gammastep stderr:", text.trim())
                }
            }
        }
        
        onRunningChanged: {
            if (running) {
                // Start timeout only for one-shot commands, not continuous location automation
                if (processType !== "automation") {
                    processTimeoutTimer.start()
                }
            } else {
                // Stop timeout when process ends
                processTimeoutTimer.stop()
            }
        }
        
        onExited: function(exitCode) {
            console.log(`NightModeAutomationService: Process ${processType} exited with code:`, exitCode)
            processTimeoutTimer.stop() // Ensure timeout is stopped
            
            if (exitCode !== 0) {
                switch(processType) {
                    case "automation":
                        if (SessionData.nightModeAutoEnabled && SessionData.nightModeAutoMode === "location") {
                            console.warn("NightModeAutomationService: Location-based automation failed, exit code:", exitCode)
                            if (exitCode === 15 || exitCode === 124) {
                                console.warn("NightModeAutomationService: Location service issues detected, falling back to time-based mode")
                                SessionData.setNightModeAutoMode("time")
                                startTimeBasedMode()
                            } else {
                                console.warn("NightModeAutomationService: Attempting to restart location automation in 10 seconds")
                                restartTimer.start()
                            }
                        } else if (SessionData.nightModeAutoEnabled && SessionData.nightModeAutoMode === "time") {
                            console.warn("NightModeAutomationService: Time-based automation process exited unexpectedly, restarting...")
                            restartTimer.start()
                        }
                        break
                    case "activate":
                        console.warn("NightModeAutomationService: Failed to enable night mode, exit code:", exitCode)
                        break
                    case "reset":
                        console.warn("NightModeAutomationService: Failed to reset gamma, exit code:", exitCode)
                        break
                    case "test":
                        console.warn("NightModeAutomationService: Test command failed, exit code:", exitCode)
                        break
                }
            } else {
                // Success case
                switch(processType) {
                    case "activate":
                        console.log("NightModeAutomationService: Night mode activated successfully")
                        break
                    case "reset":
                        console.log("NightModeAutomationService: Gamma reset successfully")
                        break
                    case "test":
                        console.log("NightModeAutomationService: Test command completed successfully")
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
                console.warn("NightModeAutomationService: Process", gammaStepProcess.processType, "timed out, killing process")
                // Only timeout one-shot commands, not continuous automation
                if (gammaStepProcess.processType !== "automation") {
                    gammaStepProcess.running = false
                } else {
                    console.warn("NightModeAutomationService: Automation process running longer than expected, but not killing continuous process")
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

    Timer {
        id: cleanupTimer
        interval: 1000
        running: false
        repeat: false
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