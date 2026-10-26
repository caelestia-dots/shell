pragma Singleton

import QtQuick

QtObject {
    property var current: null

    function activate(menu: var): void {
        if (current && current !== menu)
            current.expanded = false;
        current = menu;
    }

    function deactivate(menu: var): void {
        if (current === menu)
            current = null;
    }
}
