import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
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

    // hyprland
    readonly property var focusedWindow: Hyprland.toplevels.values.find(p => p.activated === true)
    readonly property string activeWindow: focusedWindow ? focusedWindow.title : ""

    // cpu properties
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0

    // media
    property var spotifyPlayer: Mpris.players.values.find(p => p.identity === "Spotify")
    property bool isSpotifyPlaying: !!spotifyPlayer
        && spotifyPlayer.playbackState === MprisPlaybackState.Playing

    property string spotifyText: {
        if (!spotifyPlayer) return ""
        const meta = spotifyPlayer.metadata
        const title = meta["xesam:title"] || "No Title"
        const artistRaw = meta["xesam:artist"]
        const artist = Array.isArray(artistRaw)
            ? artistRaw.join(", ")
            : (artistRaw || "")
            
        return artist ? title + " - " + artist : title
    }


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

    // slow timer for system stats
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running = true
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            property var modelData
            screen: modelData

            // tray properties and functions
            property var trayMenuRoot: null
            property var trayMenuStack: []
            property int trayMenuX: 0
            property int trayMenuY: 0

            function openTrayMenu(trayItem, x, y) {
                trayMenuRoot = trayItem.menu
                trayMenuStack = []
                trayMenuX = x
                trayMenuY = y
                trayMenuWin.visible = true
                trayGrab.active = true
            }

            function closeTrayMenu() {
                trayMenuWin.visible = false
                trayGrab.active = false
                trayMenuStack = []
                trayMenuRoot = null
            }

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

                    // active window title
                    Text {
                        text: activeWindow
                        color: root.colorMauve
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.maximumWidth: 500
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

                        PopupWindow {
                            id: trayMenuWin
                            anchor.window: panel
                            anchor.rect.x: panel.trayMenuX
                            anchor.rect.y: panel.trayMenuY
                            anchor.rect.w: 1
                            anchor.rect.h: 1
                            visible: false
                            color: "transparent"
                            implicitWidth: menuBox.implicitWidth
                            implicitHeight: menuBox.implicitHeight

                            Rectangle {
                                id: menuBox
                                implicitWidth: 260
                                implicitHeight: menuCol.implicitHeight
                                radius: 10
                                color: root.colorBase
                                border.color: root.colorOverlay
                                border.width: 1

                                // animation
                                opacity: trayMenuWin.visible ? 1 : 0
                                scale: trayMenuWin.visible ? 1 : 0.98
                                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

                                Column {
                                    id: menuCol
                                    padding: 8
                                    spacing: 2

                                    Rectangle {
                                        visible: panel.trayMenuStack.length > 0
                                        height: visible ? 28 : 0
                                        width: parent.width
                                        radius: 6
                                        color: "transparent"

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "<- Back"
                                            color: root.colorText
                                            font.pixelSize: root.fontSize - 2
                                            font.family: root.fontFamily
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: panel.trayMenuStack.pop()
                                        }
                                    }

                                    QsMenuOpener {
                                        id: trayMenuOpener
                                        menu: panel.trayMenuStack.length > 0
                                            ? panel.trayMenuStack[panel.trayMenuStack.length - 1]
                                            : panel.trayMenuRoot
                                    }

                                    Repeater {
                                        model: trayMenuOpener.children
                                        
                                        delegate: Item {
                                            id: row
                                            width: menuBox.width - 16
                                            height: entry.isSeparator ? 10 : 28

                                            property var entry: modelData

                                            // separator
                                            Rectangle {
                                                visible: entry.isSeparator
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: parent.width
                                                height: 1
                                                color: root.colorOverlay
                                                opacity: 0.6
                                            }

                                            // normal row
                                            Rectangle {
                                                visible: !entry.isSeparator
                                                anchors.fill: parent
                                                radius: 6
                                                color: hover.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"
                                                opacity: entry.enabled ? 1 : 0.45

                                                Row {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 8
                                                    anchors.rightMargin: 8
                                                    spacing: 8

                                                    // optional icon
                                                    IconImage {
                                                        visible: entry.icon !== ""
                                                        width: 16
                                                        height: 16
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        source: entry.icon
                                                    }

                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: entry.text
                                                        color: root.colorText
                                                        font.pixelSize: root.fontSize - 2
                                                        font.family: root.fontFamily
                                                        elide: Text.ElideRight
                                                        width: parent.width - 40
                                                    }

                                                    // submenu
                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: entry.hasChildren ? "›" : ""
                                                        color: root.colorOverlay
                                                        font.pixelSize: root.fontSize - 2
                                                        font.family: root.fontFamily
                                                    }
                                                }

                                                MouseArea {
                                                    id: hover
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    enabled: entry.enabled && !entry.isSeparator

                                                    onClicked: {
                                                        if (entry.hasChildren) {
                                                            panel.trayMenuStack.push(entry)
                                                        } else {
                                                            entry.triggered()
                                                            panel.closeTrayMenu()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        HyprlandFocusGrab {
                            id: trayGrab
                            windows: [ trayMenuWin ]
                            active: false
                            onCleared: panel.closeTrayMenu()
                        }

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
                                            if (!modelData.hasMenu) return
                                            var pos = parent.mapToItem(panel.contentItem, 0, parent.height)
                                            panel.openTrayMenu(modelData, pos.x, pos.y)
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
