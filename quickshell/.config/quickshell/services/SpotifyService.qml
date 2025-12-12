import QtQuick
import Quickshell.Services.Mpris

QtObject {
    property var spotifyPlayer: Mpris.players.values.find(p => p.identity === "Spotify")

    property bool isPlaying: !!spotifyPlayer
        && spotifyPlayer.playbackState === MprisPlaybackState.Playing

    property string text: {
        if (!spotifyPlayer) return ""
        const meta = spotifyPlayer.metadata
        const title = meta["xesam:title"] || "No Title"
        const artistRaw = meta["xesam:artist"]
        const artist = Array.isArray(artistRaw) ? artistRaw.join(", ") : (artistRaw || "")
        return artist ? title + " - " + artist : title
    }
}
