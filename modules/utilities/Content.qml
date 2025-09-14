import "cards"
import qs.config
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var visibilities

    spacing: Appearance.spacing.normal

    IdleInhibit {}

    GameMode {}

    Toggles {
        visibilities: root.visibilities
    }
}
