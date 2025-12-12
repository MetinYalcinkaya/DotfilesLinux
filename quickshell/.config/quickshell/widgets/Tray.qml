import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Services.SystemTray

Item {
    required property var panel
    required property var theme

    // menu state
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

    function pushMenu(entry) {
        trayMenuStack = trayMenuStack.concat([entry])
    }

    function popMenu() {
        trayMenuStack = trayMenuStack.slice(0, -1)
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        spacing: 4

        PopupWindow {
            id: trayMenuWin
            anchor.window: panel
            anchor.rect.x: trayMenuX
            anchor.rect.y: trayMenuY
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
                color: theme.base
                border.color: theme.overlay
                border.width: 1

                opacity: trayMenuWin.visible ? 1 : 0
                scale: trayMenuWin.visible ? 1 : 0.98
                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

                Column {
                    id: menuCol
                    padding: 8
                    spacing: 2

                    Rectangle {
                        visible: trayMenuStack.length > 0
                        height: visible ? 28 : 0
                        width: parent.width
                        radius: 6
                        color: "transparent"

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "<- Back"
                            color: theme.text
                            font.pixelSize: theme.fontSize - 2
                            font.family: theme.fontFamily
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: popMenu()
                        }
                    }

                    QsMenuOpener {
                        id: trayMenuOpener
                        menu: trayMenuStack.length > 0
                            ? trayMenuStack[trayMenuStack.length - 1]
                            : trayMenuRoot
                    }

                    Repeater {
                        model: trayMenuOpener.children

                        delegate: Item {
                            id: rowItem
                            width: menuBox.width - 16
                            height: entry.isSeparator ? 10 : 28
                            property var entry: modelData

                            Rectangle {
                                visible: entry.isSeparator
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 1
                                color: theme.overlay
                                opacity: 0.6
                            }

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
                                        color: theme.text
                                        font.pixelSize: theme.fontSize - 2
                                        font.family: theme.fontFamily
                                        elide: Text.ElideRight
                                        width: parent.width - 40
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: entry.hasChildren ? "›" : ""
                                        color: theme.overlay
                                        font.pixelSize: theme.fontSize - 2
                                        font.family: theme.fontFamily
                                    }
                                }

                                MouseArea {
                                    id: hover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: entry.enabled && !entry.isSeparator

                                    onClicked: {
                                        if (entry.hasChildren) {
                                            pushMenu(entry)
                                        } else {
                                            entry.triggered()
                                            closeTrayMenu()
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
            onCleared: closeTrayMenu()
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
                            openTrayMenu(modelData, pos.x, pos.y)
                        }
                    }
                }
            }
        }
    }
}
