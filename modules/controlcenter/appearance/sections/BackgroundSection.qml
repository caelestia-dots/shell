pragma ComponentBehavior: Bound

import ".."
import "../../components"
import qs.components
import qs.components.controls
import qs.components.containers
import qs.components.images
import qs.services
import qs.config
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

CollapsibleSection {
    id: root

    required property var rootPane

    title: qsTr("Background")
    showBackground: true

    SwitchRow {
        label: qsTr("Background enabled")
        checked: rootPane.backgroundEnabled
        onToggled: checked => {
            rootPane.backgroundEnabled = checked;
            rootPane.saveConfig();
        }
    }

    SwitchRow {
        label: qsTr("Wallpaper enabled")
        checked: rootPane.wallpaperEnabled
        onToggled: checked => {
            rootPane.wallpaperEnabled = checked;
            rootPane.saveConfig();
        }
    }

    StyledText {
        Layout.topMargin: Appearance.spacing.normal
        text: qsTr("Wallpaper Transitions")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    SplitButtonRow {
        label: qsTr("Transition Type")
        expandedZ: 100

        menuItems: [
            MenuItem {
                text: qsTr("Fade")
                property string val: "fade"
            },
            MenuItem {
                text: qsTr("Wipe")
                property string val: "wipe"
            },
            MenuItem {
                text: qsTr("Disc")
                property string val: "disc"
            },
            MenuItem {
                text: qsTr("Stripes")
                property string val: "stripes"
            },
            MenuItem {
                text: qsTr("Random")
                property string val: "random"
            }
        ]

        Component.onCompleted: {
            const currentTransition = Config.background.wallpaperTransition || "fade";
            for (let i = 0; i < menuItems.length; i++) {
                if (menuItems[i].val === currentTransition)
                    active = menuItems[i];
            }
        }

        onSelected: item => {
            Config.background.wallpaperTransition = item.val;
            rootPane.saveConfig();
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true

            label: qsTr("Transition Duration")
            value: Config.background.transitionDuration || 1000
            from: 100
            to: 3000
            stepSize: 100
            suffix: "ms"
            validator: IntValidator {
                bottom: 100
                top: 3000
            }
            formatValueFunction: val => Math.round(val).toString()
            parseValueFunction: text => parseInt(text)

            onValueModified: newValue => {
                Config.background.transitionDuration = Math.round(newValue);
                rootPane.saveConfig();
            }
        }
    }

    SwitchRow {
        label: qsTr("Auto Random Wallpaper")
        checked: Config.background.autoRandomWallpaper || false
        enabled: !(Config.background.timeBasedWallpaper || false)
        onToggled: checked => {
            Config.background.autoRandomWallpaper = checked;
            rootPane.saveConfig();
        }
    }

    SectionContainer {
        visible: Config.background.autoRandomWallpaper || false
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true

            label: qsTr("Random Interval")
            value: Config.background.autoRandomInterval || 300
            from: 30
            to: 3600
            stepSize: 30
            suffix: "s"
            validator: IntValidator {
                bottom: 30
                top: 3600
            }
            formatValueFunction: val => Math.round(val).toString()
            parseValueFunction: text => parseInt(text)

            onValueModified: newValue => {
                Config.background.autoRandomInterval = Math.round(newValue);
                rootPane.saveConfig();
            }
        }
    }

    SwitchRow {
        label: qsTr("Time-Based Wallpaper")
        checked: Config.background.timeBasedWallpaper || false
        onToggled: checked => {
            Config.background.timeBasedWallpaper = checked;
            if (checked && Config.background.autoRandomWallpaper) {
                Config.background.autoRandomWallpaper = false;
            }
            rootPane.saveConfig();
        }
    }

    SectionContainer {
        visible: Config.background.timeBasedWallpaper || false
        contentSpacing: Appearance.spacing.small
        Layout.maximumWidth: parent.width

        StyledText {
            text: qsTr("Wallpaper Schedule")
            font.pointSize: Appearance.font.size.normal
            font.weight: 500
        }

        Repeater {
            model: Config.background.wallpaperSchedule || []

            delegate: Item {
                required property int index
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: scheduleColumn.implicitHeight

                ColumnLayout {
                    id: scheduleColumn
                    width: parent.width
                    spacing: Appearance.spacing.small / 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        ColumnLayout {
                            spacing: Appearance.spacing.small / 2

                            StyledText {
                                text: qsTr("Time")
                                font.pointSize: Appearance.font.size.smaller
                                color: Colours.palette.m3outline
                            }

                            RowLayout {
                                spacing: 4

                                StyledRect {
                                    Layout.preferredWidth: 45
                                    implicitHeight: Appearance.font.size.normal + Appearance.padding.large * 2
                                    color: hourField.activeFocus ? Colours.layer(Colours.palette.m3surfaceContainer, 3) : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                    radius: Appearance.rounding.small
                                    border.width: 1
                                    border.color: hourField.activeFocus ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outline, 0.3)

                                    Behavior on color {
                                        CAnim {}
                                    }
                                    Behavior on border.color {
                                        CAnim {}
                                    }

                                    StyledTextField {
                                        id: hourField
                                        anchors.fill: parent
                                        anchors.leftMargin: Appearance.padding.small
                                        anchors.rightMargin: Appearance.padding.small
                                        anchors.topMargin: Appearance.padding.small
                                        anchors.bottomMargin: Appearance.padding.small
                                        horizontalAlignment: TextInput.AlignHCenter
                                        validator: IntValidator {
                                            bottom: 0
                                            top: 23
                                        }

                                        Component.onCompleted: {
                                            if (modelData && modelData.startTime) {
                                                const parts = modelData.startTime.split(":");
                                                text = parts[0] || "00";
                                            } else {
                                                text = "00";
                                            }
                                        }

                                        onEditingFinished: {
                                            let schedule = Config.background.wallpaperSchedule || [];
                                            if (schedule[index]) {
                                                const hour = text.padStart(2, '0');
                                                const minute = minuteField.text.padStart(2, '0');
                                                schedule[index].startTime = hour + ":" + minute;
                                                Config.background.wallpaperSchedule = schedule;
                                                rootPane.saveConfig();
                                            }
                                        }
                                    }
                                }

                                StyledText {
                                    text: ":"
                                    font.pointSize: Appearance.font.size.normal
                                }

                                StyledRect {
                                    Layout.preferredWidth: 45
                                    implicitHeight: Appearance.font.size.normal + Appearance.padding.large * 2
                                    color: minuteField.activeFocus ? Colours.layer(Colours.palette.m3surfaceContainer, 3) : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                    radius: Appearance.rounding.small
                                    border.width: 1
                                    border.color: minuteField.activeFocus ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outline, 0.3)

                                    Behavior on color {
                                        CAnim {}
                                    }
                                    Behavior on border.color {
                                        CAnim {}
                                    }

                                    StyledTextField {
                                        id: minuteField
                                        anchors.fill: parent
                                        anchors.leftMargin: Appearance.padding.small
                                        anchors.rightMargin: Appearance.padding.small
                                        anchors.topMargin: Appearance.padding.small
                                        anchors.bottomMargin: Appearance.padding.small
                                        horizontalAlignment: TextInput.AlignHCenter
                                        validator: IntValidator {
                                            bottom: 0
                                            top: 59
                                        }

                                        Component.onCompleted: {
                                            if (modelData && modelData.startTime) {
                                                const parts = modelData.startTime.split(":");
                                                text = parts[1] || "00";
                                            } else {
                                                text = "00";
                                            }
                                        }

                                        onEditingFinished: {
                                            let schedule = Config.background.wallpaperSchedule || [];
                                            if (schedule[index]) {
                                                const hour = hourField.text.padStart(2, '0');
                                                const minute = text.padStart(2, '0');
                                                schedule[index].startTime = hour + ":" + minute;
                                                Config.background.wallpaperSchedule = schedule;
                                                rootPane.saveConfig();
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            spacing: Appearance.spacing.small / 2

                            StyledText {
                                text: qsTr("Wallpaper Path")
                                font.pointSize: Appearance.font.size.smaller
                                color: Colours.palette.m3outline
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                spacing: Appearance.spacing.small

                                StyledRect {
                                    Layout.fillWidth: true
                                    implicitHeight: Appearance.font.size.normal + Appearance.padding.large * 2
                                    implicitWidth: 0
                                    color: wallpaperField.activeFocus ? Colours.layer(Colours.palette.m3surfaceContainer, 3) : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                    radius: Appearance.rounding.small
                                    border.width: 1
                                    border.color: wallpaperField.activeFocus ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outline, 0.3)
                                    clip: true

                                    Behavior on color {
                                        CAnim {}
                                    }
                                    Behavior on border.color {
                                        CAnim {}
                                    }

                                    StyledTextField {
                                        id: wallpaperField
                                        width: parent.width - Appearance.padding.normal * 2
                                        height: parent.height - Appearance.padding.normal * 2
                                        anchors.centerIn: parent
                                        horizontalAlignment: TextInput.AlignLeft
                                        placeholderText: qsTr("~/Pictures/Wallpapers/...")
                                        clip: true

                                        Component.onCompleted: {
                                            if (modelData && modelData.wallpaper !== undefined) {
                                                text = modelData.wallpaper;
                                            } else {
                                                text = "";
                                            }
                                        }

                                        onEditingFinished: {
                                            let schedule = Config.background.wallpaperSchedule || [];
                                            if (schedule[index]) {
                                                schedule[index].wallpaper = text;
                                                Config.background.wallpaperSchedule = schedule;
                                                rootPane.saveConfig();
                                            }
                                        }
                                    }
                                }

                                IconButton {
                                    icon: "folder_open"
                                    onClicked: {
                                        wallpaperPickerLoader.scheduleIndex = index;
                                        wallpaperPickerLoader.active = true;
                                    }
                                }
                            }
                        }

                        IconButton {
                            Layout.alignment: Qt.AlignBottom
                            icon: "delete"
                            onClicked: {
                                let schedule = Config.background.wallpaperSchedule || [];
                                schedule.splice(index, 1);
                                Config.background.wallpaperSchedule = schedule;
                                rootPane.saveConfig();
                            }
                        }
                    }
                }
            }
        }

        TextButton {
            Layout.fillWidth: true
            Layout.minimumHeight: Appearance.font.size.normal + Appearance.padding.normal * 2
            inactiveColour: Colours.palette.m3primary
            inactiveOnColour: Colours.palette.m3onPrimary
            text: qsTr("Add Schedule Entry")

            onClicked: {
                let schedule = Config.background.wallpaperSchedule || [];
                schedule.push({
                    startTime: "00:00",
                    wallpaper: ""
                });
                Config.background.wallpaperSchedule = schedule;
                rootPane.saveConfig();
            }
        }
    }

    StyledText {
        Layout.topMargin: Appearance.spacing.normal
        text: qsTr("Desktop Clock")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    SwitchRow {
        label: qsTr("Desktop Clock enabled")
        checked: rootPane.desktopClockEnabled
        onToggled: checked => {
            rootPane.desktopClockEnabled = checked;
            rootPane.saveConfig();
        }
    }

    SectionContainer {
        id: posContainer

        contentSpacing: Appearance.spacing.small
        z: 1

        readonly property var pos: (rootPane.desktopClockPosition || "top-left").split('-')
        readonly property string currentV: pos[0]
        readonly property string currentH: pos[1]

        function updateClockPos(v, h) {
            rootPane.desktopClockPosition = v + "-" + h;
            rootPane.saveConfig();
        }

        StyledText {
            text: qsTr("Positioning")
            font.pointSize: Appearance.font.size.larger
            font.weight: 500
        }

        SplitButtonRow {
            label: qsTr("Vertical Position")
            enabled: rootPane.desktopClockEnabled

            menuItems: [
                MenuItem {
                    text: qsTr("Top")
                    icon: "vertical_align_top"
                    property string val: "top"
                },
                MenuItem {
                    text: qsTr("Middle")
                    icon: "vertical_align_center"
                    property string val: "middle"
                },
                MenuItem {
                    text: qsTr("Bottom")
                    icon: "vertical_align_bottom"
                    property string val: "bottom"
                }
            ]

            Component.onCompleted: {
                for (let i = 0; i < menuItems.length; i++) {
                    if (menuItems[i].val === posContainer.currentV)
                        active = menuItems[i];
                }
            }

            // The signal from SplitButtonRow
            onSelected: item => posContainer.updateClockPos(item.val, posContainer.currentH)
        }

        SplitButtonRow {
            label: qsTr("Horizontal Position")
            enabled: rootPane.desktopClockEnabled
            expandedZ: 99

            menuItems: [
                MenuItem {
                    text: qsTr("Left")
                    icon: "align_horizontal_left"
                    property string val: "left"
                },
                MenuItem {
                    text: qsTr("Center")
                    icon: "align_horizontal_center"
                    property string val: "center"
                },
                MenuItem {
                    text: qsTr("Right")
                    icon: "align_horizontal_right"
                    property string val: "right"
                }
            ]

            Component.onCompleted: {
                for (let i = 0; i < menuItems.length; i++) {
                    if (menuItems[i].val === posContainer.currentH)
                        active = menuItems[i];
                }
            }

            onSelected: item => posContainer.updateClockPos(posContainer.currentV, item.val)
        }
    }

    SwitchRow {
        label: qsTr("Invert colors")
        checked: rootPane.desktopClockInvertColors
        onToggled: checked => {
            rootPane.desktopClockInvertColors = checked;
            rootPane.saveConfig();
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.small

        StyledText {
            text: qsTr("Shadow")
            font.pointSize: Appearance.font.size.larger
            font.weight: 500
        }

        SwitchRow {
            label: qsTr("Enabled")
            checked: rootPane.desktopClockShadowEnabled
            onToggled: checked => {
                rootPane.desktopClockShadowEnabled = checked;
                rootPane.saveConfig();
            }
        }

        SectionContainer {
            contentSpacing: Appearance.spacing.normal

            SliderInput {
                Layout.fillWidth: true

                label: qsTr("Opacity")
                value: rootPane.desktopClockShadowOpacity * 100
                from: 0
                to: 100
                suffix: "%"
                validator: IntValidator {
                    bottom: 0
                    top: 100
                }
                formatValueFunction: val => Math.round(val).toString()
                parseValueFunction: text => parseInt(text)

                onValueModified: newValue => {
                    rootPane.desktopClockShadowOpacity = newValue / 100;
                    rootPane.saveConfig();
                }
            }
        }

        SectionContainer {
            contentSpacing: Appearance.spacing.normal

            SliderInput {
                Layout.fillWidth: true

                label: qsTr("Blur")
                value: rootPane.desktopClockShadowBlur * 100
                from: 0
                to: 100
                suffix: "%"
                validator: IntValidator {
                    bottom: 0
                    top: 100
                }
                formatValueFunction: val => Math.round(val).toString()
                parseValueFunction: text => parseInt(text)

                onValueModified: newValue => {
                    rootPane.desktopClockShadowBlur = newValue / 100;
                    rootPane.saveConfig();
                }
            }
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.small

        StyledText {
            text: qsTr("Background")
            font.pointSize: Appearance.font.size.larger
            font.weight: 500
        }

        SwitchRow {
            label: qsTr("Enabled")
            checked: rootPane.desktopClockBackgroundEnabled
            onToggled: checked => {
                rootPane.desktopClockBackgroundEnabled = checked;
                rootPane.saveConfig();
            }
        }

        SwitchRow {
            label: qsTr("Blur enabled")
            checked: rootPane.desktopClockBackgroundBlur
            onToggled: checked => {
                rootPane.desktopClockBackgroundBlur = checked;
                rootPane.saveConfig();
            }
        }

        SectionContainer {
            contentSpacing: Appearance.spacing.normal

            SliderInput {
                Layout.fillWidth: true

                label: qsTr("Opacity")
                value: rootPane.desktopClockBackgroundOpacity * 100
                from: 0
                to: 100
                suffix: "%"
                validator: IntValidator {
                    bottom: 0
                    top: 100
                }
                formatValueFunction: val => Math.round(val).toString()
                parseValueFunction: text => parseInt(text)

                onValueModified: newValue => {
                    rootPane.desktopClockBackgroundOpacity = newValue / 100;
                    rootPane.saveConfig();
                }
            }
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

        SliderInput {
            Layout.fillWidth: true

            label: qsTr("Visualiser rounding")
            value: rootPane.visualiserRounding
            from: 0
            to: 10
            stepSize: 1
            validator: IntValidator {
                bottom: 0
                top: 10
            }
            formatValueFunction: val => Math.round(val).toString()
            parseValueFunction: text => parseInt(text)

            onValueModified: newValue => {
                rootPane.visualiserRounding = Math.round(newValue);
                rootPane.saveConfig();
            }
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true

            label: qsTr("Visualiser spacing")
            value: rootPane.visualiserSpacing
            from: 0
            to: 2
            validator: DoubleValidator {
                bottom: 0
                top: 2
            }

            onValueModified: newValue => {
                rootPane.visualiserSpacing = newValue;
                rootPane.saveConfig();
            }
        }
    }

    Loader {
        id: wallpaperPickerLoader
        active: false
        visible: false
        width: 0
        height: 0

        property int scheduleIndex: -1

        sourceComponent: Item {
            id: modalContainer

            Component.onCompleted: {
                parent = Overlay.overlay;
                anchors.fill = parent;
            }

            function closeModal() {
                backgroundRect.opacity = 0;
                modalRect.scale = 0.9;
                modalRect.opacity = 0;
                closeTimer.start();
            }

            Timer {
                id: closeTimer
                interval: 250
                onTriggered: wallpaperPickerLoader.active = false
            }

            Rectangle {
                id: backgroundRect
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.7)
                z: 1000

                opacity: 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                Component.onCompleted: {
                    opacity = 1;
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: modalContainer.closeModal()
                }

                StyledRect {
                    id: modalRect
                    anchors.centerIn: parent
                    width: Math.min(parent.width * 0.9, 760)
                    height: Math.min(parent.height * 0.9, 600)
                    color: Colours.palette.m3surface
                    radius: Appearance.rounding.large

                    scale: 0.9
                    opacity: 0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.2
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    Component.onCompleted: {
                        scale = 1;
                        opacity = 1;
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {}
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Appearance.padding.large
                        spacing: Appearance.spacing.normal

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            StyledText {
                                text: qsTr("Select Wallpaper")
                                font.pointSize: Appearance.font.size.larger
                                font.weight: 600
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            IconButton {
                                icon: "close"
                                type: IconButton.Text
                                label.color: mouseArea.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                onClicked: modalContainer.closeModal()

                                MouseArea {
                                    id: mouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: parent.clicked()
                                }
                            }
                        }

                        GridView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            cellWidth: 180
                            cellHeight: 130
                            model: Wallpapers.list

                            StyledScrollBar.vertical: StyledScrollBar {
                                flickable: parent
                            }

                            delegate: Item {
                                required property var modelData

                                width: 180
                                height: 130

                                StyledRect {
                                    anchors.fill: parent
                                    anchors.margins: Appearance.spacing.small
                                    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                    radius: Appearance.rounding.normal
                                    border.width: wallpaperMouseArea.containsMouse ? 2 : 0
                                    border.color: Colours.palette.m3primary

                                    Behavior on border.width {
                                        NumberAnimation {
                                            duration: 100
                                        }
                                    }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: Appearance.padding.small
                                        spacing: Appearance.spacing.small

                                        StyledClippingRect {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            color: Colours.palette.m3surfaceContainer
                                            radius: Appearance.rounding.small

                                            CachingImage {
                                                id: cachingImage
                                                anchors.fill: parent
                                                path: modelData.path
                                                fillMode: Image.PreserveAspectCrop
                                                cache: true
                                                antialiasing: true
                                                smooth: true
                                                sourceSize: Qt.size(width, height)

                                                opacity: status === Image.Ready ? 1 : 0

                                                Behavior on opacity {
                                                    NumberAnimation {
                                                        duration: 300
                                                        easing.type: Easing.OutQuad
                                                    }
                                                }
                                            }

                                            Image {
                                                id: fallbackImage
                                                anchors.fill: parent
                                                source: fallbackTimer.triggered && cachingImage.status !== Image.Ready ? modelData.path : ""
                                                asynchronous: true
                                                fillMode: Image.PreserveAspectCrop
                                                cache: true
                                                antialiasing: true
                                                smooth: true
                                                sourceSize: Qt.size(width, height)

                                                opacity: status === Image.Ready && cachingImage.status !== Image.Ready ? 1 : 0

                                                Behavior on opacity {
                                                    NumberAnimation {
                                                        duration: 300
                                                        easing.type: Easing.OutQuad
                                                    }
                                                }
                                            }

                                            Timer {
                                                id: fallbackTimer
                                                property bool triggered: false
                                                interval: 800
                                                running: cachingImage.status === Image.Loading || cachingImage.status === Image.Null
                                                onTriggered: triggered = true
                                            }

                                            StyledRect {
                                                anchors.fill: parent
                                                color: Colours.palette.m3surfaceContainer
                                                visible: cachingImage.status === Image.Loading && !fallbackTimer.triggered

                                                StyledText {
                                                    anchors.centerIn: parent
                                                    text: "..."
                                                    color: Colours.palette.m3outline
                                                }
                                            }
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: modelData.name
                                            font.pointSize: Appearance.font.size.smaller
                                            elide: Text.ElideMiddle
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                    }
                                }

                                MouseArea {
                                    id: wallpaperMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        let schedule = Config.background.wallpaperSchedule || [];
                                        if (schedule[wallpaperPickerLoader.scheduleIndex]) {
                                            schedule[wallpaperPickerLoader.scheduleIndex].wallpaper = modelData.path;
                                            Config.background.wallpaperSchedule = schedule;
                                            rootPane.saveConfig();
                                        }
                                        modalContainer.closeModal();
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
