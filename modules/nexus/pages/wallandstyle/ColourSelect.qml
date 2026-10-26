pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import qs.modules.launcher.services

PageBase {
    id: root

    title: Tr.tr("Colours")
    isSubPage: true

    readonly property int schemesPerRow: 2
    readonly property bool dynamicActive: Colours.scheme === "dynamic"

    function schemeList(filterDynamic: bool): var {
        const list = [...Schemes.list].filter(s => filterDynamic ? s.name === "dynamic" : s.name !== "dynamic");
        list.sort((a, b) => `${a.name} ${a.flavour}`.localeCompare(`${b.name} ${b.flavour}`));
        while (list.length > 0 && list.length % root.schemesPerRow !== 0)
            list.push(null);
        return list;
    }

    Component.onCompleted: Schemes.reload()

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        StyledText {
            text: Tr.tr("Current scheme")
            font: Tokens.font.title.small
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.medium
            implicitHeight: currentRow.implicitHeight + Tokens.padding.large * 2
            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.extraLarge

            RowLayout {
                id: currentRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                CurrentSchemePreview {
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 56
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: Schemes.currentScheme || Tr.tr("Unknown")
                        font: Tokens.font.body.large
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: root.dynamicActive
                        // TRANSLATORS: %1 = Material colour variant name (e.g. tonalspot)
                        text: Tr.tr("Material style: %1").arg(Schemes.currentVariant || "—")
                        color: Colours.palette.m3outline
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }
                }
            }
        }

        ToggleRow {
            first: true
            Layout.bottomMargin: 0
            text: Tr.tr("Dark theme")
            subtext: Tr.tr("Shell and bar colours")
            checked: !Colours.light
            onToggled: Colours.setMode(checked ? "dark" : "light")
        }

        ToggleRow {
            last: true
            Layout.topMargin: Tokens.spacing.extraSmall / 2
            Layout.bottomMargin: Tokens.spacing.medium
            text: Tr.tr("Light apps")
            subtext: Tr.tr("Keep GTK/Qt apps light even if the shell is dark")
            checked: Colours.lightApps
            onToggled: Colours.setLightApps(checked)
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.small
            text: Tr.tr("Colour schemes")
            font: Tokens.font.title.small
        }

        SchemeGrid {
            Layout.fillWidth: true
            model: root.schemeList(false)
        }

        Loader {
            Layout.fillWidth: true
            asynchronous: true
            active: Schemes.list.length === 0
            visible: active

            sourceComponent: StyledRect {
                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.extraLarge
                implicitHeight: loadingLayout.implicitHeight + Tokens.padding.extraExtraLarge * 2

                ColumnLayout {
                    id: loadingLayout

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "palette"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Tr.tr("Loading colour schemes…")
                        color: Colours.palette.m3outline
                        font: Tokens.font.title.small
                    }
                }
            }
        }

        // Dynamic = colours generated from wallpaper; variants live only here
        SectionHeader {
            text: Tr.tr("From wallpaper")
        }

        StyledText {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.small
            Layout.leftMargin: Tokens.padding.small
            text: Tr.tr("Generates a Material You palette from your current wallpaper.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        SchemeGrid {
            Layout.fillWidth: true
            model: root.schemeList(true)
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            spacing: Tokens.spacing.small
            visible: root.dynamicActive

            StyledText {
                text: Tr.tr("Material style")
                font: Tokens.font.title.small
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                text: Tr.tr("How the wallpaper colours are interpreted.")
                color: Colours.palette.m3outline
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                Repeater {
                    model: M3Variants.list

                    VariantRow {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        // Avoid naming this `variant` — clashes with the model role
                        item: modelData
                        variantId: modelData.variant
                        first: index === 0
                        last: index === M3Variants.list.length - 1
                        selected: variantId === Schemes.currentVariant
                        onClicked: Schemes.setVariant(variantId)
                    }
                }
            }
        }
    }

    component SchemeGrid: GridLayout {
        id: grid

        property var model

        columns: root.schemesPerRow
        rowSpacing: Tokens.spacing.medium
        columnSpacing: Tokens.spacing.large
        visible: repeater.count > 0

        Repeater {
            id: repeater

            model: grid.model

            SchemeCard {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                opacity: modelData ? 1 : 0
                enabled: !!modelData
                scheme: modelData
                selected: modelData && `${modelData.name} ${modelData.flavour}` === Schemes.currentScheme
                onClicked: {
                    if (!modelData)
                        return;
                    Schemes.setScheme(modelData.name, modelData.flavour);
                }
            }
        }
    }

    component CurrentSchemePreview: Item {
        implicitWidth: 48
        implicitHeight: 48

        StyledRect {
            anchors.fill: parent
            radius: Tokens.rounding.large
            color: Colours.palette.m3surface
            border.width: 1
            border.color: Qt.alpha(Colours.palette.m3outline, 0.5)
            clip: true

            Column {
                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                spacing: Tokens.spacing.extraSmall

                Row {
                    spacing: Tokens.spacing.extraSmall
                    width: parent.width

                    Repeater {
                        model: [
                            Colours.palette.m3primary,
                            Colours.palette.m3secondary,
                            Colours.palette.m3tertiary,
                            Colours.palette.m3error
                        ]

                        StyledRect {
                            required property color modelData

                            width: (parent.width - parent.spacing * 3) / 4
                            height: width
                            radius: Tokens.rounding.full
                            color: modelData
                        }
                    }
                }

                StyledRect {
                    width: parent.width
                    height: Math.max(Tokens.padding.small, parent.height - y - parent.spacing)
                    radius: Tokens.rounding.small
                    color: Colours.palette.m3primaryContainer
                }
            }
        }
    }

    component SchemeCard: Item {
        id: card

        property var scheme
        property bool selected
        signal clicked

        implicitHeight: cardLayout.implicitHeight

        StateLayer {
            z: 1
            radius: Tokens.rounding.largeIncreased
            onClicked: card.clicked()
        }

        ColumnLayout {
            id: cardLayout

            anchors.fill: parent
            spacing: Tokens.spacing.small

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: width * 0.72
                radius: Tokens.rounding.largeIncreased
                color: `#${card.scheme?.colours?.surface ?? "191114"}`
                border.width: card.selected ? 2 : 1
                border.color: card.selected ? Colours.palette.m3primary : Qt.alpha(`#${card.scheme?.colours?.outline ?? "514347"}`, 0.45)
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    spacing: Tokens.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall

                        Repeater {
                            model: [
                                card.scheme?.colours?.primary,
                                card.scheme?.colours?.secondary,
                                card.scheme?.colours?.tertiary,
                                card.scheme?.colours?.error
                            ]

                            StyledRect {
                                required property var modelData

                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                radius: Tokens.rounding.full
                                color: `#${modelData ?? "888888"}`
                                visible: !!modelData
                            }
                        }
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Tokens.rounding.medium
                        color: `#${card.scheme?.colours?.primaryContainer ?? card.scheme?.colours?.secondaryContainer ?? "31282a"}`

                        Row {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.margins: Tokens.padding.small
                            spacing: Tokens.spacing.extraSmall

                            StyledRect {
                                width: 18
                                height: 18
                                radius: Tokens.rounding.full
                                color: `#${card.scheme?.colours?.primary ?? "ffb0ca"}`
                            }

                            StyledRect {
                                width: 18
                                height: 18
                                radius: Tokens.rounding.full
                                color: `#${card.scheme?.colours?.secondary ?? "e2bdc7"}`
                            }

                            StyledRect {
                                width: 18
                                height: 18
                                radius: Tokens.rounding.full
                                color: `#${card.scheme?.colours?.tertiary ?? "f0bc95"}`
                            }
                        }

                        Loader {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Tokens.padding.small
                            active: card.selected
                            asynchronous: true

                            sourceComponent: StyledRect {
                                implicitWidth: checkIcon.implicitWidth + Tokens.padding.small * 2
                                implicitHeight: implicitWidth
                                radius: Tokens.rounding.full
                                color: Colours.palette.m3primary

                                MaterialIcon {
                                    id: checkIcon

                                    anchors.centerIn: parent
                                    text: "check"
                                    color: Colours.palette.m3onPrimary
                                    fontStyle: Tokens.font.icon.small
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: Tokens.padding.small
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: card.scheme?.flavour ?? ""
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: card.scheme?.name ?? ""
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }
        }
    }

    component VariantRow: ConnectedRect {
        id: variantRow

        property var item
        property string variantId
        property bool selected
        signal clicked

        implicitHeight: variantInner.implicitHeight + Tokens.padding.medium * 2

        StateLayer {
            anchors.fill: parent
            onClicked: variantRow.clicked()
        }

        RowLayout {
            id: variantInner

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: variantRow.item?.icon ?? "palette"
                fontStyle: Tokens.font.icon.large
                color: variantRow.selected ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: variantRow.item?.name ?? ""
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: variantRow.item?.description ?? ""
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }
            }

            Loader {
                active: variantRow.selected
                asynchronous: true

                sourceComponent: MaterialIcon {
                    text: "check"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.large
                }
            }
        }
    }
}
