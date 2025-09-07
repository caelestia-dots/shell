import qs.components
import qs.services

StyledText {
    text: qsTr("Microphone: %1").arg(Audio.sourceMuted ? "Muted" : "Unmuted")
}
