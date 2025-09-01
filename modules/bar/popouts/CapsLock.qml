import qs.components
import qs.services

StyledText {
    animate: true
    text: qsTr("Capslock: %1").arg(Hypr.capsLock ? "Enabled" : "Disabled")
}
