pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.config

Variants {
    model: Screens.screens

    Scope {
        id: scope

        required property ShellScreen modelData

        Exclusions {
            screen: scope.modelData
            bar: content.bar
            borderThickness: Config.border.thickness
        }

        ContentWindow {
            id: content

            screen: scope.modelData
        }
    }
}
