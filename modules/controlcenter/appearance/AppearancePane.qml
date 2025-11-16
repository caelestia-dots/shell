pragma ComponentBehavior: Bound

import ".."
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

RowLayout {
    id: root

    required property Session session

    // Appearance settings
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

    // Background settings
    property bool desktopClockEnabled: Config.background.desktopClock.enabled ?? false
    property bool backgroundEnabled: Config.background.enabled ?? true
    property bool visualiserEnabled: Config.background.visualiser.enabled ?? false
    property bool visualiserAutoHide: Config.background.visualiser.autoHide ?? true
    property real visualiserRounding: Config.background.visualiser.rounding ?? 1
    property real visualiserSpacing: Config.background.visualiser.spacing ?? 1

    anchors.fill: parent

    spacing: 0


    function saveConfig() {
        // Update animations
        Config.appearance.anim.durations.scale = root.animDurationsScale;

        // Update fonts
        Config.appearance.font.family.material = root.fontFamilyMaterial;
        Config.appearance.font.family.mono = root.fontFamilyMono;
        Config.appearance.font.family.sans = root.fontFamilySans;
        Config.appearance.font.size.scale = root.fontSizeScale;

        // Update scales
        Config.appearance.padding.scale = root.paddingScale;
        Config.appearance.rounding.scale = root.roundingScale;
        Config.appearance.spacing.scale = root.spacingScale;

        // Update transparency
        Config.appearance.transparency.enabled = root.transparencyEnabled;
        Config.appearance.transparency.base = root.transparencyBase;
        Config.appearance.transparency.layers = root.transparencyLayers;

        // Update desktop clock
        Config.background.desktopClock.enabled = root.desktopClockEnabled;

        // Update background enabled
        Config.background.enabled = root.backgroundEnabled;

        // Update visualiser
        Config.background.visualiser.enabled = root.visualiserEnabled;
        Config.background.visualiser.autoHide = root.visualiserAutoHide;
        Config.background.visualiser.rounding = root.visualiserRounding;
        Config.background.visualiser.spacing = root.visualiserSpacing;

        // Update border
        Config.border.rounding = root.borderRounding;
        Config.border.thickness = root.borderThickness;

        // Persist changes to disk
        Config.save();
    }

    Item {
        Layout.preferredWidth: Math.floor(parent.width * 0.4)
        Layout.minimumWidth: 420
        Layout.fillHeight: true

        ClippingRectangle {
            id: leftAppearanceClippingRect
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            anchors.leftMargin: 0
            anchors.rightMargin: Appearance.padding.normal / 2
            radius: leftAppearanceBorder.innerRadius
            color: "transparent"

            Loader {
                id: leftAppearanceLoader
                anchors.fill: parent
                anchors.margins: Appearance.padding.large + Appearance.padding.normal
                anchors.leftMargin: Appearance.padding.large
                anchors.rightMargin: Appearance.padding.large + Appearance.padding.normal / 2
                asynchronous: true
                sourceComponent: appearanceLeftContentComponent
                property var rootPane: root
            }
        }

        InnerBorder {
            id: leftAppearanceBorder
            leftThickness: 0
            rightThickness: Appearance.padding.normal / 2
        }

        Component {
            id: appearanceLeftContentComponent

            StyledFlickable {
                id: sidebarFlickable
                readonly property var rootPane: leftAppearanceLoader.rootPane
                flickableDirection: Flickable.VerticalFlick
                contentHeight: sidebarLayout.height

                function collapseAllSections(exceptSection) {
                    if (exceptSection !== themeModeSection)
                        themeModeSection.expanded = false;
                    if (exceptSection !== colorVariantSection)
                        colorVariantSection.expanded = false;
                    if (exceptSection !== colorSchemeSection)
                        colorSchemeSection.expanded = false;
                    if (exceptSection !== animationsSection)
                        animationsSection.expanded = false;
                    if (exceptSection !== fontsSection)
                        fontsSection.expanded = false;
                    if (exceptSection !== scalesSection)
                        scalesSection.expanded = false;
                    if (exceptSection !== transparencySection)
                        transparencySection.expanded = false;
                    if (exceptSection !== borderSection)
                        borderSection.expanded = false;
                    if (exceptSection !== backgroundSection)
                        backgroundSection.expanded = false;
                }

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: sidebarFlickable
                }

                ColumnLayout {
                    id: sidebarLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Appearance.spacing.small

                RowLayout {
                    spacing: Appearance.spacing.smaller

                    StyledText {
                        text: qsTr("Settings")
                        font.pointSize: Appearance.font.size.large
                        font.weight: 500
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                CollapsibleSection {
                    id: themeModeSection
                    title: qsTr("Theme mode")
                    description: qsTr("Light or dark theme")
                    onToggleRequested: {
                        sidebarFlickable.collapseAllSections(themeModeSection);
                    }

                    SwitchRow {
                        label: qsTr("Dark mode")
                        checked: !Colours.currentLight
                        onToggled: checked => {
                            Colours.setMode(checked ? "dark" : "light");
                        }
                    }
                }

                CollapsibleSection {
                    id: colorVariantSection
                    title: qsTr("Color variant")
                    description: qsTr("Material theme variant")
                    onToggleRequested: {
                        sidebarFlickable.collapseAllSections(colorVariantSection);
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small / 2

                        Repeater {
                            model: M3Variants.list

                            delegate: StyledRect {
                                required property var modelData

                                Layout.fillWidth: true

                                color: Qt.alpha(Colours.tPalette.m3surfaceContainer, modelData.variant === Schemes.currentVariant ? Colours.tPalette.m3surfaceContainer.a : 0)
                                radius: Appearance.rounding.normal
                                border.width: modelData.variant === Schemes.currentVariant ? 1 : 0
                                border.color: Colours.palette.m3primary

                                StateLayer {
                                    function onClicked(): void {
                                        const variant = modelData.variant;

                                        // Optimistic update - set immediately
                                        Schemes.currentVariant = variant;

                                        // Execute the command
                                        Quickshell.execDetached(["caelestia", "scheme", "set", "-v", variant]);

                                        // Reload after a delay to confirm
                                        Qt.callLater(() => {
                                            reloadTimer.restart();
                                        });
                                    }
                                }

                                Timer {
                                    id: reloadTimer
                                    interval: 300
                                    onTriggered: {
                                        Schemes.reload();
                                    }
                                }

                                RowLayout {
                                    id: variantRow

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: Appearance.padding.normal

                                    spacing: Appearance.spacing.normal

                                    MaterialIcon {
                                        text: modelData.icon
                                        font.pointSize: Appearance.font.size.large
                                        fill: modelData.variant === Schemes.currentVariant ? 1 : 0
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        font.weight: modelData.variant === Schemes.currentVariant ? 500 : 400
                                    }

                                    MaterialIcon {
                                        visible: modelData.variant === Schemes.currentVariant
                                        text: "check"
                                        color: Colours.palette.m3primary
                                        font.pointSize: Appearance.font.size.large
                                    }
                                }

                                implicitHeight: variantRow.implicitHeight + Appearance.padding.normal * 2
                            }
                        }
                    }
                }

                CollapsibleSection {
                    id: colorSchemeSection
                    title: qsTr("Color scheme")
                    description: qsTr("Available color schemes")
                    onToggleRequested: {
                        sidebarFlickable.collapseAllSections(colorSchemeSection);
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small / 2

                        Repeater {
                            model: Schemes.list

                            delegate: StyledRect {
                                required property var modelData

                                Layout.fillWidth: true

                                readonly property string schemeKey: `${modelData.name} ${modelData.flavour}`
                                readonly property bool isCurrent: schemeKey === Schemes.currentScheme

                                color: Qt.alpha(Colours.tPalette.m3surfaceContainer, isCurrent ? Colours.tPalette.m3surfaceContainer.a : 0)
                                radius: Appearance.rounding.normal
                                border.width: isCurrent ? 1 : 0
                                border.color: Colours.palette.m3primary

                                StateLayer {
                                    function onClicked(): void {
                                        const name = modelData.name;
                                        const flavour = modelData.flavour;
                                        const schemeKey = `${name} ${flavour}`;

                                        // Optimistic update - set immediately
                                        Schemes.currentScheme = schemeKey;

                                        // Execute the command
                                        Quickshell.execDetached(["caelestia", "scheme", "set", "-n", name, "-f", flavour]);

                                        // Reload after a delay to confirm
                                        Qt.callLater(() => {
                                            reloadTimer.restart();
                                        });
                                    }
                                }

                                Timer {
                                    id: reloadTimer
                                    interval: 300
                                    onTriggered: {
                                        Schemes.reload();
                                    }
                                }

                                RowLayout {
                                    id: schemeRow

                                    anchors.fill: parent
                                    anchors.margins: Appearance.padding.normal

                                    spacing: Appearance.spacing.normal

                                    StyledRect {
                                        id: preview

                                        Layout.alignment: Qt.AlignVCenter

                                        border.width: 1
                                        border.color: Qt.alpha(`#${modelData.colours?.outline}`, 0.5)

                                        color: `#${modelData.colours?.surface}`
                                        radius: Appearance.rounding.full
                                        implicitWidth: iconPlaceholder.implicitWidth
                                        implicitHeight: iconPlaceholder.implicitWidth

                                        MaterialIcon {
                                            id: iconPlaceholder
                                            visible: false
                                            text: "circle"
                                            font.pointSize: Appearance.font.size.large
                                        }

                                        Item {
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            anchors.right: parent.right

                                            implicitWidth: parent.implicitWidth / 2
                                            clip: true

                                            StyledRect {
                                                anchors.top: parent.top
                                                anchors.bottom: parent.bottom
                                                anchors.right: parent.right

                                                implicitWidth: preview.implicitWidth
                                                color: `#${modelData.colours?.primary}`
                                                radius: Appearance.rounding.full
                                            }
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        StyledText {
                                            text: modelData.flavour ?? ""
                                            font.pointSize: Appearance.font.size.normal
                                        }

                                        StyledText {
                                            text: modelData.name ?? ""
                                            font.pointSize: Appearance.font.size.small
                                            color: Colours.palette.m3outline

                                            elide: Text.ElideRight
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                        }
                                    }

                                    Loader {
                                        active: isCurrent
                                        asynchronous: true

                                        sourceComponent: MaterialIcon {
                                            text: "check"
                                            color: Colours.palette.m3onSurfaceVariant
                                            font.pointSize: Appearance.font.size.large
                                        }
                                    }
                                }

                                implicitHeight: schemeRow.implicitHeight + Appearance.padding.normal * 2
                            }
                        }
                    }
                }

                CollapsibleSection {
                    id: animationsSection
                    title: qsTr("Animations")
                    onToggleRequested: {
                        sidebarFlickable.collapseAllSections(animationsSection);
                    }

                    SectionContainer {
                        contentSpacing: Appearance.spacing.normal

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.normal

                                StyledText {
                                    text: qsTr("Animation duration scale")
                                    font.pointSize: Appearance.font.size.normal
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                StyledRect {
                                    Layout.preferredWidth: 70
                                    implicitHeight: animDurationsInput.implicitHeight + Appearance.padding.small * 2
                                    color: animDurationsInputHover.containsMouse || animDurationsInput.activeFocus 
                                           ? Colours.layer(Colours.palette.m3surfaceContainer, 3)
                                           : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                    radius: Appearance.rounding.small
                                    border.width: 1
                                    border.color: animDurationsInput.activeFocus 
                                                  ? Colours.palette.m3primary
                                                  : Qt.alpha(Colours.palette.m3outline, 0.3)

                                    Behavior on color { CAnim {} }
                                    Behavior on border.color { CAnim {} }

                                    MouseArea {
                                        id: animDurationsInputHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.IBeamCursor
                                        acceptedButtons: Qt.NoButton
                                    }

                                    StyledTextField {
                                        id: animDurationsInput
                                        anchors.centerIn: parent
                                        width: parent.width - Appearance.padding.normal
                                        horizontalAlignment: TextInput.AlignHCenter
                                        validator: DoubleValidator { bottom: 0.1; top: 5.0 }
                                        
                                        Component.onCompleted: {
                                            text = (rootPane.animDurationsScale).toFixed(1);
                                        }
                                        
                                        onTextChanged: {
                                            if (activeFocus) {
                                                const val = parseFloat(text);
                                                if (!isNaN(val) && val >= 0.1 && val <= 5.0) {
                                                    rootPane.animDurationsScale = val;
                                                    rootPane.saveConfig();
                                                }
                                            }
                                        }
                                        onEditingFinished: {
                                            const val = parseFloat(text);
                                            if (isNaN(val) || val < 0.1 || val > 5.0) {
                                                text = (rootPane.animDurationsScale).toFixed(1);
                                            }
                                        }
                                    }
                                }

                                StyledText {
                                    text: "×"
                                    color: Colours.palette.m3outline
                                    font.pointSize: Appearance.font.size.normal
                                }
                            }

                            StyledSlider {
                                id: animDurationsSlider

                                Layout.fillWidth: true
                                implicitHeight: Appearance.padding.normal * 3

                                from: 0.1
                                to: 5.0
                        value: rootPane.animDurationsScale
                                onMoved: {
                                    rootPane.animDurationsScale = animDurationsSlider.value;
                                    if (!animDurationsInput.activeFocus) {
                                        animDurationsInput.text = (animDurationsSlider.value).toFixed(1);
                                    }
                            rootPane.saveConfig();
                                }
                            }
                        }
                    }
                }

                CollapsibleSection {
                    id: fontsSection
                    title: qsTr("Fonts")
                    onToggleRequested: {
                        sidebarFlickable.collapseAllSections(fontsSection);
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Material font family")
                        font.pointSize: Appearance.font.size.larger
                        font.weight: 500
                    }

                    StyledListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(contentHeight, 300)
                        
                        clip: true
                        spacing: Appearance.spacing.small / 2
                        model: Qt.fontFamilies()

                        delegate: StyledRect {
                            required property string modelData
                            required property int index

                            width: ListView.view.width

                            readonly property bool isCurrent: modelData === rootPane.fontFamilyMaterial
                            color: Qt.alpha(Colours.tPalette.m3surfaceContainer, isCurrent ? Colours.tPalette.m3surfaceContainer.a : 0)
                            radius: Appearance.rounding.normal
                            border.width: isCurrent ? 1 : 0
                            border.color: Colours.palette.m3primary

                            StateLayer {
                                function onClicked(): void {
                                    rootPane.fontFamilyMaterial = modelData;
                                    rootPane.saveConfig();
                                }
                            }

                            RowLayout {
                                id: fontFamilyMaterialRow

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Appearance.padding.normal

                                spacing: Appearance.spacing.normal

                                StyledText {
                                    text: modelData
                                    font.pointSize: Appearance.font.size.normal
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Loader {
                                    active: isCurrent
                                    asynchronous: true

                                    sourceComponent: MaterialIcon {
                                        text: "check"
                                        color: Colours.palette.m3onSurfaceVariant
                                        font.pointSize: Appearance.font.size.large
                                    }
                                }
                            }

                            implicitHeight: fontFamilyMaterialRow.implicitHeight + Appearance.padding.normal * 2
                        }
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Monospace font family")
                        font.pointSize: Appearance.font.size.larger
                        font.weight: 500
                    }

                    StyledListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(contentHeight, 300)
                        
                        clip: true
                        spacing: Appearance.spacing.small / 2
                        model: Qt.fontFamilies()

                        delegate: StyledRect {
                            required property string modelData
                            required property int index

                            width: ListView.view.width

                            readonly property bool isCurrent: modelData === rootPane.fontFamilyMono
                            color: Qt.alpha(Colours.tPalette.m3surfaceContainer, isCurrent ? Colours.tPalette.m3surfaceContainer.a : 0)
                            radius: Appearance.rounding.normal
                            border.width: isCurrent ? 1 : 0
                            border.color: Colours.palette.m3primary

                            StateLayer {
                                function onClicked(): void {
                                    rootPane.fontFamilyMono = modelData;
                                    rootPane.saveConfig();
                                }
                            }

                            RowLayout {
                                id: fontFamilyMonoRow

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Appearance.padding.normal

                                spacing: Appearance.spacing.normal

                                StyledText {
                                    text: modelData
                                    font.pointSize: Appearance.font.size.normal
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Loader {
                                    active: isCurrent
                                    asynchronous: true

                                    sourceComponent: MaterialIcon {
                                        text: "check"
                                        color: Colours.palette.m3onSurfaceVariant
                                        font.pointSize: Appearance.font.size.large
                                    }
                                }
                            }

                            implicitHeight: fontFamilyMonoRow.implicitHeight + Appearance.padding.normal * 2
                        }
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Sans-serif font family")
                        font.pointSize: Appearance.font.size.larger
                        font.weight: 500
                    }

                    StyledListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(contentHeight, 300)
                        
                        clip: true
                        spacing: Appearance.spacing.small / 2
                        model: Qt.fontFamilies()

                        delegate: StyledRect {
                            required property string modelData
                            required property int index

                            width: ListView.view.width

                            readonly property bool isCurrent: modelData === rootPane.fontFamilySans
                            color: Qt.alpha(Colours.tPalette.m3surfaceContainer, isCurrent ? Colours.tPalette.m3surfaceContainer.a : 0)
                            radius: Appearance.rounding.normal
                            border.width: isCurrent ? 1 : 0
                            border.color: Colours.palette.m3primary

                            StateLayer {
                                function onClicked(): void {
                                    rootPane.fontFamilySans = modelData;
                                    rootPane.saveConfig();
                                }
                            }

                            RowLayout {
                                id: fontFamilySansRow

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Appearance.padding.normal

                                spacing: Appearance.spacing.normal

                                StyledText {
                                    text: modelData
                                    font.pointSize: Appearance.font.size.normal
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Loader {
                                    active: isCurrent
                                    asynchronous: true

                                    sourceComponent: MaterialIcon {
                                        text: "check"
                                        color: Colours.palette.m3onSurfaceVariant
                                        font.pointSize: Appearance.font.size.large
                                    }
                                }
                            }

                            implicitHeight: fontFamilySansRow.implicitHeight + Appearance.padding.normal * 2
                        }
                    }

                    SectionContainer {
                        contentSpacing: Appearance.spacing.normal

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.normal

                                StyledText {
                                    text: qsTr("Font size scale")
                                    font.pointSize: Appearance.font.size.normal
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                StyledRect {
                                    Layout.preferredWidth: 70
                                    implicitHeight: fontSizeInput.implicitHeight + Appearance.padding.small * 2
                                    color: fontSizeInputHover.containsMouse || fontSizeInput.activeFocus 
                                           ? Colours.layer(Colours.palette.m3surfaceContainer, 3)
                                           : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                    radius: Appearance.rounding.small
                                    border.width: 1
                                    border.color: fontSizeInput.activeFocus 
                                                  ? Colours.palette.m3primary
                                                  : Qt.alpha(Colours.palette.m3outline, 0.3)

                                    Behavior on color { CAnim {} }
                                    Behavior on border.color { CAnim {} }

                                    MouseArea {
                                        id: fontSizeInputHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.IBeamCursor
                                        acceptedButtons: Qt.NoButton
                                    }

                                    StyledTextField {
                                        id: fontSizeInput
                                        anchors.centerIn: parent
                                        width: parent.width - Appearance.padding.normal
                                        horizontalAlignment: TextInput.AlignHCenter
                                        validator: DoubleValidator { bottom: 0.1; top: 5.0 }
                                        
                                        Component.onCompleted: {
                                            text = (rootPane.fontSizeScale).toFixed(1);
                                        }
                                        
                                        onTextChanged: {
                                            if (activeFocus) {
                                                const val = parseFloat(text);
                                                if (!isNaN(val) && val >= 0.1 && val <= 5.0) {
                                                    rootPane.fontSizeScale = val;
                                                    rootPane.saveConfig();
                                                }
                                            }
                                        }
                                        onEditingFinished: {
                                            const val = parseFloat(text);
                                            if (isNaN(val) || val < 0.1 || val > 5.0) {
                                                text = (rootPane.fontSizeScale).toFixed(1);
                                            }
                                        }
                                    }
                                }

                                StyledText {
                                    text: "×"
                                    color: Colours.palette.m3outline
                                    font.pointSize: Appearance.font.size.normal
                                }
                            }

                            StyledSlider {
                                id: fontSizeSlider

                                Layout.fillWidth: true
                                implicitHeight: Appearance.padding.normal * 3

                                from: 0.1
                                to: 5.0
                        value: rootPane.fontSizeScale
                                onMoved: {
                                    rootPane.fontSizeScale = fontSizeSlider.value;
                                    if (!fontSizeInput.activeFocus) {
                                        fontSizeInput.text = (fontSizeSlider.value).toFixed(1);
                                    }
                            rootPane.saveConfig();
                                }
                            }
                        }
                    }
                }

                CollapsibleSection {
                    id: scalesSection
                    title: qsTr("Scales")
                    onToggleRequested: {
                        sidebarFlickable.collapseAllSections(scalesSection);
                    }

                    SectionContainer {
                        contentSpacing: Appearance.spacing.normal

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.normal

                                StyledText {
                                    text: qsTr("Padding scale")
                                    font.pointSize: Appearance.font.size.normal
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                StyledRect {
                                    Layout.preferredWidth: 70
                                    implicitHeight: paddingInput.implicitHeight + Appearance.padding.small * 2
                                    color: paddingInputHover.containsMouse || paddingInput.activeFocus 
                                           ? Colours.layer(Colours.palette.m3surfaceContainer, 3)
                                           : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                    radius: Appearance.rounding.small
                                    border.width: 1
                                    border.color: paddingInput.activeFocus 
                                                  ? Colours.palette.m3primary
                                                  : Qt.alpha(Colours.palette.m3outline, 0.3)

                                    Behavior on color { CAnim {} }
                                    Behavior on border.color { CAnim {} }

                                    MouseArea {
                                        id: paddingInputHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.IBeamCursor
                                        acceptedButtons: Qt.NoButton
                                    }

                                    StyledTextField {
                                        id: paddingInput
                                        anchors.centerIn: parent
                                        width: parent.width - Appearance.padding.normal
                                        horizontalAlignment: TextInput.AlignHCenter
                                        validator: DoubleValidator { bottom: 0.5; top: 2.0 }
                                        
                                        Component.onCompleted: {
                                            text = (rootPane.paddingScale).toFixed(1);
                                        }
                                        
                                        onTextChanged: {
                                            if (activeFocus) {
                                                const val = parseFloat(text);
                                                if (!isNaN(val) && val >= 0.5 && val <= 2.0) {
                                                    rootPane.paddingScale = val;
                                                    rootPane.saveConfig();
                                                }
                                            }
                                        }
                                        onEditingFinished: {
                                            const val = parseFloat(text);
                                            if (isNaN(val) || val < 0.5 || val > 2.0) {
                                                text = (rootPane.paddingScale).toFixed(1);
                                            }
                                        }
                                    }
                                }

                                StyledText {
                                    text: "×"
                                    color: Colours.palette.m3outline
                                    font.pointSize: Appearance.font.size.normal
                                }
                            }

                            StyledSlider {
                                id: paddingSlider

                                Layout.fillWidth: true
                                implicitHeight: Appearance.padding.normal * 3

                                from: 0.5
                                to: 2.0
                        value: rootPane.paddingScale
                                onMoved: {
                                    rootPane.paddingScale = paddingSlider.value;
                                    if (!paddingInput.activeFocus) {
                                        paddingInput.text = (paddingSlider.value).toFixed(1);
                                    }
                            rootPane.saveConfig();
                                }
                            }
                        }
                    }

                    SectionContainer {
                        contentSpacing: Appearance.spacing.normal

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.normal

                                StyledText {
                                    text: qsTr("Rounding scale")
                                    font.pointSize: Appearance.font.size.normal
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                StyledRect {
                                    Layout.preferredWidth: 70
                                    implicitHeight: roundingInput.implicitHeight + Appearance.padding.small * 2
                                    color: roundingInputHover.containsMouse || roundingInput.activeFocus 
                                           ? Colours.layer(Colours.palette.m3surfaceContainer, 3)
                                           : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                    radius: Appearance.rounding.small
                                    border.width: 1
                                    border.color: roundingInput.activeFocus 
                                                  ? Colours.palette.m3primary
                                                  : Qt.alpha(Colours.palette.m3outline, 0.3)

                                    Behavior on color { CAnim {} }
                                    Behavior on border.color { CAnim {} }

                                    MouseArea {
                                        id: roundingInputHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.IBeamCursor
                                        acceptedButtons: Qt.NoButton
                                    }

                                    StyledTextField {
                                        id: roundingInput
                                        anchors.centerIn: parent
                                        width: parent.width - Appearance.padding.normal
                                        horizontalAlignment: TextInput.AlignHCenter
                                        validator: DoubleValidator { bottom: 0.1; top: 5.0 }
                                        
                                        Component.onCompleted: {
                                            text = (rootPane.roundingScale).toFixed(1);
                                        }
                                        
                                        onTextChanged: {
                                            if (activeFocus) {
                                                const val = parseFloat(text);
                                                if (!isNaN(val) && val >= 0.1 && val <= 5.0) {
                                                    rootPane.roundingScale = val;
                                                    rootPane.saveConfig();
                                                }
                                            }
                                        }
                                        onEditingFinished: {
                                            const val = parseFloat(text);
                                            if (isNaN(val) || val < 0.1 || val > 5.0) {
                                                text = (rootPane.roundingScale).toFixed(1);
                                            }
                                        }
                                    }
                                }

                                StyledText {
                                    text: "×"
                                    color: Colours.palette.m3outline
                                    font.pointSize: Appearance.font.size.normal
                                }
                            }

                            StyledSlider {
                                id: roundingSlider

                                Layout.fillWidth: true
                                implicitHeight: Appearance.padding.normal * 3

                                from: 0.1
                                to: 5.0
                        value: rootPane.roundingScale
                                onMoved: {
                                    rootPane.roundingScale = roundingSlider.value;
                                    if (!roundingInput.activeFocus) {
                                        roundingInput.text = (roundingSlider.value).toFixed(1);
                                    }
                            rootPane.saveConfig();
                                }
                            }
                        }
                    }

                    SectionContainer {
                        contentSpacing: Appearance.spacing.normal

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.normal

                                StyledText {
                                    text: qsTr("Spacing scale")
                                    font.pointSize: Appearance.font.size.normal
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                StyledRect {
                                    Layout.preferredWidth: 70
                                    implicitHeight: spacingInput.implicitHeight + Appearance.padding.small * 2
                                    color: spacingInputHover.containsMouse || spacingInput.activeFocus 
                                           ? Colours.layer(Colours.palette.m3surfaceContainer, 3)
                                           : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                    radius: Appearance.rounding.small
                                    border.width: 1
                                    border.color: spacingInput.activeFocus 
                                                  ? Colours.palette.m3primary
                                                  : Qt.alpha(Colours.palette.m3outline, 0.3)

                                    Behavior on color { CAnim {} }
                                    Behavior on border.color { CAnim {} }

                                    MouseArea {
                                        id: spacingInputHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.IBeamCursor
                                        acceptedButtons: Qt.NoButton
                                    }

                                    StyledTextField {
                                        id: spacingInput
                                        anchors.centerIn: parent
                                        width: parent.width - Appearance.padding.normal
                                        horizontalAlignment: TextInput.AlignHCenter
                                        validator: DoubleValidator { bottom: 0.1; top: 2.0 }
                                        
                                        Component.onCompleted: {
                                            text = (rootPane.spacingScale).toFixed(1);
                                        }
                                        
                                        onTextChanged: {
                                            if (activeFocus) {
                                                const val = parseFloat(text);
                                                if (!isNaN(val) && val >= 0.1 && val <= 2.0) {
                                                    rootPane.spacingScale = val;
                                                    rootPane.saveConfig();
                                                }
                                            }
                                        }
                                        onEditingFinished: {
                                            const val = parseFloat(text);
                                            if (isNaN(val) || val < 0.1 || val > 2.0) {
                                                text = (rootPane.spacingScale).toFixed(1);
                                            }
                                        }
                                    }
                                }

                                StyledText {
                                    text: "×"
                                    color: Colours.palette.m3outline
                                    font.pointSize: Appearance.font.size.normal
                                }
                            }

                            StyledSlider {
                                id: spacingSlider

                                Layout.fillWidth: true
                                implicitHeight: Appearance.padding.normal * 3

                                from: 0.1
                                to: 2.0
                        value: rootPane.spacingScale
                                onMoved: {
                                    rootPane.spacingScale = spacingSlider.value;
                                    if (!spacingInput.activeFocus) {
                                        spacingInput.text = (spacingSlider.value).toFixed(1);
                                    }
                            rootPane.saveConfig();
                                }
                            }
                        }
                    }
                }

                CollapsibleSection {
                    id: transparencySection
                    title: qsTr("Transparency")
                    onToggleRequested: {
                        sidebarFlickable.collapseAllSections(transparencySection);
                    }

                    SwitchRow {
                        label: qsTr("Transparency enabled")
                        checked: rootPane.transparencyEnabled
                        onToggled: checked => {
                            rootPane.transparencyEnabled = checked;
                            rootPane.saveConfig();
                        }
                    }

                    SectionContainer {
                        contentSpacing: Appearance.spacing.normal

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.normal

                                StyledText {
                                    text: qsTr("Transparency base")
                                    font.pointSize: Appearance.font.size.normal
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                StyledRect {
                                    Layout.preferredWidth: 70
                                    implicitHeight: transparencyBaseInput.implicitHeight + Appearance.padding.small * 2
                                    color: transparencyBaseInputHover.containsMouse || transparencyBaseInput.activeFocus 
                                           ? Colours.layer(Colours.palette.m3surfaceContainer, 3)
                                           : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                    radius: Appearance.rounding.small
                                    border.width: 1
                                    border.color: transparencyBaseInput.activeFocus 
                                                  ? Colours.palette.m3primary
                                                  : Qt.alpha(Colours.palette.m3outline, 0.3)

                                    Behavior on color { CAnim {} }
                                    Behavior on border.color { CAnim {} }

                                    MouseArea {
                                        id: transparencyBaseInputHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.IBeamCursor
                                        acceptedButtons: Qt.NoButton
                                    }

                                    StyledTextField {
                                        id: transparencyBaseInput
                                        anchors.centerIn: parent
                                        width: parent.width - Appearance.padding.normal
                                        horizontalAlignment: TextInput.AlignHCenter
                                        validator: IntValidator { bottom: 0; top: 100 }
                                        
                                        Component.onCompleted: {
                                            text = Math.round(rootPane.transparencyBase * 100).toString();
                                        }
                                        
                                        onTextChanged: {
                                            if (activeFocus) {
                                                const val = parseInt(text);
                                                if (!isNaN(val) && val >= 0 && val <= 100) {
                                                    rootPane.transparencyBase = val / 100;
                                                    rootPane.saveConfig();
                                                }
                                            }
                                        }
                                        onEditingFinished: {
                                            const val = parseInt(text);
                                            if (isNaN(val) || val < 0 || val > 100) {
                                                text = Math.round(rootPane.transparencyBase * 100).toString();
                                            }
                                        }
                                    }
                                }

                                StyledText {
                                    text: "%"
                                    color: Colours.palette.m3outline
                                    font.pointSize: Appearance.font.size.normal
                                }
                            }

                            StyledSlider {
                                id: baseSlider

                                Layout.fillWidth: true
                                implicitHeight: Appearance.padding.normal * 3

                                from: 0
                                to: 100
                                value: rootPane.transparencyBase * 100
                                onMoved: {
                                    rootPane.transparencyBase = baseSlider.value / 100;
                                    if (!transparencyBaseInput.activeFocus) {
                                        transparencyBaseInput.text = Math.round(baseSlider.value).toString();
                                    }
                                    rootPane.saveConfig();
                                }
                            }
                        }
                    }

                    SectionContainer {
                        contentSpacing: Appearance.spacing.normal

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.normal

                                StyledText {
                                    text: qsTr("Transparency layers")
                                    font.pointSize: Appearance.font.size.normal
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                StyledRect {
                                    Layout.preferredWidth: 70
                                    implicitHeight: transparencyLayersInput.implicitHeight + Appearance.padding.small * 2
                                    color: transparencyLayersInputHover.containsMouse || transparencyLayersInput.activeFocus 
                                           ? Colours.layer(Colours.palette.m3surfaceContainer, 3)
                                           : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                    radius: Appearance.rounding.small
                                    border.width: 1
                                    border.color: transparencyLayersInput.activeFocus 
                                                  ? Colours.palette.m3primary
                                                  : Qt.alpha(Colours.palette.m3outline, 0.3)

                                    Behavior on color { CAnim {} }
                                    Behavior on border.color { CAnim {} }

                                    MouseArea {
                                        id: transparencyLayersInputHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.IBeamCursor
                                        acceptedButtons: Qt.NoButton
                                    }

                                    StyledTextField {
                                        id: transparencyLayersInput
                                        anchors.centerIn: parent
                                        width: parent.width - Appearance.padding.normal
                                        horizontalAlignment: TextInput.AlignHCenter
                                        validator: IntValidator { bottom: 0; top: 100 }
                                        
                                        Component.onCompleted: {
                                            text = Math.round(rootPane.transparencyLayers * 100).toString();
                                        }
                                        
                                        onTextChanged: {
                                            if (activeFocus) {
                                                const val = parseInt(text);
                                                if (!isNaN(val) && val >= 0 && val <= 100) {
                                                    rootPane.transparencyLayers = val / 100;
                                                    rootPane.saveConfig();
                                                }
                                            }
                                        }
                                        onEditingFinished: {
                                            const val = parseInt(text);
                                            if (isNaN(val) || val < 0 || val > 100) {
                                                text = Math.round(rootPane.transparencyLayers * 100).toString();
                                            }
                                        }
                                    }
                                }

                                StyledText {
                                    text: "%"
                                    color: Colours.palette.m3outline
                                    font.pointSize: Appearance.font.size.normal
                                }
                            }

                            StyledSlider {
                                id: layersSlider

                                Layout.fillWidth: true
                                implicitHeight: Appearance.padding.normal * 3

                                from: 0
                                to: 100
                                value: rootPane.transparencyLayers * 100
                                onMoved: {
                                    rootPane.transparencyLayers = layersSlider.value / 100;
                                    if (!transparencyLayersInput.activeFocus) {
                                        transparencyLayersInput.text = Math.round(layersSlider.value).toString();
                                    }
                                    rootPane.saveConfig();
                                }
                            }
                        }
                    }
                }

                CollapsibleSection {
                    id: borderSection
                    title: qsTr("Border")
                    onToggleRequested: {
                        sidebarFlickable.collapseAllSections(borderSection);
                    }

                    SectionContainer {
                        contentSpacing: Appearance.spacing.normal

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.normal

                                StyledText {
                                    text: qsTr("Border rounding")
                                    font.pointSize: Appearance.font.size.normal
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                StyledRect {
                                    Layout.preferredWidth: 70
                                    implicitHeight: borderRoundingInput.implicitHeight + Appearance.padding.small * 2
                                    color: borderRoundingInputHover.containsMouse || borderRoundingInput.activeFocus 
                                           ? Colours.layer(Colours.palette.m3surfaceContainer, 3)
                                           : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                    radius: Appearance.rounding.small
                                    border.width: 1
                                    border.color: borderRoundingInput.activeFocus 
                                                  ? Colours.palette.m3primary
                                                  : Qt.alpha(Colours.palette.m3outline, 0.3)

                                    Behavior on color { CAnim {} }
                                    Behavior on border.color { CAnim {} }

                                    MouseArea {
                                        id: borderRoundingInputHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.IBeamCursor
                                        acceptedButtons: Qt.NoButton
                                    }

                                    StyledTextField {
                                        id: borderRoundingInput
                                        anchors.centerIn: parent
                                        width: parent.width - Appearance.padding.normal
                                        horizontalAlignment: TextInput.AlignHCenter
                                        validator: DoubleValidator { bottom: 0.1; top: 100 }
                                        
                                        Component.onCompleted: {
                                            text = (rootPane.borderRounding).toFixed(1);
                                        }
                                        
                                        onTextChanged: {
                                            if (activeFocus) {
                                                const val = parseFloat(text);
                                                if (!isNaN(val) && val >= 0.1 && val <= 100) {
                                                    rootPane.borderRounding = val;
                                                    rootPane.saveConfig();
                                                }
                                            }
                                        }
                                        onEditingFinished: {
                                            const val = parseFloat(text);
                                            if (isNaN(val) || val < 0.1 || val > 100) {
                                                text = (rootPane.borderRounding).toFixed(1);
                                            }
                                        }
                                    }
                                }
                            }

                            StyledSlider {
                                id: borderRoundingSlider

                                Layout.fillWidth: true
                                implicitHeight: Appearance.padding.normal * 3

                                from: 0.1
                                to: 100
                        value: rootPane.borderRounding
                                onMoved: {
                                    rootPane.borderRounding = borderRoundingSlider.value;
                                    if (!borderRoundingInput.activeFocus) {
                                        borderRoundingInput.text = (borderRoundingSlider.value).toFixed(1);
                                    }
                            rootPane.saveConfig();
                                }
                            }
                        }
                    }

                    SectionContainer {
                        contentSpacing: Appearance.spacing.normal

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.normal

                                StyledText {
                                    text: qsTr("Border thickness")
                                    font.pointSize: Appearance.font.size.normal
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                StyledRect {
                                    Layout.preferredWidth: 70
                                    implicitHeight: borderThicknessInput.implicitHeight + Appearance.padding.small * 2
                                    color: borderThicknessInputHover.containsMouse || borderThicknessInput.activeFocus 
                                           ? Colours.layer(Colours.palette.m3surfaceContainer, 3)
                                           : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                    radius: Appearance.rounding.small
                                    border.width: 1
                                    border.color: borderThicknessInput.activeFocus 
                                                  ? Colours.palette.m3primary
                                                  : Qt.alpha(Colours.palette.m3outline, 0.3)

                                    Behavior on color { CAnim {} }
                                    Behavior on border.color { CAnim {} }

                                    MouseArea {
                                        id: borderThicknessInputHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.IBeamCursor
                                        acceptedButtons: Qt.NoButton
                                    }

                                    StyledTextField {
                                        id: borderThicknessInput
                                        anchors.centerIn: parent
                                        width: parent.width - Appearance.padding.normal
                                        horizontalAlignment: TextInput.AlignHCenter
                                        validator: DoubleValidator { bottom: 0.1; top: 100 }
                                        
                                        Component.onCompleted: {
                                            text = (rootPane.borderThickness).toFixed(1);
                                        }
                                        
                                        onTextChanged: {
                                            if (activeFocus) {
                                                const val = parseFloat(text);
                                                if (!isNaN(val) && val >= 0.1 && val <= 100) {
                                                    rootPane.borderThickness = val;
                                                    rootPane.saveConfig();
                                                }
                                            }
                                        }
                                        onEditingFinished: {
                                            const val = parseFloat(text);
                                            if (isNaN(val) || val < 0.1 || val > 100) {
                                                text = (rootPane.borderThickness).toFixed(1);
                                            }
                                        }
                                    }
                                }
                            }

                            StyledSlider {
                                id: borderThicknessSlider

                                Layout.fillWidth: true
                                implicitHeight: Appearance.padding.normal * 3

                                from: 0.1
                                to: 100
                        value: rootPane.borderThickness
                                onMoved: {
                                    rootPane.borderThickness = borderThicknessSlider.value;
                                    if (!borderThicknessInput.activeFocus) {
                                        borderThicknessInput.text = (borderThicknessSlider.value).toFixed(1);
                                    }
                            rootPane.saveConfig();
                                }
                            }
                        }
                    }
                }

                CollapsibleSection {
                    id: backgroundSection
                    title: qsTr("Background")
                    onToggleRequested: {
                        sidebarFlickable.collapseAllSections(backgroundSection);
                    }

                    SwitchRow {
                        label: qsTr("Desktop clock")
                        checked: rootPane.desktopClockEnabled
                        onToggled: checked => {
                            rootPane.desktopClockEnabled = checked;
                            rootPane.saveConfig();
                        }
                    }

                    SwitchRow {
                        label: qsTr("Background enabled")
                        checked: rootPane.backgroundEnabled
                        onToggled: checked => {
                            rootPane.backgroundEnabled = checked;
                            rootPane.saveConfig();
                        }
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Visualiser")
                        font.pointSize: Appearance.font.size.larger
                        font.weight: 500
                    }

                    SwitchRow {
                        label: qsTr("Visualiser enabled")
                        checked: rootPane.visualiserEnabled
                        onToggled: checked => {
                            rootPane.visualiserEnabled = checked;
                            rootPane.saveConfig();
                        }
                    }

                    SwitchRow {
                        label: qsTr("Visualiser auto hide")
                        checked: rootPane.visualiserAutoHide
                        onToggled: checked => {
                            rootPane.visualiserAutoHide = checked;
                            rootPane.saveConfig();
                        }
                    }

                    SectionContainer {
                        contentSpacing: Appearance.spacing.normal

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.normal

                                StyledText {
                                    text: qsTr("Visualiser rounding")
                                    font.pointSize: Appearance.font.size.normal
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                StyledRect {
                                    Layout.preferredWidth: 70
                                    implicitHeight: visualiserRoundingInput.implicitHeight + Appearance.padding.small * 2
                                    color: visualiserRoundingInputHover.containsMouse || visualiserRoundingInput.activeFocus 
                                           ? Colours.layer(Colours.palette.m3surfaceContainer, 3)
                                           : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                    radius: Appearance.rounding.small
                                    border.width: 1
                                    border.color: visualiserRoundingInput.activeFocus 
                                                  ? Colours.palette.m3primary
                                                  : Qt.alpha(Colours.palette.m3outline, 0.3)

                                    Behavior on color { CAnim {} }
                                    Behavior on border.color { CAnim {} }

                                    MouseArea {
                                        id: visualiserRoundingInputHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.IBeamCursor
                                        acceptedButtons: Qt.NoButton
                                    }

                                    StyledTextField {
                                        id: visualiserRoundingInput
                                        anchors.centerIn: parent
                                        width: parent.width - Appearance.padding.normal
                                        horizontalAlignment: TextInput.AlignHCenter
                                        validator: IntValidator { bottom: 0; top: 10 }
                                        
                                        Component.onCompleted: {
                                            text = Math.round(rootPane.visualiserRounding).toString();
                                        }
                                        
                                        onTextChanged: {
                                            if (activeFocus) {
                                                const val = parseInt(text);
                                                if (!isNaN(val) && val >= 0 && val <= 10) {
                                                    rootPane.visualiserRounding = val;
                            rootPane.saveConfig();
                                                }
                                            }
                                        }
                                        onEditingFinished: {
                                            const val = parseInt(text);
                                            if (isNaN(val) || val < 0 || val > 10) {
                                                text = Math.round(rootPane.visualiserRounding).toString();
                                            }
                                        }
                                    }
                                }
                            }

                            StyledSlider {
                                id: visualiserRoundingSlider

                                Layout.fillWidth: true
                                implicitHeight: Appearance.padding.normal * 3

                                from: 0
                                to: 10
                                stepSize: 1
                                value: rootPane.visualiserRounding
                                onMoved: {
                                    rootPane.visualiserRounding = Math.round(visualiserRoundingSlider.value);
                                    if (!visualiserRoundingInput.activeFocus) {
                                        visualiserRoundingInput.text = Math.round(visualiserRoundingSlider.value).toString();
                                    }
                            rootPane.saveConfig();
                        }
                    }
                }
            }

                    SectionContainer {
                        contentSpacing: Appearance.spacing.normal

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.normal

                                StyledText {
                                    text: qsTr("Visualiser spacing")
                                    font.pointSize: Appearance.font.size.normal
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                StyledRect {
                                    Layout.preferredWidth: 70
                                    implicitHeight: visualiserSpacingInput.implicitHeight + Appearance.padding.small * 2
                                    color: visualiserSpacingInputHover.containsMouse || visualiserSpacingInput.activeFocus 
                                           ? Colours.layer(Colours.palette.m3surfaceContainer, 3)
                                           : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                    radius: Appearance.rounding.small
                                    border.width: 1
                                    border.color: visualiserSpacingInput.activeFocus 
                                                  ? Colours.palette.m3primary
                                                  : Qt.alpha(Colours.palette.m3outline, 0.3)

                                    Behavior on color { CAnim {} }
                                    Behavior on border.color { CAnim {} }

                                    MouseArea {
                                        id: visualiserSpacingInputHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.IBeamCursor
                                        acceptedButtons: Qt.NoButton
                                    }

                                    StyledTextField {
                                        id: visualiserSpacingInput
                                        anchors.centerIn: parent
                                        width: parent.width - Appearance.padding.normal
                                        horizontalAlignment: TextInput.AlignHCenter
                                        validator: DoubleValidator { bottom: 0; top: 2 }
                                        
                                        Component.onCompleted: {
                                            text = (rootPane.visualiserSpacing).toFixed(1);
                                        }
                                        
                                        onTextChanged: {
                                            if (activeFocus) {
                                                const val = parseFloat(text);
                                                if (!isNaN(val) && val >= 0 && val <= 2) {
                                                    rootPane.visualiserSpacing = val;
                                                    rootPane.saveConfig();
                                                }
                                            }
                                        }
                                        onEditingFinished: {
                                            const val = parseFloat(text);
                                            if (isNaN(val) || val < 0 || val > 2) {
                                                text = (rootPane.visualiserSpacing).toFixed(1);
                                            }
                                        }
                                    }
                                }
                            }

                            StyledSlider {
                                id: visualiserSpacingSlider

                                Layout.fillWidth: true
                                implicitHeight: Appearance.padding.normal * 3

                                from: 0
                                to: 2
                                value: rootPane.visualiserSpacing
                                onMoved: {
                                    rootPane.visualiserSpacing = visualiserSpacingSlider.value;
                                    if (!visualiserSpacingInput.activeFocus) {
                                        visualiserSpacingInput.text = (visualiserSpacingSlider.value).toFixed(1);
                                    }
                                    rootPane.saveConfig();
                                }
                            }
                        }
                    }
                }
            }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ClippingRectangle {
            id: rightAppearanceClippingRect
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            anchors.leftMargin: 0
            anchors.rightMargin: Appearance.padding.normal / 2
            radius: rightAppearanceBorder.innerRadius
            color: "transparent"

            Loader {
                id: rightAppearanceLoader
                anchors.fill: parent
                anchors.margins: Appearance.padding.large * 2
                asynchronous: true
                sourceComponent: appearanceRightContentComponent
                property var rootPane: root
            }
        }

        InnerBorder {
            id: rightAppearanceBorder
            leftThickness: Appearance.padding.normal / 2
        }

        Component {
            id: appearanceRightContentComponent

            StyledFlickable {
                id: rightAppearanceFlickable
                flickableDirection: Flickable.VerticalFlick
                contentHeight: contentLayout.height

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: rightAppearanceFlickable
                }

                ColumnLayout {
                    id: contentLayout

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: Appearance.spacing.normal

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                    Layout.topMargin: 0
                    text: "palette"
                    font.pointSize: Appearance.font.size.extraLarge * 3
                    font.bold: true
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Appearance Settings")
                    font.pointSize: Appearance.font.size.large
                    font.bold: true
                }

                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Wallpaper")
                    font.pointSize: Appearance.font.size.extraLarge
                    font.weight: 600
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Select a wallpaper")
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurfaceVariant
                }

                Item {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.large
                    Layout.preferredHeight: wallpaperGrid.Layout.preferredHeight
                    
                    GridView {
                        id: wallpaperGrid
                        anchors.fill: parent
                        
                        readonly property int minCellWidth: 200 + Appearance.spacing.normal
                        readonly property int columnsCount: Math.max(1, Math.floor(parent.width / minCellWidth))
                        
                        Layout.preferredHeight: Math.ceil(count / columnsCount) * cellHeight
                        height: Layout.preferredHeight
                        
                        // Distribute width evenly across columns
                        cellWidth: width / columnsCount
                        cellHeight: 140 + Appearance.spacing.normal
                        
                        leftMargin: 0
                        rightMargin: 0
                        topMargin: 0
                        bottomMargin: 0

                        model: Wallpapers.list
                        clip: true
                        
                        // Disable GridView's own scrolling - let parent handle it
                        interactive: false

                    // Enable caching for better performance
                    cacheBuffer: cellHeight * 2

                    delegate: Item {
                        required property var modelData

                        width: wallpaperGrid.cellWidth
                        height: wallpaperGrid.cellHeight

                        readonly property bool isCurrent: modelData.path === Wallpapers.actualCurrent

                        StateLayer {
                            anchors.fill: parent
                            anchors.leftMargin: Appearance.spacing.normal / 2
                            anchors.rightMargin: Appearance.spacing.normal / 2
                            anchors.topMargin: Appearance.spacing.normal / 2
                            anchors.bottomMargin: Appearance.spacing.normal / 2
                            radius: Appearance.rounding.normal

                            function onClicked(): void {
                                Wallpapers.setWallpaper(modelData.path);
                            }
                        }

                        StyledClippingRect {
                            id: image

                            anchors.fill: parent
                            anchors.leftMargin: Appearance.spacing.normal / 2
                            anchors.rightMargin: Appearance.spacing.normal / 2
                            anchors.topMargin: Appearance.spacing.normal / 2
                            anchors.bottomMargin: Appearance.spacing.normal / 2
                            color: Colours.tPalette.m3surfaceContainer
                            radius: Appearance.rounding.normal
                            antialiasing: true

                            CachingImage {
                                id: cachingImage

                                path: modelData.path
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                cache: true
                                visible: opacity > 0
                                antialiasing: true

                                // Show when ready
                                opacity: status === Image.Ready ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 1000
                                        easing.type: Easing.OutQuad
                                    }
                                }
                            }

                            // Fallback image for when caching fails
                            Image {
                                id: fallbackImage

                                anchors.fill: parent
                                source: fallbackTimer.triggered && cachingImage.status !== Image.Ready ? modelData.path : ""
                                asynchronous: true
                                fillMode: Image.PreserveAspectCrop
                                cache: true
                                visible: opacity > 0
                                antialiasing: true

                                opacity: status === Image.Ready && cachingImage.status !== Image.Ready ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 1000
                                        easing.type: Easing.OutQuad
                                    }
                                }
                            }

                            // Timer to trigger fallback only if caching hasn't loaded
                            Timer {
                                id: fallbackTimer

                                property bool triggered: false
                                interval: 800
                                running: cachingImage.status === Image.Loading || cachingImage.status === Image.Null
                                onTriggered: triggered = true
                            }
                        }

                        // Border overlay that doesn't affect image size
                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: Appearance.spacing.normal / 2
                            anchors.rightMargin: Appearance.spacing.normal / 2
                            anchors.topMargin: Appearance.spacing.normal / 2
                            anchors.bottomMargin: Appearance.spacing.normal / 2
                            color: "transparent"
                            radius: Appearance.rounding.normal
                            border.width: isCurrent ? 2 : 0
                            border.color: Colours.palette.m3primary
                            antialiasing: true

                            Behavior on border.width {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutQuad
                                }
                            }

                            MaterialIcon {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Appearance.padding.small

                                visible: isCurrent
                                text: "check_circle"
                                color: Colours.palette.m3primary
                                font.pointSize: Appearance.font.size.large
                            }

                            // Gradient overlay for filename with rounded bottom corners
                            Rectangle {
                                id: filenameOverlay

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.leftMargin: isCurrent ? 2 : 0
                                anchors.rightMargin: isCurrent ? 2 : 0
                                anchors.bottomMargin: isCurrent ? 2 : 0

                                implicitHeight: filenameText.implicitHeight + Appearance.padding.normal * 1.5

                                // Only round bottom corners
                                topLeftRadius: 0
                                topRightRadius: 0
                                bottomLeftRadius: Appearance.rounding.normal
                                bottomRightRadius: Appearance.rounding.normal

                                Behavior on anchors.leftMargin {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutQuad
                                    }
                                }
                                
                                Behavior on anchors.rightMargin {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutQuad
                                    }
                                }
                                
                                Behavior on anchors.bottomMargin {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutQuad
                                    }
                                }

                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: Qt.rgba(Colours.palette.m3surfaceContainer.r, 
                                                      Colours.palette.m3surfaceContainer.g, 
                                                      Colours.palette.m3surfaceContainer.b, 0)
                                    }
                                    GradientStop {
                                        position: 0.3
                                        color: Qt.rgba(Colours.palette.m3surfaceContainer.r, 
                                                      Colours.palette.m3surfaceContainer.g, 
                                                      Colours.palette.m3surfaceContainer.b, 0.7)
                                    }
                                    GradientStop {
                                        position: 0.6
                                        color: Qt.rgba(Colours.palette.m3surfaceContainer.r, 
                                                      Colours.palette.m3surfaceContainer.g, 
                                                      Colours.palette.m3surfaceContainer.b, 0.9)
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: Qt.rgba(Colours.palette.m3surfaceContainer.r, 
                                                      Colours.palette.m3surfaceContainer.g, 
                                                      Colours.palette.m3surfaceContainer.b, 0.95)
                                    }
                                }
                            }

                            opacity: 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 1000
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Component.onCompleted: {
                                opacity = 1;
                            }
                        }

                        StyledText {
                            id: filenameText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: Appearance.padding.normal
                            anchors.rightMargin: Appearance.padding.normal
                            anchors.bottomMargin: Appearance.padding.normal

                            readonly property string fileName: {
                                const path = modelData.relativePath || "";
                                const parts = path.split("/");
                                return parts.length > 0 ? parts[parts.length - 1] : path;
                            }

                            text: fileName
                            font.pointSize: Appearance.font.size.smaller
                            font.weight: 500
                            color: isCurrent ? Colours.palette.m3primary : Colours.palette.m3onSurface
                            elide: Text.ElideMiddle
                            maximumLineCount: 1
                            horizontalAlignment: Text.AlignHCenter

                            opacity: 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 1000
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Component.onCompleted: {
                                opacity = 1;
                            }
                        }
                    }
                }
                }
            }
        }
    }
    }
}
