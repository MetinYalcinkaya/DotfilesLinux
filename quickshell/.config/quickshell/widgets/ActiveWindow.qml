import QtQuick
import Quickshell.Hyprland
import QtQuick.Layouts

Text {
    required property var theme

    readonly property var focusedWindow: Hyprland.activeToplevel
    text: focusedWindow ? focusedWindow.title : ""

    color: theme.mauve
    font.pixelSize: theme.fontSize
    font.family: theme.fontFamily
    font.bold: true
    elide: Text.ElideRight
    Layout.maximumWidth: 500
}
