import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Services.SystemTray

Item {
    id: trayRoot
    required property var panel
    required property var theme

    // drawer state
    property string overlayMode: "closed"

    // menu state
    property var trayMenuRoot: null
    property var trayMenuStack: []

    readonly property bool overlayOpen: trayDrawerWin.visible || trayMenuWin.visible
    readonly property bool pointerInside: hover.containsMouse || drawerHover.hovered || menuHover.hovered

    property bool opening: false

    Timer {
        id: hoverDismissTimer
        interval: 150
        repeat: false
        onTriggered: {
            if (overlayOpen && !pointerInside) closeAll()
        }
    }

    onPointerInsideChanged: {
        if (!overlayOpen) return
        if (pointerInside) hoverDismissTimer.stop()
        else hoverDismissTimer.restart()
    }

    Timer {
        id: focusLossDebounce
        interval: 0
        repeat: false
        onTriggered: {
            if (opening) return
            if (overlayOpen && !(panelKeys.activeFocus || drawerKeys.activeFocus || menuKeys.activeFocus)) {
                closeAll()
            }
        }
    }

    function scheduleFocusCheck() {
        focusLossDebounce.restart()
    }

    function beginOverlay() {
        panel.focusable = true
        trayGrab.active = true
    }

    function endOverlay() {
        panel.focusable = false
        trayGrab.active = false
    }

    function showDrawer() {
        opening = true
        beginOverlay()

        trayDrawerWin.visible = false
        trayMenuWin.visible = false

        Qt.callLater(() => {
            overlayMode = "drawer"
            trayDrawerWin.visible = true
            trayDrawerWin.anchor.updateAnchor()
            drawerKeys.forceActiveFocus()
            opening = false
        })
    }

    function showMenuFor(trayItem) {
        if (!trayItem || !trayItem.hasMenu) return
        trayMenuRoot = trayItem.menu
        trayMenuStack = []

        opening = true
        beginOverlay()

        trayDrawerWin.visible = false
        trayMenuWin.visible = false

        Qt.callLater(() => {
            overlayMode = "menu"
            trayMenuWin.visible = true
            trayMenuWin.anchor.updateAnchor()
            menuKeys.forceActiveFocus()
            opening = false
        })
    }

    function backToDrawer() {
        trayMenuStack = []
        trayMenuRoot = null
        showDrawer()
    }

    function closeAll() {
        opening = false
        trayDrawerWin.visible = false
        trayMenuWin.visible = false
        overlayMode = "closed"
        trayMenuStack = []
        trayMenuRoot = null
        endOverlay()
    }

    function pushMenu(entry) {
        trayMenuStack = trayMenuStack.concat([entry])
        Qt.callLater(() => trayMenuWin.anchor.updateAnchor())
    }

    function popMenu() {
        trayMenuStack = trayMenuStack.slice(0, -1)
        Qt.callLater(() => trayMenuWin.anchor.updateAnchor())
    }

    FocusScope {
        id: panelKeys
        focus: overlayOpen

        Keys.onEscapePressed: (event) => {
            if (overlayOpen) {
                closeAll()
                event.accepted = true
            }
        }

        onActiveFocusChanged: {
            if (!activeFocus && overlayOpen) scheduleFocusCheck()
        }
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
            text: "󰍜"
            color: theme.text
            font.pixelSize: theme.fontSize - 2
            font.family: theme.fontFamily
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onClicked: {
                if (overlayMode === "drawer") closeAll()
                else showDrawer()
            }
        }
    }

    readonly property int drawerBoxWidth: Math.max(1, Math.min(340, drawerRow.implicitWidth + 16))
    readonly property int drawerBoxHeight: Math.max(1, drawerCol.implicitHeight)

    readonly property int menuBoxWidth: Math.max(260, menuCol.implicitWidth)
    readonly property int menuBoxHeight: Math.max(1, menuCol.implicitHeight + 32)

    readonly property int popupWinWidth: Math.max(drawerBoxWidth, menuBoxWidth)

    function applyAnchor(win) {
        const p = panel.contentItem.mapFromItem(trayButton, 0, trayButton.height)
        win.anchor.rect.y = p.y + 4
        win.anchor.rect.x = Math.max(0, panel.width - popupWinWidth)
    }

    PopupWindow {
        id: trayDrawerWin
        visible: false
        color: "transparent"
        surfaceFormat.opaque: false

        anchor.window: panel
        anchor.rect.width: 1
        anchor.rect.height: 1
        anchor.adjustment: PopupAdjustment.FlipY | PopupAdjustment.ResizeY

        implicitWidth: popupWinWidth
        implicitHeight: drawerBoxHeight

        onImplicitHeightChanged: if (visible) anchor.updateAnchor()

        anchor.onAnchoring: applyAnchor(trayDrawerWin)

        // clear the full surface every frame
        Rectangle { anchors.fill: parent; color: Qt.rgba(0,0,0,0) }

        HoverHandler { id: drawerHover }

        FocusScope {
            id: drawerKeys
            focus: trayDrawerWin.visible

            Keys.onEscapePressed: (event) => { closeAll(); event.accepted = true }
            onActiveFocusChanged: { if (!activeFocus && overlayOpen) scheduleFocusCheck() }
        }

        ClippingRectangle {
            id: drawerBox
            anchors.top: parent.top
            anchors.right: parent.right
            width: drawerBoxWidth
            height: drawerBoxHeight

            radius: 10
            topLeftRadius: 0
            topRightRadius: 0
            bottomRightRadius: 0
            color: theme.base

            // subtle appear animation
            opacity: trayDrawerWin.visible ? 1 : 0
            scale: trayDrawerWin.visible ? 1 : 0.98
            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

            Column {
                id: drawerCol
                anchors.fill: parent
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
                                        closeAll()
                                    } else if (mouse.button === Qt.RightButton) {
                                        showMenuFor(modelData)
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
        visible: false
        color: "transparent"
        surfaceFormat.opaque: false

        anchor.window: panel
        anchor.rect.width: 1
        anchor.rect.height: 1
        anchor.adjustment: PopupAdjustment.FlipY | PopupAdjustment.ResizeY

        implicitWidth: popupWinWidth
        implicitHeight: menuBoxHeight

        onImplicitHeightChanged: if (visible) anchor.updateAnchor()

        anchor.onAnchoring: applyAnchor(trayMenuWin)

        Rectangle { anchors.fill: parent; color: Qt.rgba(0,0,0,0) }

        HoverHandler { id: menuHover }

        FocusScope {
            id: menuKeys
            focus: trayMenuWin.visible

            Keys.onEscapePressed: (event) => { closeAll(); event.accepted = true }
            onActiveFocusChanged: { if (!activeFocus && overlayOpen) scheduleFocusCheck() }
        }

        ClippingRectangle {
            id: menuBox
            anchors.top: parent.top
            anchors.right: parent.right
            width: menuBoxWidth
            height: menuBoxHeight

            radius: 10
            topLeftRadius: 0
            topRightRadius: 0
            bottomRightRadius: 0
            color: theme.base

            opacity: trayMenuWin.visible ? 1 : 0
            scale: trayMenuWin.visible ? 1 : 0.98
            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

            ColumnLayout {
                id: menuCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 2

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: trayMenuStack.length > 0 ? 28 : 0
                    visible: trayMenuStack.length > 0
                    radius: 6
                    color: "transparent"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        // text: "<- Back"
                        text: "󰌑 Back"
                        color: theme.text
                        font.pixelSize: theme.fontSize - 2
                        font.family: theme.fontFamily
                    }

                    MouseArea { anchors.fill: parent; onClicked: popMenu() }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: trayMenuStack.length === 0 ? 28 : 0
                    visible: trayMenuStack.length === 0
                    radius: 6
                    color: "transparent"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        // text: "<- Tray"
                        text: "󰌑 Tray"
                        color: theme.text
                        font.pixelSize: theme.fontSize - 2
                        font.family: theme.fontFamily
                    }

                    MouseArea { anchors.fill: parent; onClicked: backToDrawer() }
                }

                QsMenuOpener {
                    id: trayMenuOpener
                    menu: trayMenuStack.length > 0
                          ? trayMenuStack[trayMenuStack.length - 1]
                          : trayMenuRoot
                }

                Repeater {
                    model: trayMenuOpener.children
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: modelData.isSeparator ? 10 : 28
                        radius: 6
                        color: "transparent"
                        opacity: modelData.enabled ? 1 : 0.45
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
                            color: hoverEntry.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"
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
                                id: hoverEntry
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: entry.enabled && !entry.isSeparator
                                onClicked: {
                                    if (entry.hasChildren) pushMenu(entry)
                                    else {
                                        entry.triggered()
                                        closeAll()
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
        onCleared: closeAll()
    }
}
