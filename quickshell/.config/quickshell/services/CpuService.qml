import QtQuick
import Quickshell.Io

QtObject {
    id: cpu

    property int usage: 0
    property double lastCpuIdle: 0
    property double lastCpuTotal: 0

    property var cpuProc: Process {
        id: cpuProc
        command: ["head", "-1", "/proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var user = parseInt(parts[1]) || 0
                var nice = parseInt(parts[2]) || 0
                var system = parseInt(parts[3]) || 0
                var idle = parseInt(parts[4]) || 0
                var iowait = parseInt(parts[5]) || 0
                var irq = parseInt(parts[6]) || 0
                var softirq = parseInt(parts[7]) || 0

                var total = user + nice + system + idle + iowait + irq + softirq
                var idleTime = idle + iowait

                if (cpu.lastCpuTotal > 0) {
                    var totalDiff = total - cpu.lastCpuTotal
                    var idleDiff = idleTime - cpu.lastCpuIdle
                    if (totalDiff > 0) {
                        cpu.usage = Math.round(100 * (totalDiff - idleDiff) / totalDiff)
                    }
                }
                cpu.lastCpuTotal = total
                cpu.lastCpuIdle = idleTime
            }
        }
    }

    property var pollTimer: Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: cpuProc.running = true
    }

    Component.onCompleted: cpuProc.running = true
}
