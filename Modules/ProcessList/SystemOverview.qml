import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Row {
  width: parent.width
  spacing: Theme.spacingM
  Component.onCompleted: {
    SysMonitorService.addRef()
  }
  Component.onDestruction: {
    SysMonitorService.removeRef()
  }

  Rectangle {
    width: (parent.width - Theme.spacingM * 2) / 3
    height: 80
    radius: Theme.cornerRadius
    color: {
      if (SysMonitorService.sortBy === "cpu")
        return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)
      else if (cpuCardMouseArea.containsMouse)
        return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
      else
        return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
    }
    border.color: SysMonitorService.sortBy === "cpu" ? Qt.rgba(Theme.primary.r,
                                                               Theme.primary.g,
                                                               Theme.primary.b,
                                                               0.4) : Qt.rgba(
                                                         Theme.primary.r,
                                                         Theme.primary.g,
                                                         Theme.primary.b, 0.2)
    border.width: SysMonitorService.sortBy === "cpu" ? 2 : 1

    MouseArea {
      id: cpuCardMouseArea

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: SysMonitorService.setSortBy("cpu")
    }

    Column {
      anchors.left: parent.left
      anchors.leftMargin: Theme.spacingM
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      StyledText {
        text: "CPU"
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Medium
        color: SysMonitorService.sortBy === "cpu" ? Theme.primary : Theme.secondary
        opacity: SysMonitorService.sortBy === "cpu" ? 1 : 0.8
      }

      Row {
        spacing: Theme.spacingS

        StyledText {
          text: SysMonitorService.totalCpuUsage.toFixed(1) + "%"
          font.pixelSize: Theme.fontSizeLarge
          font.family: SettingsData.monoFontFamily
          font.weight: Font.Bold
          color: Theme.surfaceText
          anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
          width: 1
          height: 20
          color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g,
                         Theme.surfaceText.b, 0.3)
          anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
          text: {
            if (SysMonitorService.cpuTemperature === undefined
                || SysMonitorService.cpuTemperature === null
                || SysMonitorService.cpuTemperature < 0) {
              return "--°"
            }
            return Math.round(SysMonitorService.cpuTemperature) + "°"
          }
          font.pixelSize: Theme.fontSizeMedium
          font.family: SettingsData.monoFontFamily
          font.weight: Font.Medium
          color: {
            if (SysMonitorService.cpuTemperature > 80)
              return Theme.error
            if (SysMonitorService.cpuTemperature > 60)
              return Theme.warning
            return Theme.surfaceText
          }
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      StyledText {
        text: SysMonitorService.cpuCount + " cores"
        font.pixelSize: Theme.fontSizeSmall
        font.family: SettingsData.monoFontFamily
        color: Theme.surfaceText
        opacity: 0.7
      }
    }

    Behavior on color {
      ColorAnimation {
        duration: Theme.shortDuration
      }
    }

    Behavior on border.color {
      ColorAnimation {
        duration: Theme.shortDuration
      }
    }
  }

  Rectangle {
    width: (parent.width - Theme.spacingM * 2) / 3
    height: 80
    radius: Theme.cornerRadius
    color: {
      if (SysMonitorService.sortBy === "memory")
        return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)
      else if (memoryCardMouseArea.containsMouse)
        return Qt.rgba(Theme.secondary.r, Theme.secondary.g,
                       Theme.secondary.b, 0.12)
      else
        return Qt.rgba(Theme.secondary.r, Theme.secondary.g,
                       Theme.secondary.b, 0.08)
    }
    border.color: SysMonitorService.sortBy === "memory" ? Qt.rgba(
                                                            Theme.primary.r,
                                                            Theme.primary.g,
                                                            Theme.primary.b,
                                                            0.4) : Qt.rgba(
                                                            Theme.secondary.r,
                                                            Theme.secondary.g,
                                                            Theme.secondary.b,
                                                            0.2)
    border.width: SysMonitorService.sortBy === "memory" ? 2 : 1

    MouseArea {
      id: memoryCardMouseArea

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: SysMonitorService.setSortBy("memory")
    }

    Column {
      anchors.left: parent.left
      anchors.leftMargin: Theme.spacingM
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      StyledText {
        text: "Memory"
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Medium
        color: SysMonitorService.sortBy === "memory" ? Theme.primary : Theme.secondary
        opacity: SysMonitorService.sortBy === "memory" ? 1 : 0.8
      }

      Row {
        spacing: Theme.spacingS

        StyledText {
          text: SysMonitorService.formatSystemMemory(
                  SysMonitorService.usedMemoryKB)
          font.pixelSize: Theme.fontSizeLarge
          font.family: SettingsData.monoFontFamily
          font.weight: Font.Bold
          color: Theme.surfaceText
          anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
          width: 1
          height: 20
          color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g,
                         Theme.surfaceText.b, 0.3)
          anchors.verticalCenter: parent.verticalCenter
          visible: SysMonitorService.totalSwapKB > 0
        }

        StyledText {
          text: SysMonitorService.totalSwapKB > 0 ? SysMonitorService.formatSystemMemory(
                                                      SysMonitorService.usedSwapKB) : ""
          font.pixelSize: Theme.fontSizeMedium
          font.family: SettingsData.monoFontFamily
          font.weight: Font.Medium
          color: SysMonitorService.usedSwapKB > 0 ? Theme.warning : Theme.surfaceText
          anchors.verticalCenter: parent.verticalCenter
          visible: SysMonitorService.totalSwapKB > 0
        }
      }

      StyledText {
        text: {
          if (SysMonitorService.totalSwapKB > 0) {
            return "of " + SysMonitorService.formatSystemMemory(
                  SysMonitorService.totalMemoryKB) + " + swap"
          }
          return "of " + SysMonitorService.formatSystemMemory(
                SysMonitorService.totalMemoryKB)
        }
        font.pixelSize: Theme.fontSizeSmall
        font.family: SettingsData.monoFontFamily
        color: Theme.surfaceText
        opacity: 0.7
      }
    }

    Behavior on color {
      ColorAnimation {
        duration: Theme.shortDuration
      }
    }

    Behavior on border.color {
      ColorAnimation {
        duration: Theme.shortDuration
      }
    }
  }

  Rectangle {
    width: (parent.width - Theme.spacingM * 2) / 3
    height: 80
    radius: Theme.cornerRadius
    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                   Theme.surfaceVariant.b, 0.08)
    border.color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                          Theme.surfaceVariant.b, 0.2)
    border.width: 1

    Column {
      anchors.left: parent.left
      anchors.leftMargin: Theme.spacingM
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      StyledText {
        text: "Graphics"
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Medium
        color: Theme.secondary
        opacity: 0.8
      }

      StyledText {
        text: {
          if (!SysMonitorService.availableGpus
              || SysMonitorService.availableGpus.length === 0) {
            return "None"
          }
          if (SysMonitorService.availableGpus.length === 1) {
            var gpu = SysMonitorService.availableGpus[0]
            var temp = gpu.temperature
            var tempText = (temp === undefined || temp === null
                            || temp === 0) ? "--°" : Math.round(temp) + "°"
            return tempText
          }
          // Multiple GPUs - show average temp
          var totalTemp = 0
          var validTemps = 0
          for (var i = 0; i < SysMonitorService.availableGpus.length; i++) {
            var temp = SysMonitorService.availableGpus[i].temperature
            if (temp !== undefined && temp !== null && temp > 0) {
              totalTemp += temp
              validTemps++
            }
          }
          if (validTemps > 0) {
            return Math.round(totalTemp / validTemps) + "°"
          }
          return "--°"
        }
        font.pixelSize: Theme.fontSizeLarge
        font.family: SettingsData.monoFontFamily
        font.weight: Font.Bold
        color: {
          if (!SysMonitorService.availableGpus
              || SysMonitorService.availableGpus.length === 0) {
            return Theme.surfaceText
          }
          if (SysMonitorService.availableGpus.length === 1) {
            var temp = SysMonitorService.availableGpus[0].temperature || 0
            if (temp > 80)
              return Theme.tempDanger
            if (temp > 60)
              return Theme.tempWarning
            return Theme.surfaceText
          }
          // Multiple GPUs - get max temp for coloring
          var maxTemp = 0
          for (var i = 0; i < SysMonitorService.availableGpus.length; i++) {
            var temp = SysMonitorService.availableGpus[i].temperature || 0
            if (temp > maxTemp)
              maxTemp = temp
          }
          if (maxTemp > 80)
            return Theme.tempDanger
          if (maxTemp > 60)
            return Theme.tempWarning
          return Theme.surfaceText
        }
      }

      StyledText {
        text: {
          if (!SysMonitorService.availableGpus
              || SysMonitorService.availableGpus.length === 0) {
            return "No GPUs detected"
          }
          if (SysMonitorService.availableGpus.length === 1) {
            return SysMonitorService.availableGpus[0].driver.toUpperCase()
          }
          return SysMonitorService.availableGpus.length + " GPUs detected"
        }
        font.pixelSize: Theme.fontSizeSmall
        font.family: SettingsData.monoFontFamily
        color: Theme.surfaceText
        opacity: 0.7
      }
    }
  }
}
