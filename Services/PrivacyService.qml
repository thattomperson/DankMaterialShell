pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property bool microphoneActive: false
    property bool cameraActive: false
    property bool screensharingActive: false
    
    readonly property bool anyPrivacyActive: microphoneActive || cameraActive || screensharingActive

    readonly property var micSource: AudioService.source
    property var activeMicSources: []
    property var activeCameraSources: []
    property var activeScreenSources: []

    function resetPrivacyStates() {
        root.cameraActive = false;
        root.screensharingActive = false;
        root.microphoneActive = false;
    }

    Process {
        id: portalMonitor
        command: ["bash", "-c", `
            screencast_count=0
            camera_count=0
            microphone_count=0
            
            if command -v lsof >/dev/null 2>&1; then
                video_device_users=$(lsof /dev/video* 2>/dev/null | wc -l || echo "0")
                if [ "$video_device_users" -gt 0 ]; then
                    camera_count=1
                fi
                
                if command -v busctl >/dev/null 2>&1; then
                    mic_access_count=$(busctl --user call org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop org.freedesktop.DBus.Properties Get ss "org.freedesktop.portal.Inhibit" "Inhibited" 2>/dev/null | grep -c "microphone" || echo "0")
                    if [ "$mic_access_count" -gt 0 ]; then
                        microphone_count=1
                    fi
                fi
                
                if [ "$microphone_count" -eq 0 ] && command -v pactl >/dev/null 2>&1; then
                    total_outputs=$(pactl list short source-outputs | wc -l || echo "0")
                    system_outputs=$(pactl list source-outputs | grep -c "media\\.name.*cava" || echo "0")
                    user_outputs=$((total_outputs - system_outputs))
                    if [ "$user_outputs" -gt 0 ]; then
                        microphone_count=1
                    fi
                fi
            fi
            
            if command -v busctl >/dev/null 2>&1; then
                screencast_sessions=$(busctl --user list | grep "org.freedesktop.portal.Session" | wc -l || echo "0")
                if [ "$screencast_sessions" -gt 0 ]; then
                    screencast_count=1
                fi
            fi
            
            if command -v pw-dump >/dev/null 2>&1; then
                active_video_streams=$(pw-dump 2>/dev/null | grep -i "video" | grep -i "state.*running" | wc -l || echo "0")
                if [ "$active_video_streams" -gt 0 ]; then
                    camera_count=1
                fi
                
                active_screen_streams=$(pw-dump 2>/dev/null | grep -i "screen" | grep -i "state.*running" | wc -l || echo "0")
                if [ "$active_screen_streams" -gt 0 ]; then
                    screencast_count=1
                fi
            fi
            
            echo "screencast:$screencast_count"
            echo "camera:$camera_count"
            echo "microphone:$microphone_count"
        `]
        
        stdout: StdioCollector {
            onStreamFinished: {
                root.resetPrivacyStates();
                
                if (text && text.length > 0) {
                    const lines = text.trim().split('\n');
                    let foundScreencast = false;
                    let foundCamera = false;
                    let foundMicrophone = false;
                    
                    for (const line of lines) {
                        if (line.startsWith('screencast:')) {
                            const count = parseInt(line.split(':')[1]) || 0;
                            foundScreencast = foundScreencast || (count > 0);
                        } else if (line.startsWith('camera:')) {
                            const count = parseInt(line.split(':')[1]) || 0;
                            foundCamera = foundCamera || (count > 0);
                        } else if (line.startsWith('microphone:')) {
                            const count = parseInt(line.split(':')[1]) || 0;
                            foundMicrophone = foundMicrophone || (count > 0);
                        }
                    }
                    
                    root.screensharingActive = foundScreencast;
                    root.cameraActive = foundCamera;
                    root.microphoneActive = foundMicrophone;
                } else {
                    root.screensharingActive = false;
                    root.cameraActive = false;
                    root.microphoneActive = false;
                }
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("PrivacyService: Portal monitor process failed with exit code:", exitCode);
            }
        }
    }

    Timer {
        id: privacyMonitor
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            if (!portalMonitor.running) {
                portalMonitor.running = true;
            }
        }
    }

    Component.onCompleted: {
    }

    function getMicrophoneStatus() {
        return microphoneActive ? "active" : "inactive";
    }

    function getCameraStatus() {
        return cameraActive ? "active" : "inactive";  
    }

    function getScreensharingStatus() {
        return screensharingActive ? "active" : "inactive";
    }

    function getPrivacySummary() {
        const active = [];
        if (microphoneActive) active.push("microphone");
        if (cameraActive) active.push("camera");
        if (screensharingActive) active.push("screensharing");
        
        return active.length > 0 ? 
            "Privacy active: " + active.join(", ") : 
            "No privacy concerns detected";
    }
}