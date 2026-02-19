import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.components
import qs.components.misc
import qs.config
import qs.services

Item {
    id: root

    readonly property int minWidth: 400 + 400 + Appearance.spacing.normal + 120 + Appearance.padding.large * 2

    function displayTemp(temp: real): string {
        return `${Math.ceil(Config.services.useFahrenheit ? temp * 1.8 + 32 : temp)}°${Config.services.useFahrenheit ? "F" : "C"}`;
    }

    implicitWidth: Math.max(minWidth, content.implicitWidth)
    implicitHeight: placeholder.visible ? placeholder.height : content.implicitHeight

    StyledRect {
        id: placeholder

        anchors.centerIn: parent
        width: 400
        height: 350
        radius: Appearance.rounding.large
        color: Colours.tPalette.m3surfaceContainer
        visible: !Config.dashboard.performance.showCpu && !(Config.dashboard.performance.showGpu && SystemUsage.gpuType !== "NONE") && !Config.dashboard.performance.showMemory && !Config.dashboard.performance.showStorage && !Config.dashboard.performance.showNetwork && !(UPower.displayDevice.isLaptopBattery && Config.dashboard.performance.showBattery)

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacing.normal

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "tune"
                font.pointSize: Appearance.font.size.extraLarge * 2
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("No widgets enabled")
                font.pointSize: Appearance.font.size.large
                color: Colours.palette.m3onSurface
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Enable widgets in dashboard settings")
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    RowLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Appearance.spacing.normal
        visible: !placeholder.visible

        Ref {
            service: SystemUsage
        }

        ColumnLayout {
            id: mainColumn

            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal
                visible: Config.dashboard.performance.showCpu || (Config.dashboard.performance.showGpu && SystemUsage.gpuType !== "NONE")

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
                    visible: Config.dashboard.performance.showGpu && SystemUsage.gpuType !== "NONE"
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
                visible: Config.dashboard.performance.showMemory || Config.dashboard.performance.showStorage || Config.dashboard.performance.showNetwork

                GaugeCard {
                    Layout.minimumWidth: 250
                    Layout.preferredHeight: 220
                    Layout.fillWidth: !Config.dashboard.performance.showStorage && !Config.dashboard.performance.showNetwork
                    icon: "memory_alt"
                    title: qsTr("Memory")
                    percentage: SystemUsage.memPerc
                    subtitle: {
                        const usedFmt = SystemUsage.formatKib(SystemUsage.memUsed);
                        const totalFmt = SystemUsage.formatKib(SystemUsage.memTotal);
                        return `${usedFmt.value.toFixed(1)} / ${Math.floor(totalFmt.value)} ${totalFmt.unit}`;
                    }
                    accentColor: Colours.palette.m3tertiary
                    visible: Config.dashboard.performance.showMemory
                }

                StorageGaugeCard {
                    Layout.minimumWidth: 250
                    Layout.preferredHeight: 220
                    Layout.fillWidth: !Config.dashboard.performance.showNetwork
                    visible: Config.dashboard.performance.showStorage
                }

                NetworkCard {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 200
                    Layout.preferredHeight: 220
                    visible: Config.dashboard.performance.showNetwork
                }
            }
        }

        BatteryTank {
            Layout.preferredWidth: 120
            Layout.preferredHeight: mainColumn.implicitHeight
            visible: UPower.displayDevice.isLaptopBattery && Config.dashboard.performance.showBattery
        }
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
            anchors.margins: Appearance.padding.large
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
                    font.pointSize: Appearance.font.size.large
                    color: batteryTank.accentColor
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Battery")
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurface
                }
            }

            Item {
                Layout.fillHeight: true
            }

            // Bottom Info Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: -4

                StyledText {
                    Layout.alignment: Qt.AlignRight
                    text: `${Math.round(batteryTank.percentage * 100)}%`
                    font.pointSize: Appearance.font.size.extraLarge
                    font.weight: Font.Medium
                    color: batteryTank.accentColor
                }

                StyledText {
                    Layout.alignment: Qt.AlignRight
                    text: {
                        if (UPower.displayDevice.state === UPowerDeviceState.FullyCharged)
                            return qsTr("Full");

                        if (batteryTank.isCharging)
                            return qsTr("Charging");

                        const s = UPower.displayDevice.timeToEmpty;
                        if (s === 0)
                            return qsTr("...");

                        const hr = Math.floor(s / 3600);
                        const min = Math.floor((s % 3600) / 60);
                        if (hr > 0)
                            return `${hr}h ${min}m`;

                        return `${min}m`;
                    }
                    font.pointSize: Appearance.font.size.smaller
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        Behavior on animatedPercentage {
            Anim {
                duration: Appearance.anim.durations.large
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
            font.pointSize: Appearance.spacing.large
        }

        StyledText {
            Layout.fillWidth: true
            text: parent.title
            font.pointSize: Appearance.font.size.normal
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

        StyledRect {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * progressBar.animatedValue
            color: progressBar.fgColor
            radius: Appearance.rounding.full
        }

        Behavior on animatedValue {
            Anim {
                duration: Appearance.anim.durations.large
            }
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
            animatedUsage = usage;
            animatedTemp = tempProgress;
        }
        onUsageChanged: animatedUsage = usage
        onTempProgressChanged: animatedTemp = tempProgress

        StyledRect {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * heroCard.animatedUsage
            color: Qt.alpha(heroCard.accentColor, 0.15)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: Appearance.padding.large
            anchors.topMargin: Appearance.padding.normal
            anchors.bottomMargin: Appearance.padding.normal
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
                            font.pointSize: Appearance.font.size.normal
                            font.weight: Font.Medium
                        }

                        StyledText {
                            text: heroCard.secondaryLabel
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3onSurfaceVariant
                            anchors.baseline: parent.children[0].baseline
                        }
                    }

                    ProgressBar {
                        width: parent.width * 0.5
                        height: 6
                        value: heroCard.tempProgress
                        fgColor: heroCard.accentColor
                        bgColor: Qt.alpha(heroCard.accentColor, 0.2)
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }

        Column {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large
            anchors.rightMargin: 32
            spacing: 0

            StyledText {
                anchors.right: parent.right
                text: heroCard.mainLabel
                font.pointSize: Appearance.font.size.normal
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                anchors.right: parent.right
                text: heroCard.mainValue
                font.pointSize: Appearance.font.size.extraLarge
                font.weight: Font.Medium
                color: heroCard.accentColor
            }
        }

        Behavior on animatedUsage {
            Anim {
                duration: Appearance.anim.durations.large
            }
        }

        Behavior on animatedTemp {
            Anim {
                duration: Appearance.anim.durations.large
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

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large
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
                        const radius = (Math.min(width, height) - 12) / 2;
                        const lineWidth = 10;
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
                    Component.onCompleted: requestPaint()

                    Connections {
                        function onAnimatedPercentageChanged() {
                            gaugeCanvas.requestPaint();
                        }

                        target: gaugeCard
                    }

                    Connections {
                        function onPaletteChanged() {
                            gaugeCanvas.requestPaint();
                        }

                        target: Colours
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    text: `${Math.round(gaugeCard.percentage * 100)}%`
                    font.pointSize: Appearance.font.size.extraLarge
                    font.weight: Font.Medium
                    color: gaugeCard.accentColor
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: gaugeCard.subtitle
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        Behavior on animatedPercentage {
            Anim {
                duration: Appearance.anim.durations.large
            }
        }
    }

    component StorageGaugeCard: StyledRect {
        id: storageGaugeCard

        property int currentDiskIndex: 0
        readonly property var currentDisk: SystemUsage.disks.length > 0 ? SystemUsage.disks[currentDiskIndex] : null
        property int diskCount: 0
        readonly property real arcStartAngle: 0.75 * Math.PI
        readonly property real arcSweep: 1.5 * Math.PI
        property real animatedPercentage: 0
        property color accentColor: Colours.palette.m3secondary

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.large
        clip: true
        Component.onCompleted: {
            diskCount = SystemUsage.disks.length;
            if (currentDisk)
                animatedPercentage = currentDisk.perc;
        }
        onCurrentDiskChanged: {
            if (currentDisk)
                animatedPercentage = currentDisk.perc;
        }

        // Update diskCount and animatedPercentage when disks data changes
        Connections {
            function onDisksChanged() {
                if (SystemUsage.disks.length !== storageGaugeCard.diskCount)
                    storageGaugeCard.diskCount = SystemUsage.disks.length;

                // Update animated percentage when disk data refreshes
                if (storageGaugeCard.currentDisk)
                    storageGaugeCard.animatedPercentage = storageGaugeCard.currentDisk.perc;
            }

            target: SystemUsage
        }

        MouseArea {
            anchors.fill: parent
            onWheel: wheel => {
                if (wheel.angleDelta.y > 0)
                    storageGaugeCard.currentDiskIndex = (storageGaugeCard.currentDiskIndex - 1 + storageGaugeCard.diskCount) % storageGaugeCard.diskCount;
                else if (wheel.angleDelta.y < 0)
                    storageGaugeCard.currentDiskIndex = (storageGaugeCard.currentDiskIndex + 1) % storageGaugeCard.diskCount;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.smaller

            CardHeader {
                icon: "hard_disk"
                title: {
                    const base = qsTr("Storage");
                    if (!storageGaugeCard.currentDisk)
                        return base;

                    return `${base} - ${storageGaugeCard.currentDisk.mount}`;
                }
                accentColor: storageGaugeCard.accentColor

                // Scroll hint icon
                MaterialIcon {
                    text: "unfold_more"
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.normal
                    visible: storageGaugeCard.diskCount > 1
                    opacity: 0.7
                    ToolTip.visible: hintHover.hovered
                    ToolTip.text: qsTr("Scroll to switch disks")
                    ToolTip.delay: 500

                    HoverHandler {
                        id: hintHover
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Canvas {
                    id: storageGaugeCanvas

                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const cx = width / 2;
                        const cy = height / 2;
                        const radius = (Math.min(width, height) - 12) / 2;
                        const lineWidth = 10;
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, storageGaugeCard.arcStartAngle, storageGaugeCard.arcStartAngle + storageGaugeCard.arcSweep);
                        ctx.lineWidth = lineWidth;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = Colours.layer(Colours.palette.m3surfaceContainerHigh, 2);
                        ctx.stroke();
                        if (storageGaugeCard.animatedPercentage > 0) {
                            ctx.beginPath();
                            ctx.arc(cx, cy, radius, storageGaugeCard.arcStartAngle, storageGaugeCard.arcStartAngle + storageGaugeCard.arcSweep * storageGaugeCard.animatedPercentage);
                            ctx.lineWidth = lineWidth;
                            ctx.lineCap = "round";
                            ctx.strokeStyle = storageGaugeCard.accentColor;
                            ctx.stroke();
                        }
                    }
                    Component.onCompleted: requestPaint()

                    Connections {
                        function onAnimatedPercentageChanged() {
                            storageGaugeCanvas.requestPaint();
                        }

                        target: storageGaugeCard
                    }

                    Connections {
                        function onPaletteChanged() {
                            storageGaugeCanvas.requestPaint();
                        }

                        target: Colours
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    text: storageGaugeCard.currentDisk ? `${Math.round(storageGaugeCard.currentDisk.perc * 100)}%` : "—"
                    font.pointSize: Appearance.font.size.extraLarge
                    font.weight: Font.Medium
                    color: storageGaugeCard.accentColor
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: {
                    if (!storageGaugeCard.currentDisk)
                        return "—";

                    const usedFmt = SystemUsage.formatKib(storageGaugeCard.currentDisk.used);
                    const totalFmt = SystemUsage.formatKib(storageGaugeCard.currentDisk.total);
                    return `${usedFmt.value.toFixed(1)} / ${Math.floor(totalFmt.value)} ${totalFmt.unit}`;
                }
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        Behavior on animatedPercentage {
            Anim {
                duration: Appearance.anim.durations.large
            }
        }
    }

    component NetworkCard: StyledRect {
        id: networkCard

        property color accentColor: Colours.palette.m3primary

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.large
        clip: true

        Ref {
            service: NetworkUsage
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.small

            CardHeader {
                icon: "swap_vert"
                title: qsTr("Network")
                accentColor: networkCard.accentColor
            }

            // Sparkline graph
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Canvas {
                    id: sparklineCanvas

                    property var downHistory: NetworkUsage.downloadHistory
                    property var upHistory: NetworkUsage.uploadHistory
                    property real targetMax: 1024
                    property real smoothMax: targetMax
                    property real slideProgress: 0
                    property int _tickCount: 0
                    property int _lastTickCount: -1

                    function checkAndAnimate(): void {
                        const currentLength = (downHistory || []).length;
                        if (currentLength > 0 && _tickCount !== _lastTickCount) {
                            _lastTickCount = _tickCount;
                            updateMax();
                        }
                    }

                    function updateMax(): void {
                        const downHist = downHistory || [];
                        const upHist = upHistory || [];
                        const allValues = downHist.concat(upHist);
                        targetMax = Math.max(...allValues, 1024);
                        requestPaint();
                    }

                    anchors.fill: parent
                    onDownHistoryChanged: checkAndAnimate()
                    onUpHistoryChanged: checkAndAnimate()
                    onSmoothMaxChanged: requestPaint()
                    onSlideProgressChanged: requestPaint()

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const w = width;
                        const h = height;
                        const downHist = downHistory || [];
                        const upHist = upHistory || [];
                        if (downHist.length < 2 && upHist.length < 2)
                            return;

                        const maxVal = smoothMax;

                        const drawLine = (history, color, fillAlpha) => {
                            if (history.length < 2)
                                return;

                            const len = history.length;
                            const stepX = w / (NetworkUsage.historyLength - 1);
                            const startX = w - (len - 1) * stepX - stepX * slideProgress + stepX;
                            ctx.beginPath();
                            ctx.moveTo(startX, h - (history[0] / maxVal) * h);
                            for (let i = 1; i < len; i++) {
                                const x = startX + i * stepX;
                                const y = h - (history[i] / maxVal) * h;
                                ctx.lineTo(x, y);
                            }
                            ctx.strokeStyle = color;
                            ctx.lineWidth = 2;
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";
                            ctx.stroke();
                            ctx.lineTo(startX + (len - 1) * stepX, h);
                            ctx.lineTo(startX, h);
                            ctx.closePath();
                            ctx.fillStyle = Qt.rgba(Qt.color(color).r, Qt.color(color).g, Qt.color(color).b, fillAlpha);
                            ctx.fill();
                        };

                        drawLine(upHist, Colours.palette.m3secondary.toString(), 0.15);
                        drawLine(downHist, Colours.palette.m3tertiary.toString(), 0.2);
                    }

                    Component.onCompleted: updateMax()

                    Connections {
                        function onPaletteChanged() {
                            sparklineCanvas.requestPaint();
                        }

                        target: Colours
                    }

                    Timer {
                        interval: Config.dashboard.resourceUpdateInterval
                        running: true
                        repeat: true
                        onTriggered: sparklineCanvas._tickCount++
                    }

                    NumberAnimation on slideProgress {
                        from: 0
                        to: 1
                        duration: Config.dashboard.resourceUpdateInterval
                        loops: Animation.Infinite
                        running: true
                    }

                    Behavior on smoothMax {
                        Anim {
                            duration: Appearance.anim.durations.large
                        }
                    }
                }

                // "No data" placeholder
                StyledText {
                    anchors.centerIn: parent
                    text: qsTr("Collecting data...")
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                    visible: NetworkUsage.downloadHistory.length < 2
                    opacity: 0.6
                }
            }

            // Download row
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: "download"
                    color: Colours.palette.m3tertiary
                    font.pointSize: Appearance.font.size.normal
                }

                StyledText {
                    text: qsTr("Download")
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: {
                        const fmt = NetworkUsage.formatBytes(NetworkUsage.downloadSpeed ?? 0);
                        return fmt ? `${fmt.value.toFixed(1)} ${fmt.unit}` : "0.0 B/s";
                    }
                    font.pointSize: Appearance.font.size.normal
                    font.weight: Font.Medium
                    color: Colours.palette.m3tertiary
                }
            }

            // Upload row
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: "upload"
                    color: Colours.palette.m3secondary
                    font.pointSize: Appearance.font.size.normal
                }

                StyledText {
                    text: qsTr("Upload")
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: {
                        const fmt = NetworkUsage.formatBytes(NetworkUsage.uploadSpeed ?? 0);
                        return fmt ? `${fmt.value.toFixed(1)} ${fmt.unit}` : "0.0 B/s";
                    }
                    font.pointSize: Appearance.font.size.normal
                    font.weight: Font.Medium
                    color: Colours.palette.m3secondary
                }
            }

            // Session totals
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: "history"
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.normal
                }

                StyledText {
                    text: qsTr("Total")
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: {
                        const down = NetworkUsage.formatBytesTotal(NetworkUsage.downloadTotal ?? 0);
                        const up = NetworkUsage.formatBytesTotal(NetworkUsage.uploadTotal ?? 0);
                        return (down && up) ? `↓${down.value.toFixed(1)}${down.unit} ↑${up.value.toFixed(1)}${up.unit}` : "↓0.0B ↑0.0B";
                    }
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }
}
