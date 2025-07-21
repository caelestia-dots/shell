pragma Singleton

import ".."
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick

Searcher {
    id: root

    readonly property list<Action> actions: [
        Action {
            name: qsTr("Calculator")
            desc: qsTr("Do simple math equations (powered by Qalc)")
            icon: "calculate"

            function onClicked(list: AppList): void {
                root.autocomplete(list, "calc");
            }
        },
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
            disabled: true

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
            disabled: !Config.launcher.enableDangerousActions

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                Quickshell.execDetached(["systemctl", "poweroff"]);
            }
        },
        Action {
            name: qsTr("Reboot")
            desc: qsTr("Reboot the system")
            icon: "cached"
            disabled: !Config.launcher.enableDangerousActions

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                Quickshell.execDetached(["systemctl", "reboot"]);
            }
        },
        Action {
            name: qsTr("Logout")
            desc: qsTr("Log out of the current session")
            icon: "exit_to_app"
            disabled: !Config.launcher.enableDangerousActions

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                Quickshell.execDetached(["loginctl", "terminate-user", ""]);
            }
        },
        Action {
            name: qsTr("Lock")
            desc: qsTr("Lock the current session")
            icon: "lock"

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                Quickshell.execDetached(["loginctl", "lock-session"]);
            }
        },
        Action {
            name: qsTr("Sleep")
            desc: qsTr("Suspend then hibernate")
            icon: "bedtime"

            function onClicked(list: AppList): void {
                list.visibilities.launcher = false;
                Quickshell.execDetached(["systemctl", "suspend-then-hibernate"]);
            }
        }
    ]

    function transformSearch(search: string): string {
        return search.slice(Config.launcher.actionPrefix.length);
    }

    function autocomplete(list: AppList, text: string): void {
        list.search.text = `${Config.launcher.actionPrefix}${text} `;
    }

    list: actions.filter(a => !a.disabled)
    useFuzzy: Config.launcher.useFuzzy.actions

    component Action: QtObject {
        required property string name
        required property string desc
        required property string icon
        property bool disabled

        function onClicked(list: AppList): void {
        }
    }
}
