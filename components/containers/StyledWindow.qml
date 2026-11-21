import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.services

// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type

    enum AnimType {
        NoAnim,
        Fade
    }

    required property string name
    property int animType: StyledWindow.Fade

    WlrLayershell.namespace: `caelestia-${name}`
    color: "transparent"

    contentItem.Config.screen: screen.name
    contentItem.Tokens.screen: screen.name

    Component.onCompleted: {
        const rule = {
            match: {
                namespace: WlrLayershell.namespace
            }
        };
        if (animType === StyledWindow.Fade)
            rule.animation = "fade";
        else if (animType === StyledWindow.NoAnim)
            rule.no_anim = true;

        Hypr.extras.registerLayerRule(rule);
    }
}
