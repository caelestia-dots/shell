pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

Variants {
    model: Screens.screens

    Scope {
        id: scope

        required property ShellScreen modelData

        Exclusions {
            screen: scope.modelData
            bar: content.bar
            geometry: content.geometry
        }

        ContentWindow {
            id: content

            screen: scope.modelData
        }
    }
}
