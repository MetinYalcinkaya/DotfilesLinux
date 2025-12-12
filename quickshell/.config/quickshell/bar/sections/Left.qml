import QtQuick
import QtQuick.Layouts

import qs.widgets as W

Item {
    id: left
    required property var panel
    required property var theme

    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.leftMargin: 8

    implicitWidth: row.implicitWidth

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 8

        W.Workspaces { panel: left.panel; theme: left.theme }
        W.Separator { theme: left.theme }
        W.ActiveWindow { theme: left.theme }
    }
}
