import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

import qs.theme as Theme
import qs.services as Services
import qs.bar as Bar

ShellRoot {
    id: root

    Theme.Palette { id: palette }

    Services.CpuService { id: cpuService }
    Services.SpotifyService { id: mediaService }

    Variants {
        model: Quickshell.screens

        Bar.Bar {
            theme: palette
            cpu: cpuService
            media: mediaService
        }
    }
}
