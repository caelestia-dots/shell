import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Multimedia
import qs.services

Scope {
    id: root

    property bool cooldownPending
    property real lastBaseTransparency

    function reloadHyprRules(): void {
        let rule, blur;
        if (Hypr.usingLua) {
            rule = `eval hl.layer_rule({ match = { namespace = "caelestia-drawers" }, %1 = %2 })`;
            blur = Tokens.transparency.enabled && Tokens.transparency.blurEnabled;
        } else {
            rule = "keyword layerrule %1 %2, match:namespace caelestia-drawers";
            blur = Tokens.transparency.enabled && Tokens.transparency.blurEnabled ? 1 : 0;
        }
        Hypr.extras.batchMessage([rule.arg("blur").arg(blur), rule.arg("ignore_alpha").arg(Math.max(0, Tokens.transparency.base - 0.03))]);
    }

    function requestReloadHyprRules(): void {
        if (cooldownTimer.running) {
            cooldownPending = true;
        } else {
            reloadHyprRules();
            cooldownTimer.restart();
        }
    }

    Component.onCompleted: root.requestReloadHyprRules()

    Connections {
        function onConfigReloaded(): void {
            root.reloadHyprRules();
        }

        target: Hypr
    }

    Connections {
        function onEnabledChanged(): void {
            if (enabled)
                root.requestReloadHyprRules();
            else
                cAnimCompleteTimer.start();
        }

        function onBlurEnabledChanged(): void {
            root.requestReloadHyprRules();
        }

        function onBaseChanged(): void {
            if (root.lastBaseTransparency > Tokens.transparency.base)
                root.requestReloadHyprRules();
            else
                cAnimCompleteTimer.start();
            root.lastBaseTransparency = Tokens.transparency.base;
        }

        target: Tokens.transparency
    }

    Timer {
        id: cooldownTimer

        interval: 30
        onTriggered: {
            if (root.cooldownPending) {
                root.cooldownPending = false;
                root.reloadHyprRules();
                restart();
            }
        }
    }

    Timer {
        id: cAnimCompleteTimer

        interval: Tokens.anim.durations.expressiveSlowEffects
        onTriggered: root.requestReloadHyprRules()
    }
}
