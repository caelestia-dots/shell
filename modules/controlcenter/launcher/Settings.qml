pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Session session

    spacing: Appearance.spacing.normal

    SettingsHeader {
        icon: "apps"
        title: qsTr("Launcher Settings")
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("General")
        description: qsTr("General launcher settings")
    }

    SectionContainer {
        ToggleRow {
            label: qsTr("Enabled")
            checked: Config.launcher.enabled
            toggle.onToggled: {
                Config.launcher.enabled = checked;
                Config.save();
            }
        }

        ToggleRow {
            label: qsTr("Show on hover")
            checked: Config.launcher.showOnHover
            toggle.onToggled: {
                Config.launcher.showOnHover = checked;
                Config.save();
            }
        }

        ToggleRow {
            label: qsTr("Vim keybinds")
            checked: Config.launcher.vimKeybinds
            toggle.onToggled: {
                Config.launcher.vimKeybinds = checked;
                Config.save();
            }
        }

        ToggleRow {
            label: qsTr("Enable dangerous actions")
            checked: Config.launcher.enableDangerousActions
            toggle.onToggled: {
                Config.launcher.enableDangerousActions = checked;
                Config.save();
            }
        }
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("Display")
        description: qsTr("Display and appearance settings")
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.small / 2

        PropertyRow {
            label: qsTr("Max shown items")
            value: qsTr("%1").arg(Config.launcher.maxShown)
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Max wallpapers")
            value: qsTr("%1").arg(Config.launcher.maxWallpapers)
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Drag threshold")
            value: qsTr("%1 px").arg(Config.launcher.dragThreshold)
        }
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("Prefixes")
        description: qsTr("Command prefix settings")
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.small / 2

        PropertyRow {
            label: qsTr("Special prefix")
            value: Config.launcher.specialPrefix || qsTr("None")
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Action prefix")
            value: Config.launcher.actionPrefix || qsTr("None")
        }
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("Fuzzy search")
        description: qsTr("Fuzzy search settings")
    }

    SectionContainer {
        ToggleRow {
            label: qsTr("Apps")
            checked: Config.launcher.useFuzzy.apps
            toggle.onToggled: {
                Config.launcher.useFuzzy.apps = checked;
                Config.save();
            }
        }

        ToggleRow {
            label: qsTr("Actions")
            checked: Config.launcher.useFuzzy.actions
            toggle.onToggled: {
                Config.launcher.useFuzzy.actions = checked;
                Config.save();
            }
        }

        ToggleRow {
            label: qsTr("Schemes")
            checked: Config.launcher.useFuzzy.schemes
            toggle.onToggled: {
                Config.launcher.useFuzzy.schemes = checked;
                Config.save();
            }
        }

        ToggleRow {
            label: qsTr("Variants")
            checked: Config.launcher.useFuzzy.variants
            toggle.onToggled: {
                Config.launcher.useFuzzy.variants = checked;
                Config.save();
            }
        }

        ToggleRow {
            label: qsTr("Wallpapers")
            checked: Config.launcher.useFuzzy.wallpapers
            toggle.onToggled: {
                Config.launcher.useFuzzy.wallpapers = checked;
                Config.save();
            }
        }
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("Sizes")
        description: qsTr("Size settings for launcher items")
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.small / 2

        PropertyRow {
            label: qsTr("Item width")
            value: qsTr("%1 px").arg(Config.launcher.sizes.itemWidth)
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Item height")
            value: qsTr("%1 px").arg(Config.launcher.sizes.itemHeight)
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Wallpaper width")
            value: qsTr("%1 px").arg(Config.launcher.sizes.wallpaperWidth)
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Wallpaper height")
            value: qsTr("%1 px").arg(Config.launcher.sizes.wallpaperHeight)
        }
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("Hidden apps")
        description: qsTr("Applications hidden from launcher")
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.small / 2

        PropertyRow {
            label: qsTr("Total hidden")
            value: qsTr("%1").arg(Config.launcher.hiddenApps ? Config.launcher.hiddenApps.length : 0)
        }
    }
}

