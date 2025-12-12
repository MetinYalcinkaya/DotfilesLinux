import QtQuick
import Quickshell.Io

QtObject {
    id: cpu

    property int usage: 0
    property double lastCpuIdle: 0
    property double lastCpuTotal: 0

    function updateFromStat(text) {
        const line = (text || "").split("\n")[0]
        if (!line) return

        const parts = line.trim().split(/\s+/)
        const user = parseInt(parts[1]) || 0
        const nice = parseInt(parts[2]) || 0
        const system = parseInt(parts[3]) || 0
        const idle = parseInt(parts[4]) || 0
        const iowait = parseInt(parts[5]) || 0
        const irq = parseInt(parts[6]) || 0
        const softirq = parseInt(parts[7]) || 0

        const total = user + nice + system + idle + iowait + irq + softirq
        const idleTime = idle + iowait

        if (cpu.lastCpuTotal > 0) {
            const totalDiff = total - cpu.lastCpuTotal
            const idleDiff = idleTime - cpu.lastCpuIdle
            if (totalDiff > 0) {
                cpu.usage = Math.round(100 * (totalDiff - idleDiff) / totalDiff)
            }
        }

        cpu.lastCpuTotal = total
        cpu.lastCpuIdle = idleTime
    }

    readonly property var stat: FileView {
        id: stat
        path: "/proc/stat"

        onLoaded: cpu.updateFromStat(text())
        onLoadFailed: (error) => console.warn("Failed to read /proc/stat:", error)
    }

    readonly property var pollTimer: Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: stat.reload()
    }

    Component.onCompleted: stat.reload()
}
