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
    readonly property alias howdy: howdy
    readonly property alias fprint: dummyFprint

    property string lockMessage
    property string state
    property string fprintState: ""
    property string buffer: ""

    signal flashMsg

    function handleKey(event: KeyEvent): void {
        if (passwd.active || state === "max")
            return;

        if (howdy.active && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Return) {
            howdy.abort();
        }

        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            if (buffer.length === 0) {
                if (howdy.available) howdy.trigger();
            } else {
                if (howdy.active) howdy.abort();
                passwd.start();
            }
        } else if (event.key === Qt.Key_Backspace) {
            if (event.modifiers & Qt.ControlModifier) {
                buffer = "";
            } else {
                buffer = buffer.slice(0, -1);
            }
        } else if (/^[^\x00-\x1F\x7F-\x9F]+$/.test(event.text)) {
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
            if (!responseRequired) return;
            respond(root.buffer);
            root.buffer = "";
        }

        onCompleted: res => {
            if (res === PamResult.Success) return root.lock.unlock();
            if (res === PamResult.Error) root.state = "error";
            else if (res === PamResult.MaxTries) root.state = "max";
            else if (res === PamResult.Failed) root.state = "fail";

            root.flashMsg();
            stateReset.restart();
        }
    }

    PamContext {
        id: howdy
        property bool available: false

        function trigger(): void {
            if (!available || !root.lock.secure) return;
            start();
        }

        config: "howdy" 
        configDirectory: Quickshell.shellDir + "/assets/pam.d"

        onCompleted: res => {
            if (res === PamResult.Success) return root.lock.unlock();
            else abort(); 
        }
    }

    QtObject {
        id: dummyFprint
        property bool available: false
        property bool active: false
        property int tries: 0
        property string message: ""
        function abort() {}
    }

    Process {
        id: howdyAvailProc
        command: ["sh", "-c", "command -v howdy"]
        onExited: code => { 
            howdy.available = code === 0;
        }
    }

    Timer {
        id: stateReset
        interval: 4000
        onTriggered: {
            if (root.state !== "max") root.state = "";
        }
    }

    Connections {
        target: root.lock
        
        function onSecureChanged(): void {
            if (root.lock.secure) {
                howdyAvailProc.running = true; 
                root.buffer = "";
                root.state = "";
                root.lockMessage = "";
            }
        }

        function onUnlock(): void {
            howdy.abort();
            passwd.abort();
        }
    }
}
