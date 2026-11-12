pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.components.misc
import qs.services

Scope {
    Variants {
        model: Screens.screens

        NotchWindow {
            required property ShellScreen modelData

            screen: modelData
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mascot"
        description: "Pick a notch mascot animation"
        onPressed: menu.toggle()
    }

    MascotMenu {
        id: menu
    }

    IpcHandler {
        function toggle(): void {
            const s = ShellState.forActive();
            s.notch = !s.notch;
        }

        function open(page: string): void {
            const s = ShellState.forActive();
            const idx = NotchPages.find(page);
            if (idx >= 0)
                s.notchPage = idx;
            s.notch = true;
        }

        function close(): void {
            ShellState.forActive().notch = false;
        }

        function mascot(): void {
            const s = ShellState.forActive();
            s.mascotPick = "";
            s.mascotCalls++;
        }

        function play(name: string): void {
            const s = ShellState.forActive();
            s.mascotPick = name;
            s.mascotCalls++;
        }

        function mascotMenu(): void {
            menu.toggle();
        }

        function react(name: string): void {
            Mascot.ready = true;
            Mascot.react(name);
        }

        function pages(): string {
            return NotchPages.all.map(p => p.id).join("\n");
        }

        function setMascot(name: string): void {
            if (["knight", "grimm", "hornet"].includes(name))
                NotchSettings.set("mascotKind", name);
        }

        function getMascot(): string {
            return NotchSettings.mascotKind;
        }

        target: "notch"
    }
}
