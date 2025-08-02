pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string username: ""
    property string fullName: ""
    property string profilePicture: ""
    property string uptime: ""
    property string hostname: ""
    property bool profileAvailable: false

    function getUserInfo() {
        userInfoProcess.running = true;
    }

    function getUptime() {
        uptimeProcess.running = true;
    }

    function refreshUserInfo() {
        getUserInfo();
        getUptime();
    }

    Component.onCompleted: {
        getUserInfo();
        getUptime();
    }

    // Get username and full name
    Process {
        id: userInfoProcess

        command: ["bash", "-c", "echo \"$USER|$(getent passwd $USER | cut -d: -f5 | cut -d, -f1)|$(hostname)\""]
        running: false
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                
                root.username = "User";
                root.fullName = "User";
                root.hostname = "System";
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|");
                if (parts.length >= 3) {
                    root.username = parts[0] || "";
                    root.fullName = parts[1] || parts[0] || "";
                    root.hostname = parts[2] || "";
                    
                }
            }
        }

    }

    // Get system uptime
    Process {
        id: uptimeProcess

        command: ["bash", "-c", "uptime -p | sed 's/up //'"]
        running: false
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                
                root.uptime = "Unknown";
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                root.uptime = text.trim() || "Unknown";
            }
        }

    } 
}
