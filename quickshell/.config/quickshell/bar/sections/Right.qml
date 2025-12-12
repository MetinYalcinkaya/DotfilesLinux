import QtQuick
import QtQuick.Layouts

import qs.widgets as W

Item {
    id: right
    required property var panel
    required property var theme
    required property var cpu

    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.rightMargin: 8

    implicitWidth: row.implicitWidth

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 8

        Text {
            text: "CPU: " + cpu.usage + "%"
            color: theme.yellow
            font.pixelSize: theme.fontSize
            font.family: theme.fontFamily
            font.bold: true
        }

        W.Separator { theme: right.theme }
        W.Clock { theme: right.theme }
        W.Separator { theme: right.theme }
        W.Tray { panel: right.panel; theme: right.theme }
    }
}
