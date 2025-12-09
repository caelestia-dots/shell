import qs.components
import qs.components.misc
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

RowLayout {
    id: root

    readonly property int padding: Appearance.padding.large
    readonly property int visibleCount: (Config.dashboard.performance.showBattery ? 1 : 0) +
                                        (Config.dashboard.performance.showGpu ? 1 : 0) +
                                        (Config.dashboard.performance.showCpu ? 1 : 0) +
                                        (Config.dashboard.performance.showMemory ? 1 : 0) +
                                        (Config.dashboard.performance.showStorage ? 1 : 0)
    // Scale factor: 1.0 for 3 or less, progressively smaller for more items
    readonly property real scaleFactor: visibleCount <= 3 ? 1.0 : (visibleCount === 4 ? 0.85 : 0.72)
    readonly property real dynamicSpacing: Appearance.spacing.large * (visibleCount <= 3 ? 3 : (visibleCount === 4 ? 2 : 1.5))
    readonly property real dynamicPrimaryMult: visibleCount <= 3 ? 1.2 : 1.0
    readonly property real dynamicPadding: padding * scaleFactor

    function displayTemp(temp: real): string {
        return `${Math.ceil(Config.services.useFahrenheit ? temp * 1.8 + 32 : temp)}°${Config.services.useFahrenheit ? "F" : "C"}`;
    }

    spacing: root.dynamicSpacing

    Ref {
        service: SystemUsage
    }

    // Battery Resource
    Resource {
        Layout.alignment: Qt.AlignVCenter
        Layout.topMargin: root.dynamicPadding
        Layout.bottomMargin: root.dynamicPadding
        Layout.leftMargin: root.dynamicPadding * 2
        Layout.rightMargin: !Config.dashboard.performance.showGpu && !Config.dashboard.performance.showCpu && !Config.dashboard.performance.showMemory && !Config.dashboard.performance.showStorage ? root.dynamicPadding * 3 : 0

        visible: Config.dashboard.performance.showBattery

        value1: UPower.displayDevice.isLaptopBattery ? UPower.displayDevice.percentage : 0
        value2: 0

        label1: UPower.displayDevice.isLaptopBattery ? `${Math.round(UPower.displayDevice.percentage * 100)}%` : "N/A"
        label2: {
            if (!UPower.displayDevice.isLaptopBattery) return "No Battery";
            if (UPower.onBattery) {
                const timeToEmpty = UPower.displayDevice.timeToEmpty;
                if (timeToEmpty > 0) {
                    const hours = Math.floor(timeToEmpty / 3600);
                    const minutes = Math.floor((timeToEmpty % 3600) / 60);
                    return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
                }
                return qsTr("Discharging");
            } else {
                const timeToFull = UPower.displayDevice.timeToFull;
                if (timeToFull > 0) {
                    const hours = Math.floor(timeToFull / 3600);
                    const minutes = Math.floor((timeToFull % 3600) / 60);
                    return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
                }
                return qsTr("Charging");
            }
        }

        sublabel1: qsTr("Battery")
        sublabel2: UPower.onBattery ? qsTr("Remaining") : qsTr("To Full")
    }

    // GPU Resource
    Resource {
        Layout.alignment: Qt.AlignVCenter
        Layout.topMargin: root.dynamicPadding
        Layout.bottomMargin: root.dynamicPadding
        Layout.leftMargin: !Config.dashboard.performance.showBattery ? root.dynamicPadding * 2 : 0
        Layout.rightMargin: !Config.dashboard.performance.showCpu && !Config.dashboard.performance.showMemory && !Config.dashboard.performance.showStorage ? root.dynamicPadding * 3 : 0

        visible: Config.dashboard.performance.showGpu

        value1: Math.min(1, SystemUsage.gpuTemp / 90)
        value2: SystemUsage.gpuPerc

        label1: root.displayTemp(SystemUsage.gpuTemp)
        label2: `${Math.round(SystemUsage.gpuPerc * 100)}%`

        sublabel1: qsTr("GPU temp")
        sublabel2: qsTr("Usage")
    }

    // CPU Resource (primary)
    Resource {
        Layout.alignment: Qt.AlignVCenter
        Layout.topMargin: root.dynamicPadding
        Layout.bottomMargin: root.dynamicPadding
        Layout.leftMargin: !Config.dashboard.performance.showBattery && !Config.dashboard.performance.showGpu ? root.dynamicPadding * 2 : 0
        Layout.rightMargin: !Config.dashboard.performance.showMemory && !Config.dashboard.performance.showStorage ? root.dynamicPadding * 3 : 0

        visible: Config.dashboard.performance.showCpu
        primary: true

        value1: Math.min(1, SystemUsage.cpuTemp / 90)
        value2: SystemUsage.cpuPerc

        label1: root.displayTemp(SystemUsage.cpuTemp)
        label2: `${Math.round(SystemUsage.cpuPerc * 100)}%`

        sublabel1: qsTr("CPU temp")
        sublabel2: qsTr("Usage")
    }

    // Memory Resource
    Resource {
        Layout.alignment: Qt.AlignVCenter
        Layout.topMargin: root.dynamicPadding
        Layout.bottomMargin: root.dynamicPadding
        Layout.rightMargin: !Config.dashboard.performance.showStorage ? root.dynamicPadding * 3 : 0

        visible: Config.dashboard.performance.showMemory
        primary: !Config.dashboard.performance.showCpu

        value1: SystemUsage.memPerc
        // value2: SystemUsage.memPerc

        label1: {
            const fmt = SystemUsage.formatKib(SystemUsage.memUsed);
            return `${+fmt.value.toFixed(1)}${fmt.unit}`;
        }
        label2: `${Math.round(SystemUsage.memPerc * 100)}%`

        sublabel1: qsTr("Memory")
        sublabel2: {
            const totalFmt = SystemUsage.formatKib(SystemUsage.memTotal);
            return `of ${Math.floor(totalFmt.value)}${totalFmt.unit}`;
        }
    }

    // Storage Resource
    Resource {
        Layout.alignment: Qt.AlignVCenter
        Layout.topMargin: root.dynamicPadding
        Layout.bottomMargin: root.dynamicPadding
        Layout.rightMargin: root.dynamicPadding * 3

        visible: Config.dashboard.performance.showStorage

        value1: SystemUsage.storagePerc
        // value2: SystemUsage.storagePerc

        label1: {
            const fmt = SystemUsage.formatKib(SystemUsage.storageUsed);
            return `${Math.floor(fmt.value)}${fmt.unit}`;
        }
        label2: `${Math.round(SystemUsage.storagePerc * 100)}%`

        sublabel1: qsTr("Storage")
        sublabel2: {
            const totalFmt = SystemUsage.formatKib(SystemUsage.storageTotal);
            return `of ${Math.floor(totalFmt.value)}${totalFmt.unit}`;
        }
    }

    component Resource: Item {
        id: res

        required property real value1
        required property real value2
        required property string sublabel1
        required property string sublabel2
        required property string label1
        required property string label2

        property bool primary
        readonly property real primaryMult: primary ? root.dynamicPrimaryMult : 1
        readonly property real sizeMultiplier: root.scaleFactor * primaryMult

        readonly property real thickness: Config.dashboard.sizes.resourceProgessThickness * sizeMultiplier
        readonly property bool showSecondArc: value2 > 0

        property color fg1: Colours.palette.m3primary
        property color fg2: Colours.palette.m3secondary
        property color bg1: Colours.palette.m3primaryContainer
        property color bg2: Colours.palette.m3secondaryContainer

        implicitWidth: Config.dashboard.sizes.resourceSize * sizeMultiplier
        implicitHeight: Config.dashboard.sizes.resourceSize * sizeMultiplier

        onValue1Changed: canvas.requestPaint()
        onValue2Changed: canvas.requestPaint()
        onFg1Changed: canvas.requestPaint()
        onFg2Changed: canvas.requestPaint()
        onBg1Changed: canvas.requestPaint()
        onBg2Changed: canvas.requestPaint()

        Column {
            anchors.centerIn: parent

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter

                text: res.label1
                font.pointSize: Appearance.font.size.extraLarge * res.sizeMultiplier
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter

                text: res.sublabel1
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.smaller * res.sizeMultiplier
            }
        }

        Column {
            anchors.horizontalCenter: parent.right
            anchors.top: parent.verticalCenter
            anchors.horizontalCenterOffset: -res.thickness / 2
            anchors.topMargin: res.thickness / 2 + Appearance.spacing.small * root.scaleFactor
            visible: res.showSecondArc

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter

                text: res.label2
                font.pointSize: Appearance.font.size.smaller * res.sizeMultiplier
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter

                text: res.sublabel2
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small * res.sizeMultiplier
            }
        }

        // Alternative layout for single value displays (like battery status)
        Column {
            anchors.horizontalCenter: parent.right
            anchors.top: parent.verticalCenter
            anchors.horizontalCenterOffset: -res.thickness / 2
            anchors.topMargin: res.thickness / 2 + Appearance.spacing.small * root.scaleFactor
            visible: !res.showSecondArc

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter

                text: res.label2
                font.pointSize: Appearance.font.size.smaller * res.sizeMultiplier
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter

                text: res.sublabel2
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small * res.sizeMultiplier
            }
        }

        Canvas {
            id: canvas

            readonly property real centerX: width / 2
            readonly property real centerY: height / 2

            readonly property real arc1Start: degToRad(45)
            readonly property real arc1End: degToRad(220)
            readonly property real arc2Start: degToRad(230)
            readonly property real arc2End: degToRad(360)

            function degToRad(deg: int): real {
                return deg * Math.PI / 180;
            }

            anchors.fill: parent

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();

                ctx.lineWidth = res.thickness;
                ctx.lineCap = Appearance.rounding.scale === 0 ? "square" : "round";

                const radius = (Math.min(width, height) - ctx.lineWidth) / 2;
                const cx = centerX;
                const cy = centerY;
                const a1s = arc1Start;
                const a1e = arc1End;
                const a2s = arc2Start;
                const a2e = arc2End;

                // First arc (always drawn)
                ctx.beginPath();
                ctx.arc(cx, cy, radius, a1s, a1e, false);
                ctx.strokeStyle = res.bg1;
                ctx.stroke();

                ctx.beginPath();
                ctx.arc(cx, cy, radius, a1s, (a1e - a1s) * res.value1 + a1s, false);
                ctx.strokeStyle = res.fg1;
                ctx.stroke();

                // Second arc (only drawn if value2 > 0)
                if (res.showSecondArc) {
                    ctx.beginPath();
                    ctx.arc(cx, cy, radius, a2s, a2e, false);
                    ctx.strokeStyle = res.bg2;
                    ctx.stroke();

                    ctx.beginPath();
                    ctx.arc(cx, cy, radius, a2s, (a2e - a2s) * res.value2 + a2s, false);
                    ctx.strokeStyle = res.fg2;
                    ctx.stroke();
                }
            }
        }

        Behavior on value1 {
            Anim {}
        }

        Behavior on value2 {
            Anim {}
        }

        Behavior on fg1 {
            CAnim {}
        }

        Behavior on fg2 {
            CAnim {}
        }

        Behavior on bg1 {
            CAnim {}
        }

        Behavior on bg2 {
            CAnim {}
        }
    }
}
