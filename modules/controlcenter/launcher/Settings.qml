pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.config
import QtQuick
import QtQuick.Controls
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
        title: qsTr("Categories")
        description: qsTr("Manage launcher categories")
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.smaller

        ToggleRow {
            Layout.bottomMargin: Appearance.spacing.normal
            label: qsTr("Enable categories")
            checked: Config.launcher.enableCategories
            toggle.onToggled: {
                Config.launcher.enableCategories = checked;
                Config.save();
            }
        }

        TextButton {
            Layout.fillWidth: true
            text: qsTr("+ Add Category")
            inactiveColour: Colours.palette.m3primaryContainer
            inactiveOnColour: Colours.palette.m3onPrimaryContainer

            onClicked: {
                editCategoryDialog.editIndex = -1;
                editCategoryDialog.categoryName = "";
                editCategoryDialog.categoryIcon = "";
                editCategoryDialog.open();
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            interactive: false
            spacing: Appearance.spacing.smaller

            model: Config.launcher.categories

            delegate: StyledRect {
                required property var modelData
                required property int index

                width: ListView.view ? ListView.view.width : undefined
                color: Colours.tPalette.m3surfaceContainerHigh
                radius: Appearance.rounding.normal

                implicitHeight: categoryRow.implicitHeight + Appearance.padding.normal * 2

                RowLayout {
                    id: categoryRow
                    anchors.fill: parent
                    anchors.leftMargin: Appearance.padding.normal
                    anchors.rightMargin: Appearance.padding.normal
                    anchors.topMargin: Appearance.padding.normal
                    anchors.bottomMargin: Appearance.padding.normal
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: modelData.icon
                        color: Colours.palette.m3onSurface
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: Colours.palette.m3onSurface
                    }

                    IconButton {
                        type: IconButton.Tonal
                        icon: "arrow_upward"
                        radius: Appearance.rounding.normal
                        visible: index > 0
                        onClicked: {
                            const categories = [...Config.launcher.categories];
                            const temp = categories[index];
                            categories[index] = categories[index - 1];
                            categories[index - 1] = temp;
                            Config.launcher.categories = categories;
                            Config.save();
                        }
                    }

                    IconButton {
                        type: IconButton.Tonal
                        icon: "arrow_downward"
                        radius: Appearance.rounding.normal
                        visible: index < Config.launcher.categories.length - 1
                        onClicked: {
                            const categories = [...Config.launcher.categories];
                            const temp = categories[index];
                            categories[index] = categories[index + 1];
                            categories[index + 1] = temp;
                            Config.launcher.categories = categories;
                            Config.save();
                        }
                    }

                    IconButton {
                        type: IconButton.Tonal
                        icon: "edit"
                        radius: Appearance.rounding.normal
                        onClicked: {
                            editCategoryDialog.editIndex = index;
                            editCategoryDialog.categoryName = modelData.name;
                            editCategoryDialog.categoryIcon = modelData.icon;
                            editCategoryDialog.open();
                        }
                    }

                    IconButton {
                        type: IconButton.Tonal
                        icon: "delete"
                        radius: Appearance.rounding.normal
                        onClicked: {
                            const categories = [...Config.launcher.categories];
                            categories.splice(index, 1);
                            Config.launcher.categories = categories;
                            Config.save();
                        }
                    }
                }
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

    Popup {
        id: editCategoryDialog

        property int editIndex: -1
        property string categoryName: ""
        property string categoryIcon: ""

        parent: Overlay.overlay
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        implicitWidth: Math.min(400, parent.width - Appearance.padding.large * 2)
        padding: Appearance.padding.large

        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: StyledRect {
            color: Colours.palette.m3surfaceContainerHigh
            radius: Appearance.rounding.large
        }

        contentItem: ColumnLayout {
            spacing: Appearance.spacing.normal

            StyledText {
                text: editCategoryDialog.editIndex === -1 ? qsTr("Add Category") : qsTr("Edit Category")
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Configure category name and icon")
                wrapMode: Text.WordWrap
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            TextField {
                id: categoryNameField
                Layout.fillWidth: true
                placeholderText: qsTr("Category name")
                text: editCategoryDialog.categoryName
                onTextChanged: editCategoryDialog.categoryName = text
            }

            TextField {
                id: categoryIconField
                Layout.fillWidth: true
                placeholderText: qsTr("Icon name (e.g., folder, code)")
                text: editCategoryDialog.categoryIcon
                onTextChanged: editCategoryDialog.categoryIcon = text
            }

            Item { Layout.preferredHeight: Appearance.spacing.normal }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                TextButton {
                    Layout.fillWidth: true
                    text: qsTr("Cancel")
                    inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                    inactiveOnColour: Colours.palette.m3onSurface

                    onClicked: editCategoryDialog.close()
                }

                TextButton {
                    Layout.fillWidth: true
                    text: editCategoryDialog.editIndex === -1 ? qsTr("Add") : qsTr("Save")
                    enabled: editCategoryDialog.categoryName.length > 0 && editCategoryDialog.categoryIcon.length > 0
                    inactiveColour: Colours.palette.m3primaryContainer
                    inactiveOnColour: Colours.palette.m3onPrimaryContainer

                    onClicked: {
                        const categories = [...Config.launcher.categories];
                        const newCategory = {
                            name: editCategoryDialog.categoryName,
                            icon: editCategoryDialog.categoryIcon
                        };

                        if (editCategoryDialog.editIndex === -1) {
                            categories.push(newCategory);
                        } else {
                            categories[editCategoryDialog.editIndex] = newCategory;
                        }

                        Config.launcher.categories = categories;
                        Config.save();
                        editCategoryDialog.close();
                    }
                }
            }
        }
    }
}
