import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    id: root
    required property var panel
    required property var theme

    // https://doc.qt.io/qt-6/qml-qtquick-fontmetrics.html
    FontMetrics {
        id: fm
        font.family: theme.fontFamily
        font.pixelSize: theme.fontSize
        font.bold: true
    }

    readonly property int em: Math.max(1, Math.round(fm.averageCharacterWidth))
    spacing: Math.round(em*0.15)

    Repeater {
        model: Hyprland.workspaces.values
            .filter(ws => ws.id > 0)
            .filter(ws => ws.monitor && ws.monitor.name === panel.screen.name)

        Rectangle {
            id: cell
            Layout.fillHeight: true
            color: "transparent"

            property int padX: Math.round(root.em * 0.25)

            property var workspace: modelData
            property int wsId: workspace.id
            property bool isFocused: Hyprland.focusedWorkspace === workspace

            readonly property int minCell: Math.round(root.em * 1.2)
            Layout.preferredWidth: Math.max(minCell, Math.ceil(label.contentWidth) + padX * 2)

            // workspace numbers
            Text {
                id: label
                text: cell.wsId
                color: cell.isFocused ? theme.teal : theme.overlay
                font.pixelSize: theme.fontSize
                font.family: theme.fontFamily
                font.bold: true
                anchors.centerIn: parent
            }

            // underline on focused
            Rectangle {
                height: Math.max(2, Math.round(root.em * 0.18))
                width: Math.ceil(label.contentWidth)
                color: theme.mauve
                anchors.horizontalCenter: label.horizontalCenter
                anchors.bottom: parent.bottom
                opacity: cell.isFocused ? 1 : 0
            }

            MouseArea {
                anchors.fill: parent
                onClicked: cell.workspace.activate()
            }
        }
    }
}
