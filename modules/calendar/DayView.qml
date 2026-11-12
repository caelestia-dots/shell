pragma Singleton

import QtQuick
import Quickshell

// Day panel of the notch calendar: which day is unfolded over the week view
Singleton {
    id: root

    property date date: new Date()
    property bool shown

    function open(date: date): void {
        root.date = date;
        shown = true;
    }

    function close(): void {
        shown = false;
    }
}
