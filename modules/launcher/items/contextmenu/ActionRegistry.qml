pragma Singleton
import qs.utils
import qs.config
import Quickshell
import QtQuick

QtObject {
    id: registry

    readonly property var presets: ({
            "launch": {
                text: qsTr("Launch"),
                icon: "play_arrow",
                hasSubmenu: true,
                bold: true,
                execute: function (app, context) {
                    if (app) {
                        context.launchApp();
                        if (context.visibilities)
                            context.visibilities.launcher = false;
                        context.toggle();
                    }
                }
            },
            "workspaces": {
                text: qsTr("Open in Workspace"),
                icon: "workspaces",
                hasSubmenu: true
            },
            "categories": {
                text: qsTr("Assign Categories"),
                icon: "category",
                hasSubmenu: true
            },
            "favorites": {
                text: qsTr("Add to Favourites"),
                icon: "favorite",
                dynamicText: true,
                execute: function (app, context) {
                    if (!app || !app.id)
                        return context.toggle();
                    const favourites = Config.launcher.favouriteApps.slice();
                    const index = favourites.indexOf(app.id);
                    if (index > -1)
                        favourites.splice(index, 1);
                    else
                        favourites.push(app.id);
                    Config.launcher.favouriteApps = favourites;
                    Config.save();
                    context.toggle();
                }
            },
            "hide": {
                text: qsTr("Hide from Launcher"),
                icon: "visibility_off",
                execute: function (app, context) {
                    if (!app || !app.id)
                        return context.toggle();
                    const hidden = Config.launcher.hiddenApps.slice();
                    hidden.push(app.id);
                    Config.launcher.hiddenApps = hidden;
                    Config.save();
                    if (context.visibilities)
                        context.visibilities.launcher = false;
                    context.toggle();
                }
            },
            "desktop-file": {
                text: qsTr("Open .desktop File"),
                icon: "description",
                execute: function (app, context) {
                    if (!app || !app.id)
                        return;
                    Quickshell.execDetached({
                        command: ["sh", "-c", `file=$(find ~/.local/share/applications /usr/share/applications /usr/local/share/applications /var/lib/flatpak/exports/share/applications ~/.local/share/flatpak/exports/share/applications -name '${app.id}.desktop' 2>/dev/null | head -n1); [ -n "$file" ] && xdg-open "$file"`]
                    });
                    context.toggle();
                }
            }
        })

    readonly property var actions: ({
            "terminal": {
                text: qsTr("Run in Terminal"),
                icon: "terminal",
                execute: function (app, context) {
                    if (!app || !app.execString)
                        return;
                    Quickshell.execDetached({
                        command: [...Config.general.apps.terminal, "-e", app.execString]
                    });
                    if (context.visibilities)
                        context.visibilities.launcher = false;
                    context.toggle();
                }
            },
            "kill": {
                text: qsTr("Force Quit"),
                icon: "close",
                execute: function (app, context) {
                    if (!app || !app.execString)
                        return;
                    const execName = app.execString.split(" ")[0].split("/").pop();
                    Quickshell.execDetached({
                        command: ["pkill", "-9", "-f", execName]
                    });
                    context.toggle();
                }
            },
            "open-path": {
                text: qsTr("Open App Location"),
                icon: "folder_open",
                execute: function (app, context) {
                    if (!app || !app.execString)
                        return;
                    const execPath = app.execString.split(" ")[0];
                    Quickshell.execDetached({
                        command: ["sh", "-c", `realpath=$(which "${execPath}" 2>/dev/null || realpath "${execPath}" 2>/dev/null); [ -n "$realpath" ] && ${Config.general.apps.explorer.join(" ")} "$(dirname "$realpath")"`]
                    });
                    context.toggle();
                }
            },
            "copy-exec": {
                text: qsTr("Copy Command"),
                icon: "content_copy",
                execute: function (app, context) {
                    if (!app || !app.execString)
                        return;
                    Quickshell.execDetached({
                        command: ["sh", "-c", `echo -n "${app.execString}" | wl-copy`]
                    });
                    context.toggle();
                }
            }
        })

    readonly property string defaultSubmenuIcon: "folder"

    function isPreset(id) {
        return presets.hasOwnProperty(id);
    }

    function isAction(id) {
        return actions.hasOwnProperty(id);
    }

    function isKnown(id) {
        return id === "separator" || isPreset(id) || isAction(id);
    }

    function getDefaults(id) {
        if (id === "separator") {
            return {
                type: "separator"
            };
        }
        if (presets.hasOwnProperty(id)) {
            return Object.assign({
                type: "preset"
            }, presets[id]);
        }
        if (actions.hasOwnProperty(id)) {
            return Object.assign({
                type: "action"
            }, actions[id]);
        }
        return {
            type: "custom",
            text: id,
            icon: defaultSubmenuIcon
        };
    }

    function getText(id, config, app) {
        if (id === "favorites" && app) {
            const isFavorite = app.id && Strings.testRegexList(Config.launcher.favouriteApps, app.id);
            return isFavorite ? qsTr("Remove from Favourites") : qsTr("Add to Favourites");
        }

        if (config && config.text) {
            return config.text;
        }

        const defaults = getDefaults(id);
        return defaults.text || id;
    }

    function getIcon(id, config) {
        if (config && config.icon) {
            return config.icon;
        }

        const defaults = getDefaults(id);
        return defaults.icon || defaultSubmenuIcon;
    }

    function execute(actionId, config, app, context) {
        const defaults = getDefaults(actionId);

        if (defaults.execute) {
            defaults.execute(app, context);
        } else if (config && config.command) {
            executeCustomCommand(config.command, app, context);
        }
    }

    function executeCustomCommand(command, app, context) {
        if (!Array.isArray(command))
            return;

        const processedCommand = command.map(arg => {
            if (typeof arg !== "string")
                return arg;
            return arg.replace(/\$appId/g, app?.id || "").replace(/\$appName/g, app?.name || "").replace(/\$execString/g, app?.execString || "").replace(/\$desktopPath/g, app?.desktopPath || "").replace(/\$iconName/g, app?.iconName || "");
        });

        Quickshell.execDetached({
            command: processedCommand
        });
        context.toggle();
    }
}
