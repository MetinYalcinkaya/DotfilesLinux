import { App } from "astal/gtk3"
import { Variable, GLib, bind } from "astal"
import { Astal, Gtk, Gdk } from "astal/gtk3"
import Hyprland from "gi://AstalHyprland"
import Mpris from "gi://AstalMpris"
import Wp from "gi://AstalWp"
import Tray from "gi://AstalTray"
// import Cava from "gi://AstalCava"

function SysTray() {
    const tray = Tray.get_default()

    return <box className="SysTray">
        {bind(tray, "items").as(items => items.map(item => (
            <menubutton
                tooltipMarkup={bind(item, "tooltipMarkup")}
                usePopover={false}
                actionGroup={bind(item, "actionGroup").as(ag => ["dbusmenu", ag])}
                menuModel={bind(item, "menuModel")}>
                <icon gicon={bind(item, "gicon")} />
            </menubutton>
        )))}
    </box>
}

function Media() {
    const spotify = Mpris.Player.new("spotify");

    return <box className="Media">
        {bind(spotify, "available").as(avail =>
            avail ? (
                <box>
                    <box
                        className="Cover"
                        valign={Gtk.Align.CENTER}
                        css={bind(spotify, "coverArt").as(cover =>
                            `background-image: url('${cover}');`
                        )}
                    />
                    <label
                        label={bind(spotify, "title").as(title =>
                            `${title} - ${spotify.artist}`
                        )}
                    />
                </box>
            ) : (
                <label label="Nothing Playing" />
            )
        )}
    </box>;
}

// function CavaDraw() {
//   const cava = Cava.get_default()!;
//   return (
//     <box className="Cava">
//       <drawingarea
//         hexpand={true}
//         vexpand={true}
//         widthRequest={50}
//         onDraw={(self, cr) => {
//           const width = self.get_allocated_width();
//           const height = self.get_allocated_height();
//           const values = cava.get_values();
//           const bars = cava.bars;
//
//           if (bars === 0 || values.length === 0) return;
//
//           // Get color from style context
//           const color = self
//             .get_style_context()
//             .get_color(Gtk.StateFlags.NORMAL);
//           cr.setSourceRGBA(color.red, color.green, color.blue, color.alpha);
//
//           const barWidth = width / (bars - 1);
//           let lastX = 0;
//           let lastY = height - height * values[0];
//
//           cr.moveTo(lastX, lastY);
//
//           for (let i = 1; i < bars; i++) {
//             const h = height * values[i];
//             const y = height - h;
//
//             cr.curveTo(
//               lastX + barWidth / 2,
//               lastY,
//               lastX + barWidth / 2,
//               y,
//               i * barWidth,
//               y,
//             );
//
//             lastX = i * barWidth;
//             lastY = y;
//           }
//
//           // Close and fill the path
//           cr.lineTo(lastX, height);
//           cr.lineTo(0, height);
//           cr.closePath();
//           cr.fill();
//         }}
//       />
//     </box>
//   ).hook(cava, "notify::values", (self) => self.queue_draw());
// }

function Workspaces() {
    const hypr = Hyprland.get_default()

    return <box className="Workspaces">
        {bind(hypr, "workspaces").as(wss => wss
            .filter(ws => !(ws.id >= -99 && ws.id <= -2)) // filter out special workspaces
            .sort((a, b) => a.id - b.id)
            .map(ws => (
                <button
                    className={bind(hypr, "focusedWorkspace").as(fw =>
                        ws === fw ? "focused" : "")}
                    onClicked={() => ws.focus()}>
                    {ws.id}
                </button>
            ))
        )}
    </box>
}

// function FocusedClient() {
//     const hypr = Hyprland.get_default()
//     const focused = bind(hypr, "focusedClient")
//
//     return <box
//         className="Focused"
//         visible={focused.as(Boolean)}>
//         {focused.as(client => (
//             client && <label label={bind(client, "title").as(String)} />
//         ))}
//     </box>
// }

function Time({ format = "%I:%M %p - %A - %e/%m/%Y" }) {
    const time = Variable<string>("").poll(1000, () =>
        GLib.DateTime.new_now_local().format(format)!)

    return <label
        className="Time"
        onDestroy={() => time.drop()}
        label={time()}
    />
}

export default function Bar(monitor: Gdk.Monitor) {
    const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

    return <window
        className="Bar"
        gdkmonitor={monitor}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        anchor={TOP | LEFT | RIGHT}>
        <centerbox>
            <box hexpand halign={Gtk.Align.START}>
                <Workspaces />
            </box>
            <box>
                <Media />
            </box>
            <box hexpand halign={Gtk.Align.END} >
                <SysTray />
                <Time />
            </box>
        </centerbox>
    </window>
}
