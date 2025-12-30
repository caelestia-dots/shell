pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property bool visible: false

    signal open()
    signal close()

    function toggle(): void {
        visible = !visible;
    }

    function show(): void {
        visible = true;
        open();
    }

    function hide(): void {
        visible = false;
        close();
    }
}
