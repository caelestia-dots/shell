import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Caelestia.Config

Scope {
    id: root

    signal unlocked
    signal failed(string message)

    property string pending

    function submit(text: string): void {
        if (ctx.responseRequired) {
            ctx.respond(text);
            return;
        }

        if (ctx.active)
            return;

        pending = text;
        ctx.start();
    }

    PamContext {
        id: ctx

        config: GlobalConfig.lock.pamService || "passwd"
        configDirectory: GlobalConfig.lock.pamService ? "/etc/pam.d" : Quickshell.shellPath("assets/pam.d")

        onResponseRequiredChanged: {
            if (!responseRequired || root.pending === "")
                return;

            respond(root.pending);
            root.pending = "";
        }

        onCompleted: res => {
            root.pending = "";

            if (res === PamResult.Success) {
                root.unlocked();
                return;
            }

            root.failed(message.length > 0 ? message : "Authentication failed");
        }
    }
}
