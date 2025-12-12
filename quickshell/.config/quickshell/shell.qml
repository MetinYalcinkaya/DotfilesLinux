//@ pragma UseQApplication
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    // catppuccin colors
    property color colorBase: "#1e1e2e"
    property color colorText: "#cdd6f4"
    property color colorOverlay: "#6c7086"
    property color colorTeal: "#94e2d5"
    property color colorMauve: "#cba6f7"
    property color colorRed: "#f38ba8"
    property color colorYellow: "#f9e2af"
    property color colorBlue: "#89b4fa"
    property color colorGreen: "#a6e3a1"


    // font
    property string fontFamily: "Berkeley Mono"
    property int fontSize: 18

    // system info properties
    property int cpuUsage: 0
    property int memUsage: 0
    property string activeWindow: "Window"
    property string currentLayout: "Tiled"

    // cpu properties
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0

    // media property
    property string spotifyText: ""
    property bool isSpotifyPlaying: false

    // cpu usage
    Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]
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

                if (lastCpuTotal > 0) {
                    var totalDiff = total - lastCpuTotal
                    var idleDiff = idleTime - lastCpuIdle
                    if (totalDiff > 0) {
                        cpuUsage = Math.round(100 * (totalDiff - idleDiff) / totalDiff)
                    }
                }
                lastCpuTotal = total
                lastCpuIdle = idleTime
            }
        }
        Component.onCompleted: running = true
    }

    // mem usage
    Process {
        id: memProc
        command: ["sh", "-c", "free | grep Mem"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var total = parseInt(parts[1]) || 1
                var used = parseInt(parts[2]) || 0
                memUsage = Math.round(100 * used / total)
            }
        }
        Component.onCompleted: running = true
    }

    // active window title
    Process {
        id: windowProc
        command: ["sh", "-c", "hyprctl activewindow -j | jq -r '.title // empty'"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) {
                    activeWindow = data.trim()
                }
            }
        }
        Component.onCompleted: running = true
    }

    // current layout (Hyprland: dwindle/master/floating)
    Process {
        id: layoutProc
        command: ["sh", "-c", "hyprctl activewindow -j | jq -r 'if .floating then \"Floating\" elif .fullscreen == 1 then \"Fullscreen\" else \"Tiled\" end'"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) {
                    currentLayout = data.trim()
                }
            }
        }
        Component.onCompleted: running = true
    }

    // spotify process
    Process {
        id: spotifyProc
        command: ["sh", "-c", "if [ \"$(playerctl -p spotify status 2>/dev/null)\" = \"Playing\" ]; then playerctl -p spotify metadata --format '{{ title }} - {{ artist }}'; else echo ''; fi"]
        stdout: SplitParser {
            onRead: data => {
                const cleanData = data ? data.trim() : ""
                if (cleanData !== "") {
                    spotifyText = cleanData
                    isSpotifyPlaying = true
                } else {
                    isSpotifyPlaying = false
                }
            }
        }
        Component.onCompleted: running = true
    }

    // slow timer for system stats
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running = true
            memProc.running = true
        }
    }

    // Event-based updates for window/layout (instant)
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            windowProc.running = true
            layoutProc.running = true
        }
    }

    // Backup timer for window/layout (catches edge cases)
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: {
            spotifyProc.running = true
            windowProc.running = true
            layoutProc.running = true
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 32
            color: root.colorBase

            // status bar
            Rectangle {
                anchors.fill: parent
                color: root.colorBase

                // left modules
                RowLayout {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 8
                    spacing: 8

                    // workspaces repeater
                    RowLayout {
                        spacing: 0
                        Repeater {
                            model: Array.from(Hyprland.workspaces.values)
                                .filter(ws => ws.id > 0)
                                .filter(ws => ws.monitor && ws.monitor.name === panel.screen.name)
                                .sort((a, b) => a.id - b.id)

                            Rectangle {
                                Layout.preferredWidth: 20
                                Layout.fillHeight: true
                                color: "transparent"

                                property var workspace: modelData
                                property int wsId: workspace.id
                                property bool isFocused: Hyprland.focusedWorkspace === workspace

                                Text {
                                    text: parent.wsId
                                    color: parent.isFocused ? root.colorTeal : root.colorOverlay
                                    font.pixelSize: root.fontSize
                                    font.family: root.fontFamily
                                    font.bold: true
                                    anchors.centerIn: parent
                                }

                                Rectangle {
                                    width: 20
                                    height: 3
                                    color: parent.isFocused ? root.colorMauve : "transparent"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Hyprland.dispatch("workspace " + parent.wsId)
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        color: root.colorOverlay
                    }

                    // current layout
                    Text {
                        text: currentLayout
                        color: root.colorText
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        color: root.colorOverlay
                    }

                    // active window title
                    Text {
                        text: activeWindow
                        color: root.colorMauve
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.maximumWidth: 400
                    }
                }

                // center modules
                RowLayout {
                    anchors.centerIn: parent
                    opacity: root.isSpotifyPlaying ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutQuad
                        }
                    }

                    Text {
                        text: spotifyText
                        color: root.colorGreen
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true

                        elide: Text.ElideRight
                        Layout.maximumWidth: 500
                    }
                }

                // right modules
                RowLayout {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 8
                    spacing: 8

                    // cpu
                    Text {
                        text: "CPU: " + cpuUsage + "%"
                        color: root.colorYellow
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        color: root.colorOverlay
                    }

                    // mem
                    Text {
                        text: "Mem: " + memUsage + "%"
                        color: root.colorYellow
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        color: root.colorOverlay
                    }

                    // clock
                    Text {
                        id: clockText
                        text: Qt.formatDateTime(new Date(), "ddd, MMM, dd - hh:mm AP")
                        color: root.colorMauve
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true

                        Timer {
                            interval: 1000
                            running: true
                            repeat: true
                            onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd, MMM, dd - hh:mm AP")
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        color: root.colorOverlay
                        visible: trayRepeater.count > 0
                    }

                    RowLayout {
                        spacing: 4

                        Repeater {
                            id: trayRepeater
                            model: SystemTray.items

                            Rectangle {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                color: "transparent"

                                IconImage {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    source: modelData.icon
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.LeftButton) {
                                            modelData.activate()
                                        } else if (mouse.button === Qt.RightButton) {
                                            var pos = parent.mapToItem(panel.contentItem, 0, height)
                                            modelData.display(panel, pos.x, pos.y)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
