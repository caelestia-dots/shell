pragma Singleton

import QtQuick
import Quickshell

Item {
    id: root

    property Item firstInstance: null
    property bool soundEnabled: false
}