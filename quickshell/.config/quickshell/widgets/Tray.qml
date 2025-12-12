import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Services.SystemTray

Item {
    required property var panel
    required property var theme

    // drawer state
    property bool trayOpen: false
    property int drawerX: 0
    property int drawerY: 0

    // menu state
    property var trayMenuRoot: null
    property var trayMenuStack: []
    property int trayMenuX: 0
    property int trayMenuY: 0

    function syncDrawerAnchor() {
        const p = trayButton.mapToItem(panel.contentItem, 0, trayButton.height)
        drawerX = p.x + trayButton.width - drawerBoxWidth
        drawerY = panel.height - 1
        if (drawerX < 4) drawerX = 4
    }

    function openDrawer() {
        trayOpen = true
        syncDrawerAnchor()
        trayDrawerWin.visible = true
        trayGrab.windows = [ panel, trayDrawerWin, trayMenuWin ]
        trayGrab.active = true
    }

    function closeAll() {
        trayOpen = false
        closeTrayMenu()
        trayGrab.active = false
    }


    function toggleDrawer() {
        if (trayOpen) {
            closeAll()
        } else {
            openDrawer()
        }
    }

    function openTrayMenu(trayItem, x, y) {
        trayMenuRoot = trayItem.menu
        trayMenuStack = []
        trayMenuX = x
        trayMenuY = y
        trayMenuWin.visible = true
        trayGrab.windows = [ panel, trayDrawerWin, trayMenuWin ]
        trayGrab.active = true
    }

    function closeTrayMenu() {
        trayMenuWin.visible = false
        trayMenuStack = []
        trayMenuRoot = null
    }

    function pushMenu(entry) {
        trayMenuStack = trayMenuStack.concat([entry])
    }

    function popMenu() {
        trayMenuStack = trayMenuStack.slice(0, -1)
    }

    implicitWidth: trayButton.implicitWidth
    implicitHeight: trayButton.implicitHeight

    Rectangle {
        id: trayButton
        implicitWidth: 24
        implicitHeight: 24
        radius: 6
        color: hover.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"

        Text {
            anchors.centerIn: parent
            // TODO: change?
            text: "󰒱"
            color: theme.text
            font.pixelSize: theme.fontSize - 2
            font.family: theme.fontFamily
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onClicked: toggleDrawer()
        }
    }

    readonly property int drawerBoxWidth: Math.max(1, Math.min(340, drawerRow.implicitWidth + 16))

    PopupWindow {
        id: trayDrawerWin
        anchor.window: panel
        anchor.rect.x: drawerX
        anchor.rect.y: drawerY
        anchor.rect.w: 1
        anchor.rect.h: 1
        visible: false
        color: "transparent"
        implicitWidth: drawerBoxWidth
        implicitHeight: Math.max(1, drawerBox.height)

        ClippingRectangle {
            id: drawerBox
            width: trayDrawerWin.implicitWidth
            height: trayOpen ? (drawerCol.implicitHeight) : 0

            radius: 10
            topLeftRadius: 0
            topRightRadius: 0
            color: theme.base
            border.color: theme.overlay
            border.width: 1

            opacity: trayOpen ? 1 : 0
            scale: trayOpen ? 1 : 0.98
            
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

            onHeightChanged: {
                if (!trayOpen && height < 1) trayDrawerWin.visible = false
            }

            Column {
                id: drawerCol
                padding: 8
                spacing: 6

                RowLayout {
                    id: drawerRow
                    spacing: 4

                    Repeater {
                        model: SystemTray.items
                        delegate: Rectangle {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            radius: 6
                            color: iconHover.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"

                            IconImage {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                source: modelData.icon
                            }

                            MouseArea {
                                id: iconHover
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton

                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.LeftButton) {
                                        modelData.activate()
                                    } else if (mouse.button === Qt.RightButton) {
                                        if (!modelData.hasMenu) return
                                        const pos = parent.mapToItem(panel.contentItem, 0, trayButton.height + 8)
                                        openTrayMenu(modelData, pos.x, panel.height - 1)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

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
        active: false
        windows: [ panel, trayDrawerWin, trayMenuWin ]
        onCleared: {
            trayOpen = false
            closeTrayMenu()
        }
    }

    onTrayOpenChanged: if (trayOpen) syncDrawerAnchor()
}
