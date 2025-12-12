import QtQuick
import QtQuick.Layouts

Item {
    required property var theme
    required property var media

    anchors.centerIn: parent
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        opacity: media.isPlaying ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
        }

        Text {
            text: media.text
            color: theme.green
            font.pixelSize: theme.fontSize
            font.family: theme.fontFamily
            font.bold: true
            elide: Text.ElideRight
            Layout.maximumWidth: 500
        }
    }
}
