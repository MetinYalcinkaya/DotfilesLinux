import QtQuick
import QtQuick.Layouts

import qs.widgets as W

Item {
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

        W.Workspaces { panel: panel; theme: theme }
        W.Separator { theme: theme }
        W.ActiveWindow { theme: theme }
    }
}
