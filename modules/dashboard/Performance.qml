import qs.components
import qs.components.misc
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

import Quickshell.Services.UPower

RowLayout {
    id: root

    spacing: Appearance.spacing.normal

    function displayTemp(temp: real): string {
        return `${Math.ceil(Config.services.useFahrenheit ? temp * 1.8 + 32 : temp)}°${Config.services.useFahrenheit ? "F" : "C"}`;
    }

    Ref {
        service: SystemUsage
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            HeroCard {
                Layout.fillWidth: true
                Layout.minimumWidth: 400
                Layout.preferredHeight: 150

                visible: Config.dashboard.performance.showCpu

                icon: "memory"
                title: SystemUsage.cpuName ? `CPU - ${SystemUsage.cpuName}` : qsTr("CPU")
                mainValue: `${Math.round(SystemUsage.cpuPerc * 100)}%`
                mainLabel: qsTr("Usage")
                secondaryValue: root.displayTemp(SystemUsage.cpuTemp)
                secondaryLabel: qsTr("Temp")
                usage: SystemUsage.cpuPerc
                temperature: SystemUsage.cpuTemp
                accentColor: Colours.palette.m3primary
            }

            HeroCard {
                Layout.fillWidth: true
                Layout.minimumWidth: 400
                Layout.preferredHeight: 150

                visible: Config.dashboard.performance.showGpu

                icon: "desktop_windows"
                title: SystemUsage.gpuName ? `GPU - ${SystemUsage.gpuName}` : qsTr("GPU")
                mainValue: `${Math.round(SystemUsage.gpuPerc * 100)}%`
                mainLabel: qsTr("Usage")
                secondaryValue: root.displayTemp(SystemUsage.gpuTemp)
                secondaryLabel: qsTr("Temp")
                usage: SystemUsage.gpuPerc
                temperature: SystemUsage.gpuTemp
                accentColor: Colours.palette.m3secondary
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            GaugeCard {
                Layout.minimumWidth: 250
                Layout.preferredHeight: 220

                visible: Config.dashboard.performance.showMemory

                icon: "memory_alt"
                title: qsTr("Memory")
                percentage: SystemUsage.memPerc
                subtitle: {
                    const usedFmt = SystemUsage.formatKib(SystemUsage.memUsed);
                    const totalFmt = SystemUsage.formatKib(SystemUsage.memTotal);
                    return `${usedFmt.value.toFixed(1)} / ${Math.floor(totalFmt.value)} ${totalFmt.unit}`;
                }
                accentColor: Colours.palette.m3tertiary
            }

            StorageCard {
                Layout.fillWidth: true
                Layout.minimumWidth: 550
                Layout.preferredHeight: 220

                visible: Config.dashboard.performance.showStorage
            }
        }
    }

    BatteryTank {
        Layout.preferredWidth: 120
        Layout.fillHeight: true
        Layout.minimumHeight: 350 // Match combined height + spacing roughly, or let it fill

        visible: UPower.displayDevice.isLaptopBattery && Config.dashboard.performance.showBattery
    }

    component BatteryTank: StyledClippingRect {
        id: batteryTank

        property real percentage: UPower.displayDevice.percentage
        property bool isCharging: UPower.displayDevice.state === UPowerDeviceState.Charging
        property color accentColor: Colours.palette.m3primary

        property real animatedPercentage: 0

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.large

        Component.onCompleted: animatedPercentage = percentage
        onPercentageChanged: animatedPercentage = percentage

        Behavior on animatedPercentage {
            Anim { duration: Appearance.anim.durations.large }
        }

        // Background Fill
        StyledRect {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * batteryTank.animatedPercentage

            color: Qt.alpha(batteryTank.accentColor, 0.15)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Config.dashboard.performance.batteryTankMargin
            spacing: Appearance.spacing.small

            // Header Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                MaterialIcon {
                    text: {
                        if (!UPower.displayDevice.isLaptopBattery) {
                            if (PowerProfiles.profile === PowerProfile.PowerSaver)
                                return "energy_savings_leaf";
                            if (PowerProfiles.profile === PowerProfile.Performance)
                                return "rocket_launch";
                            return "balance";
                        }

                        if (UPower.displayDevice.state === UPowerDeviceState.FullyCharged)
                            return "battery_full";

                        const perc = UPower.displayDevice.percentage;
                        const charging = [UPowerDeviceState.Charging, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state);
                        if (perc >= 0.99)
                            return "battery_full";
                        
                        let level = Math.floor(perc * 7);
                        if (charging && (level === 4 || level === 1))
                            level--;
                        return charging ? `battery_charging_${(level + 3) * 10}` : `battery_${level}_bar`;
                    }
                    font.pointSize: Config.dashboard.performance.largeIconSize
                    color: batteryTank.accentColor
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Battery")
                    font.pointSize: Config.dashboard.performance.normalTextSize
                    color: Colours.palette.m3onSurface
                }
            }

            Item { Layout.fillHeight: true }

            // Bottom Info Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Config.dashboard.performance.percentValueSpacing

                StyledText {
                    Layout.alignment: Qt.AlignRight
                    text: `${Math.round(batteryTank.percentage * 100)}%`
                    font.pointSize: Config.dashboard.performance.percentageTextSize
                    font.weight: Font.Medium
                    color: batteryTank.accentColor
                }

                StyledText {
                    Layout.alignment: Qt.AlignRight
                    text: {
                        if (UPower.displayDevice.state === UPowerDeviceState.FullyCharged) {
                            return qsTr("Full");
                        }
                        if (batteryTank.isCharging) {
                            return qsTr("Charging");
                        }
                        const s = UPower.displayDevice.timeToEmpty;
                        if (s === 0) return qsTr("...");
                        const hr = Math.floor(s / 3600);
                        const min = Math.floor((s % 3600) / 60);
                        if (hr > 0) return `${hr}h ${min}m`;
                        return `${min}m`;
                    }
                    font.pointSize: Config.dashboard.performance.usageTextSize
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }

    component CardHeader: RowLayout {
        property string icon
        property string title
        property color accentColor: Colours.palette.m3primary

        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        MaterialIcon {
            text: parent.icon
            fill: 1
            color: parent.accentColor
            font.pointSize: Config.dashboard.performance.largeIconSize
        }

        StyledText {
            Layout.fillWidth: true
            text: parent.title
            font.pointSize: Config.dashboard.performance.normalTextSize
            elide: Text.ElideRight
        }
    }

    component ProgressBar: StyledRect {
        id: progressBar

        property real value: 0
        property color fgColor: Colours.palette.m3primary
        property color bgColor: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)

        property real animatedValue: 0

        color: bgColor
        radius: Appearance.rounding.full

        Component.onCompleted: animatedValue = value
        onValueChanged: animatedValue = value

        Behavior on animatedValue {
            Anim { duration: Appearance.anim.durations.large }
        }

        StyledRect {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * progressBar.animatedValue

            color: progressBar.fgColor
            radius: Appearance.rounding.full
        }
    }

    component HeroCard: StyledClippingRect {
        id: heroCard

        property string icon
        property string title
        property string mainValue
        property string mainLabel
        property string secondaryValue
        property string secondaryLabel
        property real usage: 0
        property real temperature: 0
        property color accentColor: Colours.palette.m3primary

        readonly property real maxTemp: 100
        readonly property real tempProgress: Math.min(1, Math.max(0, temperature / maxTemp))

        property real animatedUsage: 0
        property real animatedTemp: 0

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.large

        Component.onCompleted: {
            animatedUsage = usage
            animatedTemp = tempProgress
        }

        onUsageChanged: animatedUsage = usage
        onTempProgressChanged: animatedTemp = tempProgress

        Behavior on animatedUsage {
            Anim { duration: Appearance.anim.durations.large }
        }

        Behavior on animatedTemp {
            Anim { duration: Appearance.anim.durations.large }
        }

        StyledRect {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * heroCard.animatedUsage

            color: Qt.alpha(heroCard.accentColor, 0.15)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: Config.dashboard.performance.heroCardLeftMargin
            anchors.rightMargin: Config.dashboard.performance.heroCardRightMargin
            anchors.topMargin: Config.dashboard.performance.heroCardTopMargin
            anchors.bottomMargin: Config.dashboard.performance.heroCardBottomMargin
            spacing: Appearance.spacing.small

            CardHeader {
                icon: heroCard.icon
                title: heroCard.title
                accentColor: heroCard.accentColor
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Appearance.spacing.normal

                Column {
                    Layout.alignment: Qt.AlignBottom
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    Row {
                        spacing: Appearance.spacing.small

                        StyledText {
                            text: heroCard.secondaryValue
                            font.pointSize: Config.dashboard.performance.normalTextSize
                            font.weight: Font.Medium
                        }

                        StyledText {
                            text: heroCard.secondaryLabel
                            font.pointSize: Config.dashboard.performance.valueLabelSize
                            color: Colours.palette.m3onSurfaceVariant
                            anchors.baseline: parent.children[0].baseline
                        }
                    }

                    ProgressBar {
                        width: parent.width * Config.dashboard.performance.tempBarWidthMult
                        height: Config.dashboard.performance.tempBarHeight

                        value: heroCard.tempProgress
                        fgColor: heroCard.accentColor
                        bgColor: Qt.alpha(heroCard.accentColor, 0.2)
                    }
                }

                Item { Layout.fillWidth: true }
            }

            Column {
                parent: heroCard
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Appearance.padding.large
                anchors.rightMargin: Config.dashboard.performance.heroCardRightValueMargin
                spacing: Config.dashboard.performance.mainValueSpacing

                StyledText {
                    anchors.right: parent.right
                    text: heroCard.mainLabel
                    font.pointSize: Config.dashboard.performance.normalTextSize
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    anchors.right: parent.right
                    text: heroCard.mainValue
                    font.pointSize: Config.dashboard.performance.percentageTextSize
                    font.weight: Font.Medium
                    color: heroCard.accentColor
                }

            }
        }
    }

    component GaugeCard: StyledRect {
        id: gaugeCard

        property string icon
        property string title
        property real percentage: 0
        property string subtitle
        property color accentColor: Colours.palette.m3primary

        readonly property real arcStartAngle: 0.75 * Math.PI
        readonly property real arcSweep: 1.5 * Math.PI

        property real animatedPercentage: 0

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.large
        clip: true

        Component.onCompleted: animatedPercentage = percentage
        onPercentageChanged: animatedPercentage = percentage

        Behavior on animatedPercentage {
            Anim { duration: Appearance.anim.durations.large }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Config.dashboard.performance.gaugeCardMargin
            spacing: Appearance.spacing.smaller

            CardHeader {
                icon: gaugeCard.icon
                title: gaugeCard.title
                accentColor: gaugeCard.accentColor
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Canvas {
                    id: gaugeCanvas

                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();

                        const cx = width / 2;
                        const cy = height / 2;
                        const radius = (Math.min(width, height) - Config.dashboard.performance.gaugeRadiusOffset) / 2;
                        const lineWidth = Config.dashboard.performance.gaugeLineWidth;

                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, gaugeCard.arcStartAngle, gaugeCard.arcStartAngle + gaugeCard.arcSweep);
                        ctx.lineWidth = lineWidth;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = Colours.layer(Colours.palette.m3surfaceContainerHigh, 2);
                        ctx.stroke();

                        if (gaugeCard.animatedPercentage > 0) {
                            ctx.beginPath();
                            ctx.arc(cx, cy, radius, gaugeCard.arcStartAngle, gaugeCard.arcStartAngle + gaugeCard.arcSweep * gaugeCard.animatedPercentage);
                            ctx.lineWidth = lineWidth;
                            ctx.lineCap = "round";
                            ctx.strokeStyle = gaugeCard.accentColor;
                            ctx.stroke();
                        }
                    }

                    Connections {
                        target: gaugeCard
                        function onAnimatedPercentageChanged() {
                            gaugeCanvas.requestPaint();
                        }
                    }

                    Connections {
                        target: Colours
                        function onPaletteChanged() {
                            gaugeCanvas.requestPaint();
                        }
                    }

                    Component.onCompleted: requestPaint()
                }

                StyledText {
                    anchors.centerIn: parent
                    text: `${Math.round(gaugeCard.percentage * 100)}%`
                    font.pointSize: Config.dashboard.performance.percentageTextSize
                    font.weight: Font.Medium
                    color: gaugeCard.accentColor
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: gaugeCard.subtitle
                font.pointSize: Config.dashboard.performance.usageTextSize
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    component StorageCard: StyledRect {
        id: storageCard

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.large
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Config.dashboard.performance.storageCardMargin
            spacing: Appearance.spacing.normal

            CardHeader {
                icon: "hard_disk"
                title: qsTr("Storage")
                accentColor: Colours.palette.m3secondary
            }

            Repeater {
                model: SystemUsage.disks.slice(0, 5)

                delegate: DiskRow {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.fillHeight: false    

                    diskName: modelData.mount
                    used: modelData.used
                    total: modelData.total
                    percentage: modelData.perc
                    diskColor: index === 0 ? Colours.palette.m3primary :
                               index === 1 ? Colours.palette.m3secondary :
                               index === 2 ? Colours.palette.m3tertiary :
                               index === 3 ? Colours.palette.m3outline :
                               Colours.palette.m3error
                }
            }

            Item { Layout.fillHeight: SystemUsage.disks.length < 5 }
        }
    }

    component DiskRow: Item {
        id: diskRow

        property string diskName
        property real used
        property real total
        property real percentage
        property color diskColor: Colours.palette.m3primary

        property real animatedPercentage: 0
        property bool hovered: false

        implicitHeight: rowLayout.implicitHeight

        Component.onCompleted: animatedPercentage = percentage
        onPercentageChanged: animatedPercentage = percentage

        Behavior on animatedPercentage {
            Anim { duration: Appearance.anim.durations.large }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: diskRow.hovered = true
            onExited: diskRow.hovered = false
        }

        RowLayout {
            id: rowLayout

            anchors.fill: parent
            spacing: Appearance.spacing.normal

            Rectangle {
                width: Config.dashboard.performance.diskIndicatorWidth
                Layout.fillHeight: true
                Layout.topMargin: Config.dashboard.performance.diskRowTopMargin
                Layout.bottomMargin: Config.dashboard.performance.diskRowBottomMargin
                radius: Config.dashboard.performance.diskIndicatorRadius
                color: diskRow.diskColor
            }

            StyledText {
                Layout.preferredWidth: 80
                text: diskRow.diskName
                font.pointSize: Config.dashboard.performance.usageTextSize
            }

            ProgressBar {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: Config.dashboard.performance.diskRowProgressTopMargin
                Layout.bottomMargin: Config.dashboard.performance.diskRowProgressBottomMargin

                value: diskRow.percentage
                fgColor: diskRow.diskColor
            }

            Item {
                Layout.preferredWidth: usageText.visible ? usageText.implicitWidth : percentText.implicitWidth
                Layout.minimumWidth: 35
                implicitHeight: Math.max(percentText.implicitHeight, usageText.implicitHeight)

                Behavior on Layout.preferredWidth {
                    Anim { duration: Appearance.anim.durations.normal }
                }

                StyledText {
                    id: percentText

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    visible: !diskRow.hovered
                    opacity: diskRow.hovered ? 0 : 1
                    text: `${Math.round(diskRow.percentage * 100)}%`
                    font.pointSize: Config.dashboard.performance.usageTextSize
                    font.weight: Font.Medium
                    color: diskRow.diskColor
                    horizontalAlignment: Text.AlignRight

                    Behavior on opacity {
                        Anim { duration: Appearance.anim.durations.normal }
                    }
                }

                StyledText {
                    id: usageText

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    visible: diskRow.hovered
                    opacity: diskRow.hovered ? 1 : 0
                    text: {
                        const usedFmt = SystemUsage.formatKib(diskRow.used);
                        const totalFmt = SystemUsage.formatKib(diskRow.total);
                        return `${usedFmt.value.toFixed(0)}/${totalFmt.value.toFixed(0)}${totalFmt.unit}`;
                    }
                    font.pointSize: Config.dashboard.performance.valueLabelSize
                    color: Colours.palette.m3onSurfaceVariant
                    horizontalAlignment: Text.AlignRight

                    Behavior on opacity {
                        Anim { duration: Appearance.anim.durations.normal }
                    }
                }
            }
        }
    }
}
