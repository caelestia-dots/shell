import qs.config
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

Scope {
    id: root

    required property WlSessionLock lock

    readonly property alias passwd: passwd
    readonly property alias fprint: fprint
    property string state
    property string fprintState
    property string buffer

    readonly property bool fprintRunning: fprintState === "" && fprint.active && fprint.message.includes("fingerprint")

    function handleKey(event: KeyEvent): void {
        if (passwd.active || state === "max")
            return;

        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            passwd.start();
        } else if (event.key === Qt.Key_Backspace) {
            if (event.modifiers & Qt.ControlModifier) {
                buffer = "";
            } else {
                buffer = buffer.slice(0, -1);
            }
        } else if (" abcdefghijklmnopqrstuvwxyz1234567890`~!@#$%^&*()-_=+[{]}\\|;:'\",<.>/?".includes(event.text.toLowerCase())) {
            // No illegal characters (you are insane if you use unicode in your password)
            buffer += event.text;
        }
    }

    PamContext {
        id: passwd

        onResponseRequiredChanged: {
            if (!responseRequired)
                return;

            respond(root.buffer);
            root.buffer = "";
        }

        onCompleted: res => {
            if (res === PamResult.Success)
                return root.lock.unlock();

            if (res === PamResult.Error)
                root.state = "error";
            else if (res === PamResult.MaxTries)
                root.state = "max";
            else if (res === PamResult.Failed)
                root.state = "fail";

            stateReset.restart();
        }
    }

    PamContext {
        id: fprint

        property bool available
        property int tries
        property int errorTries

        config: "fprint"
        configDirectory: Quickshell.shellDir + "/assets/pam.d"

        onCompleted: res => {
            if (!available)
                return;

            if (res === PamResult.Success)
                return root.lock.unlock();

            if (res === PamResult.Error) {
                root.fprintState = "error";
                if (errorTries < 3) {
                    errorTries++;
                    abort();
                    start();
                }
            } else if (res === PamResult.MaxTries) {
                // Isn't actually the real max tries as pam only reports completed
                // when max tries is reached.
                if (tries < Config.lock.maxFprintTries) {
                    tries++;
                    // Restart if not actually real max tries
                    start();
                } else {
                    root.fprintState = "max";
                    abort();
                }
            } else if (res === PamResult.Failed) {
                root.fprintState = "fail";
                abort();
                start();
            }

            fprintStateReset.start();
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "fprintd-list $USER"]
        onExited: code => fprint.available = code === 0
    }

    Timer {
        id: stateReset

        interval: 4000
        onTriggered: {
            if (root.state !== "max")
                root.state = "";
        }
    }

    Timer {
        id: fprintStateReset

        interval: 4000
        onTriggered: {
            root.fprintState = "";
            fprint.errorTries = 0;
        }
    }

    Connections {
        target: root.lock

        function onSecureChanged(): void {
            if (Config.lock.enableFprint && fprint.available && root.lock.secure) {
                fprint.start();
                fprint.tries = 0;
            }
        }

        function onUnlock(): void {
            root.buffer = "";
            fprint.abort();
        }
    }
}
