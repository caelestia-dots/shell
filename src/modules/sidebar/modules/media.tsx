import Players from "@/services/players";
import Slider from "@/widgets/slider";
import { bind, Variable } from "astal";
import { Gtk } from "astal/gtk3";
import AstalMpris from "gi://AstalMpris";

const lengthStr = (length: number) =>
    `${Math.floor(length / 60)}:${Math.floor(length % 60)
        .toString()
        .padStart(2, "0")}`;

const noNull = (s: string | null) => s ?? "-";

const NoMedia = () => (
    <box vertical className="media" name="none">
        <box homogeneous halign={Gtk.Align.CENTER} className="cover-art">
            <label xalign={0.4} label="" />
        </box>
        <box vertical className="progress">
            <Slider value={bind(Variable(0))} />
            <box className="time">
                <label label="-1:-1" />
                <box hexpand />
                <label label="-1:-1" />
            </box>
        </box>
        <box vertical className="details">
            <label truncate className="title" label="No media" />
            <label truncate className="artist" label="Try play some music!" />
            <label truncate className="album" label="" />
        </box>
        <box vertical className="controls">
            <box halign={Gtk.Align.CENTER} className="playback">
                <button sensitive={false} cursor="pointer" label="󰒮" />
                <button sensitive={false} cursor="pointer" label="󰐊" />
                <button sensitive={false} cursor="pointer" label="󰒭" />
            </box>
            <box className="options">
                <button sensitive={false} cursor="pointer" label="󰊓" />
                <button sensitive={false} cursor="pointer" label="󰒞" />
                <box hexpand />
                <button className="needs-adjustment" sensitive={false} cursor="pointer" label="󰑗" />
                <button className="needs-adjustment" sensitive={false} cursor="pointer" label="󰀽" />
            </box>
        </box>
    </box>
);

const Player = ({ player }: { player: AstalMpris.Player }) => {
    const position = Variable.derive([bind(player, "position"), bind(player, "length")], (p, l) => p / l);

    return (
        <box vertical className="media" name={player.busName} onDestroy={() => position.drop()}>
            <box
                homogeneous
                halign={Gtk.Align.CENTER}
                className="cover-art"
                css={bind(player, "coverArt").as(a => `background-image: url("${a}");`)}
            >
                {bind(player, "coverArt").as(a => (a ? <box visible={false} /> : <label xalign={0.4} label="" />))}
            </box>
            <box vertical className="progress">
                <Slider value={bind(position)} />
                <box className="time">
                    <label label={bind(player, "position").as(lengthStr)} />
                    <box hexpand />
                    <label label={bind(player, "length").as(lengthStr)} />
                </box>
            </box>
            <box vertical className="details">
                <label truncate className="title" label={bind(player, "title").as(noNull)} />
                <label truncate className="artist" label={bind(player, "artist").as(noNull)} />
                <label truncate className="album" label={bind(player, "album").as(noNull)} />
            </box>
            <box vertical className="controls">
                <box halign={Gtk.Align.CENTER} className="playback">
                    <button
                        sensitive={bind(player, "canGoPrevious")}
                        cursor="pointer"
                        onClicked={() => player.next()}
                        label="󰒮"
                    />
                    <button
                        sensitive={bind(player, "canControl")}
                        cursor="pointer"
                        onClicked={() => player.play_pause()}
                        label={bind(player, "playbackStatus").as(s =>
                            s === AstalMpris.PlaybackStatus.PLAYING ? "󰏤" : "󰐊"
                        )}
                    />
                    <button
                        sensitive={bind(player, "canGoNext")}
                        cursor="pointer"
                        onClicked={() => player.next()}
                        label="󰒭"
                    />
                </box>
                <box className="options">
                    <button
                        sensitive={bind(player, "canSetFullscreen")}
                        cursor="pointer"
                        onClicked={() => player.toggle_fullscreen()}
                        label={bind(player, "fullscreen").as(f => (f ? "󰊔" : "󰊓"))}
                    />
                    <button
                        sensitive={bind(player, "canControl")}
                        cursor="pointer"
                        onClicked={() => player.shuffle()}
                        label={bind(player, "shuffleStatus").as(s => (s === AstalMpris.Shuffle.ON ? "󰒝" : "󰒞"))}
                    />
                    <box hexpand />
                    <button
                        className="needs-adjustment"
                        sensitive={bind(player, "canControl")}
                        cursor="pointer"
                        onClicked={() => player.loop()}
                        label={bind(player, "loopStatus").as(l =>
                            l === AstalMpris.Loop.TRACK ? "󰑘" : l === AstalMpris.Loop.PLAYLIST ? "󰑖" : "󰑗"
                        )}
                    />
                    <button
                        className="needs-adjustment"
                        sensitive={bind(player, "canRaise")}
                        cursor="pointer"
                        onClicked={() => player.raise()}
                        label="󰀽"
                    />
                </box>
            </box>
        </box>
    );
};

export default () => {
    const active = Variable(Players.get_default().list[0]?.busName ?? "none");

    return (
        <box vertical>
            <stack
                transitionType={Gtk.StackTransitionType.SLIDE_LEFT_RIGHT}
                transitionDuration={150}
                shown={bind(active)}
            >
                <NoMedia />
                {bind(Players.get_default(), "list").as(ps => ps.map(p => <Player player={p} />))}
            </stack>
        </box>
    );
};
