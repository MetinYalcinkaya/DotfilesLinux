import QtQuick
import Quickshell.Services.Mpris

QtObject {
    property var spotifyPlayer: Mpris.players.values.find(p => p.identity === "Spotify")

    property bool isPlaying: !!spotifyPlayer
        && spotifyPlayer.playbackState === MprisPlaybackState.Playing

    property string text: {
        if (!spotifyPlayer) return ""
        const title = spotifyPlayer.trackTitle || "No Title"
        const artist = spotifyPlayer.trackArtist || ""
        return artist ? `${title} - ${artist}` : title
    }
}
