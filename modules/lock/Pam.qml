import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import Caelestia.Config

Scope {
    id: root

    required property WlSessionLock lock

    readonly property alias passwd: passwd
    readonly property alias fprint: fprint
    property string lockMessage
    property string state
    property string fprintState
    property string buffer

    signal flashMsg

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
        } else if (/^[^\x00-\x1F\x7F-\x9F]+$/.test(event.text)) {
            // Allow anything except control characters
            buffer += event.text;
        }
    }

    PamContext {
        id: passwd

        config: "passwd"
        configDirectory: Quickshell.shellDir + "/assets/pam.d"

        onMessageChanged: {
            if (message.startsWith("The account is locked"))
                root.lockMessage = message;
            else if (root.lockMessage && message.endsWith(" left to unlock)"))
                root.lockMessage += "\n" + message;
        }

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

            root.flashMsg();
            stateReset.restart();
        }
    }

    PamContext {
        id: fprint

        property bool available
        property int tries
        property int errorTries

        function checkAvail(): void {
            if (!available || !GlobalConfig.lock.enableFprint || !root.lock.secure) {
                abort();
                return;
            }

            tries = 0;
            errorTries = 0;
            start();
        }

        config: "fprint"
        configDirectory: Quickshell.shellDir + "/assets/pam.d"

        onCompleted: res => {
            if (!available)
                return;

            if (res === PamResult.Success)
                return root.lock.unlock();

            if (res === PamResult.Error) {
                root.fprintState = "error";
                errorTries++;
                if (errorTries < 5) {
                    abort();
                    errorRetry.restart();
                }
            } else if (res === PamResult.MaxTries) {
                // Isn't actually the real max tries as pam only reports completed
                // when max tries is reached.
                tries++;
                if (tries < GlobalConfig.lock.maxFprintTries) {
                    // Restart if not actually real max tries
                    root.fprintState = "fail";
                    start();
                } else {
                    root.fprintState = "max";
                    abort();
                }
            }

            root.flashMsg();
            fprintStateReset.start();
        }
    }

    Process {
        id: availProc

        command: ["sh", "-c", "fprintd-list $USER"]
        onExited: code => { // qmllint disable signal-handler-parameters
            fprint.available = code === 0;
            fprint.checkAvail();
        }
    }

    Timer {
        id: errorRetry

        interval: 800
        onTriggered: fprint.start()
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
        function onSecureChanged(): void {
            if (root.lock.secure) {
                availProc.running = true;
                root.buffer = "";
                root.state = "";
                root.fprintState = "";
                root.lockMessage = "";
            }
        }

        function onUnlock(): void {
            fprint.abort();
        }

        target: root.lock
    }

    Connections {
        function onEnableFprintChanged(): void {
            fprint.checkAvail();
        }

        target: GlobalConfig.lock
    }
}
