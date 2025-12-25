import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    required property var panel
    required property var theme

    spacing: 0

    Repeater {
        model: Hyprland.workspaces.values
            .filter(ws => ws.id > 0)
            .filter(ws => ws.monitor && ws.monitor.name === panel.screen.name)

        Rectangle {
            Layout.preferredWidth: 20
            Layout.fillHeight: true
            color: "transparent"

            property var workspace: modelData
            property int wsId: workspace.id
            property bool isFocused: Hyprland.focusedWorkspace === workspace

            // workspace numbers
            Text {
                text: parent.wsId
                color: parent.isFocused ? theme.teal : theme.overlay
                font.pixelSize: theme.fontSize
                font.family: theme.fontFamily
                font.bold: true
                anchors.centerIn: parent
            }

            // underline on focused
            Rectangle {
                width: 20
                height: 3
                color: parent.isFocused ? theme.mauve : "transparent"
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
