pragma Singleton

import QtQuick
import QtMultimedia

Item {
    signal toggleRequested

    property bool shouldPlay: false
    property var firstInstance: null

    function play(): void {
        shouldPlay = true;
        toggleRequested();
    }

    function stop(): void {
        shouldPlay = false;
        toggleRequested();
    }

    function toggle(): void {
        shouldPlay = !shouldPlay;
        toggleRequested();
    }
}