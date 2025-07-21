pragma Singleton

import qs.widgets
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property list<MprisPlayer> list: Mpris.players.values
    readonly property MprisPlayer active: manualActive ?? list.find(p => p.identity === "Spotify") ?? list[0] ?? null
    property MprisPlayer manualActive

    CustomShortcut {
        name: "mediaToggle"
        description: "Toggle media playback"
        onPressed: {
            const active = root.active;
            if (active && active.canTogglePlaying)
                active.togglePlaying();
        }
    }

    CustomShortcut {
        name: "mediaPrev"
        description: "Previous track"
        onPressed: {
            const active = root.active;
            if (active && active.canGoPrevious)
                active.previous();
        }
    }

    CustomShortcut {
        name: "mediaNext"
        description: "Next track"
        onPressed: {
            const active = root.active;
            if (active && active.canGoNext)
                active.next();
        }
    }

    CustomShortcut {
        name: "mediaStop"
        description: "Stop media playback"
        onPressed: root.active?.stop()
    }

    IpcHandler {
        target: "mpris"

        function getActive(prop: string): string {
            const active = root.active;
            return active ? active[prop] ?? "Invalid property" : "No active player";
        }

        function list(): string {
            return root.list.map(p => p.identity).join("\n");
        }

        function play(): void {
            const active = root.active;
            if (active?.canPlay)
                active.play();
        }

        function pause(): void {
            const active = root.active;
            if (active?.canPause)
                active.pause();
        }

        function playPause(): void {
            const active = root.active;
            if (active?.canTogglePlaying)
                active.togglePlaying();
        }

        function previous(): void {
            const active = root.active;
            if (active?.canGoPrevious)
                active.previous();
        }

        function next(): void {
            const active = root.active;
            if (active?.canGoNext)
                active.next();
        }

        function stop(): void {
            root.active?.stop();
        }
    }
}
