pragma Singleton

import "root:/utils/scripts/fuzzysort.js" as Fuzzy
import "root:/services"
import "root:/config"
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property list<Action> list: [
        Action {
            name: qsTr("Scheme")
            desc: qsTr("Change the current colour scheme")
            icon: "palette"

            function onClicked(list: AppList): void {
                root.autocomplete(list, "scheme");
            }
        },
        Action {
            name: qsTr("Wallpaper")
            desc: qsTr("Change the current wallpaper")
            icon: "image"

            function onClicked(list: AppList): void {
                root.autocomplete(list, "wallpaper");
            }
        },
        Action {
            name: qsTr("Variant")
            desc: qsTr("Change the current scheme variant")
            icon: "colors"

            function onClicked(list: AppList): void {
                root.autocomplete(list, "variant");
            }
        },
        Action {
            name: qsTr("Transparency")
            desc: qsTr("Change shell transparency")
            icon: "opacity"

            function onClicked(list: AppList): void {
                root.autocomplete(list, "transparency");
            }
        },
        Action {
            name: qsTr("Light")
            desc: qsTr("Change the scheme to light mode")
            icon: "light_mode"

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                Colours.setMode("light");
            }
        },
        Action {
            name: qsTr("Dark")
            desc: qsTr("Change the scheme to dark mode")
            icon: "dark_mode"

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                Colours.setMode("dark");
            }
        },
        Action {
            name: qsTr("Shutdown")
            desc: qsTr("Shutdown the system")
            icon: "power_settings_new"
            disabled: !LauncherConfig.allowDangerousActions
            disabledReason: qsTr("Enable dangerous actions in config/LauncherConfig.qml first")

            function onClicked(list: AppList): void {
                root.handleDangerousAction(list, shutdown);
            }
        },
        Action {
            name: qsTr("Reboot")
            desc: qsTr("Reboot the system")
            icon: "cached"
            disabled: !LauncherConfig.allowDangerousActions
            disabledReason: qsTr("Enable dangerous actions in config/LauncherConfig.qml first")

            function onClicked(list: AppList): void {
                root.handleDangerousAction(list, reboot);
            }
        },
        Action {
            name: qsTr("Logout")
            desc: qsTr("Logout of the current session")
            icon: "exit_to_app"
            disabled: !LauncherConfig.allowDangerousActions
            disabledReason: qsTr("Enable dangerous actions in config/LauncherConfig.qml first")

            function onClicked(list: AppList): void {
                root.handleDangerousAction(list, logout);
            }
        },
        Action {
            name: qsTr("Lock")
            desc: qsTr("Lock the current session")
            icon: "lock"

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                lock.running = true;
            }
        },
        Action {
            name: qsTr("Sleep")
            desc: qsTr("Suspend then hibernate")
            icon: "bedtime"

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                sleep.running = true;
            }
        }
    ]

    readonly property list<var> preppedActions: list.map(a => ({
                name: Fuzzy.prepare(a.name),
                desc: Fuzzy.prepare(a.desc),
                action: a
            }))

    function fuzzyQuery(search: string): var {
        return Fuzzy.go(search.slice(LauncherConfig.actionPrefix.length), preppedActions, {
            all: true,
            keys: ["name", "desc"],
            scoreFn: r => r[0].score > 0 ? r[0].score * 0.9 + r[1].score * 0.1 : 0
        }).map(r => r.obj.action);
    }

    function autocomplete(list: AppList, text: string): void {
        list.search.text = `${LauncherConfig.actionPrefix}${text} `;
    }

    function handleDangerousAction(list: AppList, process: QtObject): void {
        list.visibilities.launcher = false;
        if (!LauncherConfig.allowDangerousActions) {
            dangerousActions.running = true;
            return;
        }
        process.running = true;
    }

    Process {
        id: dangerousActions

        command: ["notify-send", "Quickshell", qsTr("Enable dangerous actions in config/LauncherConfig.qml to use this action."), "-i", "dialog-warning"]
    }

    Process {
        id: shutdown

        command: ["systemctl", "poweroff"]
    }

    Process {
        id: reboot

        command: ["systemctl", "reboot"]
    }

    Process {
        id: logout

        command: ["sh", "-c", "(uwsm stop | grep -q 'Compositor is not running' && loginctl terminate-user $USER) || uwsm stop"]
    }   

    Process {
        id: lock

        command: ["loginctl", "lock-session"]
    }

    Process {
        id: sleep

        command: ["systemctl", "suspend-then-hibernate"]
    }

    component Action: QtObject {
        required property string name
        required property string desc
        required property string icon
        property bool disabled
        property string disabledReason

        function onClicked(list: AppList): void {
        }
    }
}
