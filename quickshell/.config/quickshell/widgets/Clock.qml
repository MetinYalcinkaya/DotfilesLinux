import QtQuick

Text {
    required property var theme

    id: clockText
    text: Qt.formatDateTime(new Date(), "ddd, MMM, dd - hh:mm AP")

    color: theme.mauve
    font.pixelSize: theme.fontSize
    font.family: theme.fontFamily
    font.bold: true

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd, MMM, dd - hh:mm AP")
    }
}
