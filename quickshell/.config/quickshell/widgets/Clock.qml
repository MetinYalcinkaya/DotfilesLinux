import Quickshell
import QtQuick

Text {
    required property var theme
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    id: clockText
    text: Qt.formatDateTime(clock.date, "ddd, MMM, dd - hh:mm AP")

    color: theme.mauve
    font.pixelSize: theme.fontSize
    font.family: theme.fontFamily
    font.bold: true
}
