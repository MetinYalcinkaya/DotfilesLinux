import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import qs.bar.sections as S

PanelWindow {
    id: panel

    required property var modelData
    screen: modelData

    required property var theme
    required property var cpu
    required property var media

    anchors { top: true; left: true; right: true }
    implicitHeight: 32
    color: theme.base

    Rectangle {
        anchors.fill: parent
        color: theme.base

        S.Left {
            panel: panel
            theme: panel.theme
        }

        S.Center {
            theme: panel.theme
            media: panel.media
        }

        S.Right {
            panel: panel
            theme: panel.theme
            cpu: panel.cpu
        }
    }
}
