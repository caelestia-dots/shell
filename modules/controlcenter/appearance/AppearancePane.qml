pragma ComponentBehavior: Bound

import ".."
import "../components"
import "./sections"
import "../../launcher/services"
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.components.images
import qs.services
import qs.config
import qs.utils
import Caelestia.Models
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session

    property real animDurationsScale: Config.appearance.anim.durations.scale ?? 1
    property string fontFamilyMaterial: Config.appearance.font.family.material ?? "Material Symbols Rounded"
    property string fontFamilyMono: Config.appearance.font.family.mono ?? "CaskaydiaCove NF"
    property string fontFamilySans: Config.appearance.font.family.sans ?? "Rubik"
    property real fontSizeScale: Config.appearance.font.size.scale ?? 1
    property real paddingScale: Config.appearance.padding.scale ?? 1
    property real roundingScale: Config.appearance.rounding.scale ?? 1
    property real spacingScale: Config.appearance.spacing.scale ?? 1
    property bool transparencyEnabled: Config.appearance.transparency.enabled ?? false
    property real transparencyBase: Config.appearance.transparency.base ?? 0.85
    property real transparencyLayers: Config.appearance.transparency.layers ?? 0.4
    property real borderRounding: Config.border.rounding ?? 1
    property real borderThickness: Config.border.thickness ?? 1

    property bool desktopClockEnabled: Config.background.desktopClock.enabled ?? false
    property bool backgroundEnabled: Config.background.enabled ?? true
    property bool visualiserEnabled: Config.background.visualiser.enabled ?? false
    property bool visualiserAutoHide: Config.background.visualiser.autoHide ?? true
    property real visualiserRounding: Config.background.visualiser.rounding ?? 1
    property real visualiserSpacing: Config.background.visualiser.spacing ?? 1

    anchors.fill: parent

    function saveConfig() {
        Config.appearance.anim.durations.scale = root.animDurationsScale;

        Config.appearance.font.family.material = root.fontFamilyMaterial;
        Config.appearance.font.family.mono = root.fontFamilyMono;
        Config.appearance.font.family.sans = root.fontFamilySans;
        Config.appearance.font.size.scale = root.fontSizeScale;

        Config.appearance.padding.scale = root.paddingScale;
        Config.appearance.rounding.scale = root.roundingScale;
        Config.appearance.spacing.scale = root.spacingScale;

        Config.appearance.transparency.enabled = root.transparencyEnabled;
        Config.appearance.transparency.base = root.transparencyBase;
        Config.appearance.transparency.layers = root.transparencyLayers;

        Config.background.desktopClock.enabled = root.desktopClockEnabled;
        Config.background.enabled = root.backgroundEnabled;

        Config.background.visualiser.enabled = root.visualiserEnabled;
        Config.background.visualiser.autoHide = root.visualiserAutoHide;
        Config.background.visualiser.rounding = root.visualiserRounding;
        Config.background.visualiser.spacing = root.visualiserSpacing;

        Config.border.rounding = root.borderRounding;
        Config.border.thickness = root.borderThickness;

        Config.save();
    }

    Component {
        id: appearanceRightContentComponent

        Item {
            id: rightAppearanceFlickable

            ColumnLayout {
                id: contentLayout

                anchors.fill: parent
                spacing: 0

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: Appearance.spacing.normal
                    text: qsTr("Wallpaper")
                    font.pointSize: Appearance.font.size.extraLarge
                    font.weight: 600
                }

                Loader {
                    id: wallpaperLoader
                    
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.bottomMargin: -Appearance.padding.large * 2
                    
                    asynchronous: true
                    active: {
                        const isActive = root.session.activeIndex === 3;
                        const isAdjacent = Math.abs(root.session.activeIndex - 3) === 1;
                        const splitLayout = root.children[0];
                        const loader = splitLayout && splitLayout.rightLoader ? splitLayout.rightLoader : null;
                        const shouldActivate = loader && loader.item !== null && (isActive || isAdjacent);
                        return shouldActivate;
                    }
                    
                    onStatusChanged: {
                        if (status === Loader.Error) {
                            console.error("[AppearancePane] Wallpaper loader error!");
                        }
                    }
                    
                    sourceComponent: WallpaperGrid {
                        session: root.session
                    }
                }
            }
        }
    }

    SplitPaneLayout {
        anchors.fill: parent

        leftContent: Component {

            StyledFlickable {
                id: sidebarFlickable
                readonly property var rootPane: root
                flickableDirection: Flickable.VerticalFlick
                contentHeight: sidebarLayout.height


                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: sidebarFlickable
                }

                ColumnLayout {
                    id: sidebarLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Appearance.spacing.small
                    
                    readonly property var rootPane: sidebarFlickable.rootPane

                    readonly property bool allSectionsExpanded: 
                        themeModeSection.expanded &&
                        colorVariantSection.expanded &&
                        colorSchemeSection.expanded &&
                        animationsSection.expanded &&
                        fontsSection.expanded &&
                        scalesSection.expanded &&
                        transparencySection.expanded &&
                        borderSection.expanded &&
                        backgroundSection.expanded

                RowLayout {
                    spacing: Appearance.spacing.smaller

                    StyledText {
                        text: qsTr("Appearance")
                        font.pointSize: Appearance.font.size.large
                        font.weight: 500
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    IconButton {
                        icon: sidebarLayout.allSectionsExpanded ? "unfold_less" : "unfold_more"
                        type: IconButton.Text
                        label.animate: true
                        onClicked: {
                            const shouldExpand = !sidebarLayout.allSectionsExpanded;
                            themeModeSection.expanded = shouldExpand;
                            colorVariantSection.expanded = shouldExpand;
                            colorSchemeSection.expanded = shouldExpand;
                            animationsSection.expanded = shouldExpand;
                            fontsSection.expanded = shouldExpand;
                            scalesSection.expanded = shouldExpand;
                            transparencySection.expanded = shouldExpand;
                            borderSection.expanded = shouldExpand;
                            backgroundSection.expanded = shouldExpand;
                        }
                    }
                }

                ThemeModeSection {
                    id: themeModeSection
                }

                ColorVariantSection {
                    id: colorVariantSection
                }

                ColorSchemeSection {
                    id: colorSchemeSection
                }

                AnimationsSection {
                    id: animationsSection
                    rootPane: sidebarFlickable.rootPane
                }

                FontsSection {
                    id: fontsSection
                    rootPane: sidebarFlickable.rootPane
                }

                ScalesSection {
                    id: scalesSection
                    rootPane: sidebarFlickable.rootPane
                }

                TransparencySection {
                    id: transparencySection
                    rootPane: sidebarFlickable.rootPane
                }

                BorderSection {
                    id: borderSection
                    rootPane: sidebarFlickable.rootPane
                }

                BackgroundSection {
                    id: backgroundSection
                    rootPane: sidebarFlickable.rootPane
                }
            }
        }
        }

        rightContent: appearanceRightContentComponent
    }
}
