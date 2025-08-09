pragma Singleton

pragma ComponentBehavior

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import qs.Common

Singleton {
  id: root

  readonly property string shellDir: Qt.resolvedUrl(".").toString().replace(
                                       "file://", "").replace("/Services/", "")

  property int refCount: 0
  property int updateInterval: refCount > 0 ? 3000 : 30000
  property int maxProcesses: 100
  property bool isUpdating: false
  property bool staticDataInitialized: false

  property var processes: []
  property string sortBy: "cpu"
  property bool sortDescending: true
  property var lastProcTicks: ({})
  property real lastTotalJiffies: -1

  property real cpuUsage: 0
  property real totalCpuUsage: 0
  property int cpuCores: 1
  property int cpuCount: 1
  property string cpuModel: ""
  property real cpuFrequency: 0
  property real cpuTemperature: -1
  property var perCoreCpuUsage: []

  property var lastCpuStats: null
  property var lastPerCoreStats: null

  property real memoryUsage: 0
  property real totalMemoryMB: 0
  property real usedMemoryMB: 0
  property real freeMemoryMB: 0
  property real availableMemoryMB: 0
  property int totalMemoryKB: 0
  property int usedMemoryKB: 0
  property int totalSwapKB: 0
  property int usedSwapKB: 0

  property real networkRxRate: 0
  property real networkTxRate: 0
  property var lastNetworkStats: null

  property real diskReadRate: 0
  property real diskWriteRate: 0
  property var lastDiskStats: null
  property var diskMounts: []

  property int historySize: 60
  property var cpuHistory: []
  property var memoryHistory: []
  property var networkHistory: ({
                                  "rx": [],
                                  "tx": []
                                })
  property var diskHistory: ({
                               "read": [],
                               "write": []
                             })

  property string kernelVersion: ""
  property string distribution: ""
  property string hostname: ""
  property string architecture: ""
  property string loadAverage: ""
  property int processCount: 0
  property int threadCount: 0
  property string bootTime: ""
  property string motherboard: ""
  property string biosVersion: ""
  property var availableGpus: []

  // Check if any GPU temperature widgets are configured
  function hasGpuTempWidgets() {
    const allWidgets = [...(SettingsData.topBarLeftWidgets || []), 
                       ...(SettingsData.topBarCenterWidgets || []), 
                       ...(SettingsData.topBarRightWidgets || [])]
    
    return allWidgets.some(widget => {
      const widgetId = typeof widget === "string" ? widget : widget.id
      const widgetEnabled = typeof widget === "string" ? true : (widget.enabled !== false)
      return widgetId === "gpuTemp" && widgetEnabled
    })
  }
  
  // Check if any NVIDIA GPU temperature widgets are configured
  function hasNvidiaGpuTempWidgets() {
    if (!hasGpuTempWidgets()) return false
    
    const allWidgets = [...(SettingsData.topBarLeftWidgets || []), 
                       ...(SettingsData.topBarCenterWidgets || []), 
                       ...(SettingsData.topBarRightWidgets || [])]
    
    return allWidgets.some(widget => {
      const widgetId = typeof widget === "string" ? widget : widget.id
      const widgetEnabled = typeof widget === "string" ? true : (widget.enabled !== false)
      if (widgetId !== "gpuTemp" || !widgetEnabled) return false
      
      const selectedGpuIndex = typeof widget === "string" ? 0 : (widget.selectedGpuIndex || 0)
      if (availableGpus && availableGpus[selectedGpuIndex]) {
        return availableGpus[selectedGpuIndex].driver === "nvidia"
      }
      return false
    })
  }
  
  // Check if any non-NVIDIA GPU temperature widgets are configured
  function hasNonNvidiaGpuTempWidgets() {
    if (!hasGpuTempWidgets()) return false
    
    const allWidgets = [...(SettingsData.topBarLeftWidgets || []), 
                       ...(SettingsData.topBarCenterWidgets || []), 
                       ...(SettingsData.topBarRightWidgets || [])]
    
    return allWidgets.some(widget => {
      const widgetId = typeof widget === "string" ? widget : widget.id
      const widgetEnabled = typeof widget === "string" ? true : (widget.enabled !== false)
      if (widgetId !== "gpuTemp" || !widgetEnabled) return false
      
      const selectedGpuIndex = typeof widget === "string" ? 0 : (widget.selectedGpuIndex || 0)
      if (availableGpus && availableGpus[selectedGpuIndex]) {
        return availableGpus[selectedGpuIndex].driver !== "nvidia"
      }
      return true  // Default to true if GPU not found yet (static data might not be loaded)
    })
  }

  function addRef() {
    refCount++
    if (refCount === 1) {
      if (!staticDataInitialized) {
        initializeStaticData()
      }
      updateAllStats()
    }
  }

  function removeRef() {
    refCount = Math.max(0, refCount - 1)
  }

  function initializeStaticData() {
    if (!staticDataInitialized) {
      staticDataInitialized = true
      staticDataProcess.running = true
    }
  }

  function updateAllStats() {
    if (refCount > 0) {
      isUpdating = true
      dynamicStatsProcess.running = true
    }
  }

  function setSortBy(newSortBy) {
    if (newSortBy !== sortBy) {
      sortBy = newSortBy
      sortProcessesInPlace()
    }
  }

  function toggleSortOrder() {
    sortDescending = !sortDescending
    sortProcessesInPlace()
  }

  function sortProcessesInPlace() {
    if (processes.length === 0)
      return
    const sortedProcesses = [...processes]

    sortedProcesses.sort((a, b) => {
                           let aVal, bVal

                           switch (sortBy) {
                             case "cpu":
                             aVal = parseFloat(a.cpu) || 0
                             bVal = parseFloat(b.cpu) || 0
                             break
                             case "memory":
                             aVal = parseFloat(a.memoryPercent) || 0
                             bVal = parseFloat(b.memoryPercent) || 0
                             break
                             case "name":
                             aVal = a.command || ""
                             bVal = b.command || ""
                             break
                             case "pid":
                             aVal = parseInt(a.pid) || 0
                             bVal = parseInt(b.pid) || 0
                             break
                             default:
                             aVal = parseFloat(a.cpu) || 0
                             bVal = parseFloat(b.cpu) || 0
                           }

                           if (typeof aVal === "string") {
                             return sortDescending ? bVal.localeCompare(
                                                       aVal) : aVal.localeCompare(
                                                       bVal)
                           } else {
                             return sortDescending ? bVal - aVal : aVal - bVal
                           }
                         })

    processes = sortedProcesses
  }

  function killProcess(pid) {
    if (pid > 0) {
      Quickshell.execDetached("kill", [pid.toString()])
    }
  }

  function addToHistory(array, value) {
    array.push(value)
    if (array.length > historySize)
      array.shift()
  }

  function calculateCpuUsage(currentStats, lastStats) {
    if (!lastStats || !currentStats || currentStats.length < 4) {
      return 0
    }

    const currentTotal = currentStats.reduce((sum, val) => sum + val, 0)
    const lastTotal = lastStats.reduce((sum, val) => sum + val, 0)

    const totalDiff = currentTotal - lastTotal
    if (totalDiff <= 0)
      return 0

    const currentIdle = currentStats[3]
    const lastIdle = lastStats[3]
    const idleDiff = currentIdle - lastIdle

    const usedDiff = totalDiff - idleDiff
    return Math.max(0, Math.min(100, (usedDiff / totalDiff) * 100))
  }

  function parseStaticData(data) {
    if (data.cpu) {
      cpuCores = data.cpu.count || 1
      cpuCount = data.cpu.count || 1
      cpuModel = data.cpu.model || ""
    }

    if (data.system) {
      kernelVersion = data.system.kernel || ""
      distribution = data.system.distro || ""
      hostname = data.system.hostname || ""
      architecture = data.system.arch || ""
      motherboard = data.system.motherboard || ""
      biosVersion = data.system.bios || ""
    }

    if (data.gpus) {
      const gpuList = []
      for (const gpu of data.gpus) {
        // Parse the display name and PCI ID from rawLine
        let displayName = ""
        let fullName = ""
        let pciId = ""
        
        if (gpu.rawLine) {
          // Extract PCI ID [vvvv:dddd]
          const pciMatch = gpu.rawLine.match(/\[([0-9a-f]{4}:[0-9a-f]{4})\]/i)
          if (pciMatch) {
            pciId = pciMatch[1]
          }
          
          // Remove BDF and class prefix
          let s = gpu.rawLine.replace(/^[^:]+: /, "")
          // Remove PCI ID [vvvv:dddd] and everything after
          s = s.replace(/\[[0-9a-f]{4}:[0-9a-f]{4}\].*$/i, "")
          
          // Try to extract text after last ']'
          const afterBracket = s.match(/\]\s*([^\[]+)$/)
          if (afterBracket && afterBracket[1].trim()) {
            displayName = afterBracket[1].trim()
          } else {
            // Try to get last bracketed text
            const lastBracket = s.match(/\[([^\]]+)\]([^\[]*$)/)
            if (lastBracket) {
              displayName = lastBracket[1]
            } else {
              displayName = s
            }
          }
          
          // Remove vendor prefixes
          displayName = displayName
            .replace(/^NVIDIA Corporation\s+/i, "")
            .replace(/^NVIDIA\s+/i, "")
            .replace(/^Advanced Micro Devices, Inc\.\s+/i, "")
            .replace(/^AMD\/ATI\s+/i, "")
            .replace(/^AMD\s+/i, "")
            .replace(/^ATI\s+/i, "")
            .replace(/^Intel Corporation\s+/i, "")
            .replace(/^Intel\s+/i, "")
            .trim()
        } else if (gpu.rawLine && gpu.rawLine.startsWith("NVIDIA")) {
          // nvidia-smi fallback case
          displayName = gpu.rawLine.replace(/^NVIDIA\s+/, "")
        } else {
          displayName = "Unknown"
        }
        
        // Build full name with vendor prefix
        switch(gpu.vendor) {
          case "NVIDIA": fullName = "NVIDIA " + displayName; break
          case "AMD": fullName = "AMD " + displayName; break
          case "Intel": fullName = "Intel " + displayName; break
          default: fullName = displayName
        }
        
        gpuList.push({
          "driver": gpu.driver,
          "vendor": gpu.vendor,
          "displayName": displayName,
          "fullName": fullName,
          "pciId": pciId,
          "temperature": 0,
          "hwmon": "unknown"
        })
      }
      availableGpus = gpuList
    }
  }

  function parseDynamicStats(data) {
    updateGpuTemperatures(data.gputemps || [])
    parseUnifiedStats(JSON.stringify(data))
  }

  function updateGpuTemperatures(tempData) {
    if (availableGpus.length === 0 || tempData.length === 0) return
    
    const updatedGpus = []
    for (let i = 0; i < availableGpus.length; i++) {
      const gpu = availableGpus[i]
      const tempInfo = tempData.find(t => t.driver === gpu.driver)
      if (tempInfo) {
        updatedGpus.push({
          "driver": gpu.driver,
          "vendor": gpu.vendor,
          "displayName": gpu.displayName,
          "fullName": gpu.fullName,
          "pciId": gpu.pciId,
          "temperature": tempInfo.temperature || 0,
          "hwmon": tempInfo.hwmon || "unknown"
        })
      } else {
        updatedGpus.push({
          "driver": gpu.driver,
          "vendor": gpu.vendor,
          "displayName": gpu.displayName,
          "fullName": gpu.fullName,
          "pciId": gpu.pciId,
          "temperature": gpu.temperature || 0,
          "hwmon": gpu.hwmon || "unknown"
        })
      }
    }
    availableGpus = updatedGpus
  }

  function parseUnifiedStats(text) {
    function num(x) {
      return (typeof x === "number" && !isNaN(x)) ? x : 0
    }

    let data
    try {
      data = JSON.parse(text)
    } catch (error) {
      isUpdating = false
      return
    }

    if (data.memory) {
      const m = data.memory
      totalMemoryKB = num(m.total)
      const free = num(m.free)
      const buf = num(m.buffers)
      const cached = num(m.cached)
      const shared = num(m.shared)
      usedMemoryKB = totalMemoryKB - free - buf - cached
      totalSwapKB = num(m.swaptotal)
      usedSwapKB = num(m.swaptotal) - num(m.swapfree)
      totalMemoryMB = totalMemoryKB / 1024
      usedMemoryMB = usedMemoryKB / 1024
      freeMemoryMB = (totalMemoryKB - usedMemoryKB) / 1024
      availableMemoryMB = num(
            m.available) ? num(
                             m.available) / 1024 : (free + buf + cached) / 1024
      memoryUsage = totalMemoryKB > 0 ? (usedMemoryKB / totalMemoryKB) * 100 : 0
    }

    if (data.cpu) {
      cpuFrequency = data.cpu.frequency || 0
      cpuTemperature = data.cpu.temperature || 0

      if (data.cpu.total && data.cpu.total.length >= 8) {
        const currentStats = data.cpu.total
        const usage = calculateCpuUsage(currentStats, lastCpuStats)
        cpuUsage = usage
        totalCpuUsage = usage
        lastCpuStats = [...currentStats]
      }

      if (data.cpu.cores) {
        const coreUsages = []
        for (var i = 0; i < data.cpu.cores.length; i++) {
          const currentCoreStats = data.cpu.cores[i]
          if (currentCoreStats && currentCoreStats.length >= 8) {
            let lastCoreStats = null
            if (lastPerCoreStats && lastPerCoreStats[i]) {
              lastCoreStats = lastPerCoreStats[i]
            }

            const usage = calculateCpuUsage(currentCoreStats, lastCoreStats)
            coreUsages.push(usage)
          }
        }

        if (JSON.stringify(perCoreCpuUsage) !== JSON.stringify(coreUsages)) {
          perCoreCpuUsage = coreUsages
        }

        lastPerCoreStats = data.cpu.cores.map(core => [...core])
      }
    }

    if (data.network) {
      let totalRx = 0
      let totalTx = 0
      for (const iface of data.network) {
        totalRx += iface.rx
        totalTx += iface.tx
      }
      if (lastNetworkStats) {
        const timeDiff = updateInterval / 1000
        const rxDiff = totalRx - lastNetworkStats.rx
        const txDiff = totalTx - lastNetworkStats.tx
        networkRxRate = Math.max(0, rxDiff / timeDiff)
        networkTxRate = Math.max(0, txDiff / timeDiff)
        addToHistory(networkHistory.rx, networkRxRate / 1024)
        addToHistory(networkHistory.tx, networkTxRate / 1024)
      }
      lastNetworkStats = {
        "rx": totalRx,
        "tx": totalTx
      }
    }

    if (data.disk) {
      let totalRead = 0
      let totalWrite = 0
      for (const disk of data.disk) {
        totalRead += disk.read * 512
        totalWrite += disk.write * 512
      }
      if (lastDiskStats) {
        const timeDiff = updateInterval / 1000
        const readDiff = totalRead - lastDiskStats.read
        const writeDiff = totalWrite - lastDiskStats.write
        diskReadRate = Math.max(0, readDiff / timeDiff)
        diskWriteRate = Math.max(0, writeDiff / timeDiff)
        addToHistory(diskHistory.read, diskReadRate / (1024 * 1024))
        addToHistory(diskHistory.write, diskWriteRate / (1024 * 1024))
      }
      lastDiskStats = {
        "read": totalRead,
        "write": totalWrite
      }
    }

    let totalDiff = 0
    if (data.cpu && data.cpu.total && data.cpu.total.length >= 4) {
      const currentTotal = data.cpu.total.reduce((s, v) => s + v, 0)
      if (lastTotalJiffies > 0)
        totalDiff = currentTotal - lastTotalJiffies
      lastTotalJiffies = currentTotal
    }

    if (data.processes) {
      const newProcesses = []
      for (const proc of data.processes) {
        const pid = proc.pid
        const pticks = Number(proc.pticks) || 0
        const prev = lastProcTicks[pid] ?? null
        let cpuShare = 0

        if (prev !== null && totalDiff > 0) {
          // Per share all CPUs (matches gnome system monitor)
          //cpuShare = 100 * Math.max(0, pticks - prev) / totalDiff

          // per-share per-core
          cpuShare = 100 * cpuCores * Math.max(0, pticks - prev) / totalDiff
        }

        lastProcTicks[pid] = pticks // update cache

        newProcesses.push({
                            "pid": pid,
                            "ppid": proc.ppid,
                            "cpu": cpuShare,
                            "memoryPercent": proc.pssPercent
                                             ?? proc.memoryPercent,
                            "memoryKB": proc.pssKB ?? proc.memoryKB,
                            "command": proc.command,
                            "fullCommand": proc.fullCommand,
                            "displayName": (proc.command && proc.command.length
                                            > 15) ? proc.command.substring(
                                                      0,
                                                      15) + "..." : proc.command
                          })
      }
      processes = newProcesses
      sortProcessesInPlace()
    }

    if (data.system) {
      loadAverage = data.system.loadavg || ""
      processCount = data.system.processes || 0
      threadCount = data.system.threads || 0
      bootTime = data.system.boottime || ""
    }

    if (data.diskmounts) {
      diskMounts = data.diskmounts
    }


    addToHistory(cpuHistory, cpuUsage)
    addToHistory(memoryHistory, memoryUsage)

    isUpdating = false
  }

  function getProcessIcon(command) {
    const cmd = command.toLowerCase()
    if (cmd.includes("firefox") || cmd.includes("chrome") || cmd.includes(
          "browser"))
      return "web"
    if (cmd.includes("code") || cmd.includes("editor") || cmd.includes("vim"))
      return "code"
    if (cmd.includes("terminal") || cmd.includes("bash") || cmd.includes("zsh"))
      return "terminal"
    if (cmd.includes("music") || cmd.includes("audio") || cmd.includes(
          "spotify"))
      return "music_note"
    if (cmd.includes("video") || cmd.includes("vlc") || cmd.includes("mpv"))
      return "play_circle"
    if (cmd.includes("systemd") || cmd.includes("kernel") || cmd.includes(
          "kthread"))
      return "settings"
    return "memory"
  }

  function formatCpuUsage(cpu) {
    return (cpu || 0).toFixed(1) + "%"
  }

  function formatMemoryUsage(memoryKB) {
    const mem = memoryKB || 0
    if (mem < 1024)
      return mem.toFixed(0) + " KB"
    else if (mem < 1024 * 1024)
      return (mem / 1024).toFixed(1) + " MB"
    else
      return (mem / (1024 * 1024)).toFixed(1) + " GB"
  }

  function formatSystemMemory(memoryKB) {
    const mem = memoryKB || 0
    if (mem < 1024 * 1024)
      return (mem / 1024).toFixed(0) + " MB"
    else
      return (mem / (1024 * 1024)).toFixed(1) + " GB"
  }

  Timer {
    id: updateTimer
    interval: root.updateInterval
    running: root.refCount > 0
    repeat: true
    triggeredOnStart: true
    onTriggered: root.updateAllStats()
  }

  Process {
    id: staticDataProcess
    command: [root.shellDir + "/sysmon_static.sh"]
    running: false
    onExited: exitCode => {
      if (exitCode !== 0) {
        console.warn("Static data collection failed with exit code:", exitCode)
      }
    }
    stdout: StdioCollector {
      onStreamFinished: {
        if (text.trim()) {
          const fullText = text.trim()
          const lastBraceIndex = fullText.lastIndexOf('}')
          if (lastBraceIndex === -1) {
            console.warn("Invalid static data JSON")
            return
          }
          const jsonText = fullText.substring(0, lastBraceIndex + 1)

          try {
            const data = JSON.parse(jsonText)
            parseStaticData(data)
          } catch (e) {
            console.warn("Failed to parse static data JSON:", e)
            return
          }
        }
      }
    }
  }

  Process {
    id: dynamicStatsProcess
    command: [root.shellDir + "/sysmon_dynamic.sh", root.sortBy, String(root.maxProcesses), root.hasGpuTempWidgets() ? "1" : "0", root.hasNvidiaGpuTempWidgets() ? "1" : "0", root.hasNonNvidiaGpuTempWidgets() ? "1" : "0"]
    running: false
    onExited: exitCode => {
      if (exitCode !== 0) {
        isUpdating = false
      }
    }
    stdout: StdioCollector {
      onStreamFinished: {
        if (text.trim()) {
          const fullText = text.trim()
          const lastBraceIndex = fullText.lastIndexOf('}')
          if (lastBraceIndex === -1) {
            isUpdating = false
            return
          }
          const jsonText = fullText.substring(0, lastBraceIndex + 1)

          try {
            const data = JSON.parse(jsonText)
            parseDynamicStats(data)
          } catch (e) {
            isUpdating = false
            return
          }
        }
      }
    }
  }
}
