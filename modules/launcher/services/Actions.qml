pragma Singleton

import ".."
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick

Searcher {
    id: root

    readonly property var actions: {
        const allActions = [];

        for (let i = 0; i < Config.launcher.actions.length; i++) {
            const action = Config.launcher.actions[i];
            const enabled = action.enabled ?? true;
            const dangerous = action.dangerous ?? false;

            if (!action) continue;
            if (!enabled) continue;
            if (dangerous && !Config.launcher.enableDangerousActions) continue;

            allActions.push(actionComponent.createObject(root, {
                name: action.name || "Unnamed",
                desc: action.description || "No description",
                icon: action.icon || "help_outline",
                action: action
            }));
        }

        return allActions;
    }

    function transformSearch(search: string): string {
        return search.slice(Config.launcher.actionPrefix.length);
    }

    function autocomplete(list: AppList, text: string): void {
        list.search.text = `${Config.launcher.actionPrefix}${text} `;
    }

    function executeCommand(command: list<string>, list: AppList): void {
        if (command.length === 0) return;

        const commandType = command[0];

        if (commandType === "autocomplete" && command.length > 1) {
            root.autocomplete(list, command[1]);
        } else if (commandType === "internal" && command.length > 1) {
            list.visibilities.launcher = false;

            if (command[1] === "setLightMode") {
                Colours.setMode("light");
            } else if (command[1] === "setDarkMode") {
                Colours.setMode("dark");
            }
        } else {
            list.visibilities.launcher = false;
            Quickshell.execDetached(command);
        }
    }

    list: actions
    useFuzzy: Config.launcher.useFuzzy.actions

    Component {
        id: actionComponent

        QtObject {
            required property string name
            required property string desc
            required property string icon
            required property var action

            function onClicked(list: AppList): void {
                root.executeCommand([...action.command], list);
            }
        }
    }
}