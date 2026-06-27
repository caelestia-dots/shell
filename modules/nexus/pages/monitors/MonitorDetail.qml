pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property var mon: nState.selectedMonitor
    readonly property var brightnessMon: mon ? Brightness.getMonitor(mon.name) : null

    property var availableResolutions: []
    property var availableRefreshRates: []

    readonly property list<MenuItem> rotationItems: [
        MenuItem {
            text: qsTr("0°")
        },
        MenuItem {
            text: "90°"
        },
        MenuItem {
            text: "180°"
        },
        MenuItem {
            text: "270°"
        }
    ]

    readonly property list<int> rotationValues: [0, 90, 180, 270]

    readonly property list<MenuItem> scaleItems: [
        MenuItem {
            text: "1.0×"
        },
        MenuItem {
            text: "1.25×"
        },
        MenuItem {
            text: "1.5×"
        },
        MenuItem {
            text: "2.0×"
        }
    ]

    readonly property list<real> scaleValues: [1.0, 1.25, 1.5, 2.0]

    function updateModes(): void {
        const res = [];
        const rates = [];
        if (root.mon && root.mon.availableModes) {
            const modes = root.mon.availableModes;
            for (let i = 0; i < modes.length; i++) {
                const mode = modes[i];
                const parts = mode.split("@");
                if (parts.length === 2) {
                    const rStr = parts[0];
                    if (res.indexOf(rStr) === -1) {
                        res.push(rStr);
                    }
                    const rateStr = parts[1].replace("Hz", "");
                    const rate = parseFloat(rateStr);
                    if (!isNaN(rate)) {
                        const roundedRate = Math.round(rate * 100) / 100;
                        if (rates.indexOf(roundedRate) === -1) {
                            rates.push(roundedRate);
                        }
                    }
                }
            }
            // Sort resolutions descending by total pixels
            res.sort((a, b) => {
                const aParts = a.split("x").map(Number);
                const bParts = b.split("x").map(Number);
                return (bParts[0] * bParts[1]) - (aParts[0] * aParts[1]);
            });
            // Sort rates descending
            rates.sort((a, b) => b - a);
        } else if (root.mon) {
            // Fallback if no availableModes
            const currentRes = `${root.mon.width}x${root.mon.height}`;
            res.push(currentRes);
            rates.push(Math.round(root.mon.refreshRate ?? 60));
        }

        root.availableResolutions = res;
        root.availableRefreshRates = rates;
    }

    function getRefreshItem(): var {
        if (!root.mon || !root.availableRefreshRates || root.availableRefreshRates.length === 0)
            return null;
        if (!refreshItemsInstantiator.objects || refreshItemsInstantiator.objects.length === 0)
            return null;
        const rate = root.mon.refreshRate ?? 60;
        let minDiff = 999999;
        let bestIdx = -1;
        for (let i = 0; i < root.availableRefreshRates.length; i++) {
            const diff = Math.abs(root.availableRefreshRates[i] - rate);
            if (diff < minDiff) {
                minDiff = diff;
                bestIdx = i;
            }
        }
        return bestIdx >= 0 ? refreshItemsInstantiator.objects[bestIdx] : null;
    }

    function getResolutionItem(): var {
        if (!root.mon || !root.availableResolutions || root.availableResolutions.length === 0)
            return null;
        if (!resolutionItemsInstantiator.objects || resolutionItemsInstantiator.objects.length === 0)
            return null;
        const currentRes = `${root.mon.width}x${root.mon.height}`;
        const idx = root.availableResolutions.indexOf(currentRes);
        return idx >= 0 ? resolutionItemsInstantiator.objects[idx] : null;
    }

    function getScaleItem(): var {
        const s = root.mon?.scale ?? 1.0;
        const idx = root.scaleValues.findIndex(v => Math.abs(v - s) < 0.01);
        return idx >= 0 ? root.scaleItems[idx] : null;
    }

    title: mon?.name ?? qsTr("Monitor")
    isSubPage: true

    onMonChanged: {
        updateModes();
        if (!mon) {
            nState.closeSubPage();
        }
    }

    Component.onCompleted: updateModes()

    resources: [
        Instantiator {
            id: refreshItemsInstantiator

            model: root.availableRefreshRates
            delegate: MenuItem {
                required property var modelData
                required property int index

                text: modelData + " Hz"
                onClicked: {
                    if (root.mon)
                        Monitors.setRefreshRate(root.mon.name, modelData);
                }
            }
        },
        Instantiator {
            id: resolutionItemsInstantiator

            model: root.availableResolutions
            delegate: MenuItem {
                required property var modelData
                required property int index

                text: modelData
                onClicked: {
                    if (root.mon)
                        Monitors.setResolution(root.mon.name, modelData);
                }
            }
        }
    ]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // ── Hero Section ──────────────────────────────────────
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: hero.implicitHeight + Tokens.padding.extraLarge * 2

            ColumnLayout {
                id: hero

                anchors.centerIn: parent
                width: parent.width - Tokens.padding.largeIncreased * 2
                spacing: Tokens.spacing.small

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "monitor"
                    fontStyle: Tokens.font.icon.extraLarge
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Tokens.spacing.small
                    text: root.mon?.name ?? qsTr("Unknown Monitor")
                    font: Tokens.font.headline.builders.small.build()
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        const w = root.mon?.width ?? 0;
                        const h = root.mon?.height ?? 0;
                        const r = root.mon?.refreshRate ?? 0;
                        if (w && h && r)
                            return qsTr("%1 × %2 @ %3 Hz").arg(w).arg(h).arg(r.toFixed(0));
                        return qsTr("Unavailable");
                    }
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                }
            }
        }

        // ── Settings ───────────────────────────────────────
        SectionHeader {
            text: qsTr("Configuration")
        }

        SliderRow {
            Layout.fillWidth: true
            first: true
            visible: root.brightnessMon !== null && root.brightnessMon !== undefined
            icon: (root.brightnessMon?.brightness ?? 0) > 0.5 ? "brightness_high" : "brightness_low"
            label: qsTr("Brightness")
            valueLabel: Math.round((root.brightnessMon?.brightness ?? 0) * 100) + "%"
            value: root.brightnessMon?.brightness ?? 0
            onMoved: v => {
                if (root.brightnessMon)
                    root.brightnessMon.setBrightness(v);
            }
        }

        SelectRow {
            Layout.fillWidth: true
            first: root.brightnessMon === null || root.brightnessMon === undefined
            label: qsTr("Resolution")
            subtext: qsTr("Display resolution")
            menuItems: resolutionItemsInstantiator.objects || []
            active: root.getResolutionItem()
            fallbackText: root.mon ? qsTr("%1×%2").arg(root.mon.width).arg(root.mon.height) : qsTr("Unknown")
            fallbackIcon: "aspect_ratio"
            onSelected: item => {
                const idx = resolutionItemsInstantiator.objects.indexOf(item);
                if (idx >= 0 && root.mon)
                    Monitors.setResolution(root.mon.name, root.availableResolutions[idx]);
            }
        }

        SelectRow {
            Layout.fillWidth: true
            first: false
            label: qsTr("Refresh rate")
            subtext: qsTr("Maximum refresh rate")
            menuItems: refreshItemsInstantiator.objects || []
            active: root.getRefreshItem()
            fallbackText: root.mon?.refreshRate ? qsTr("%1 Hz").arg((root.mon.refreshRate).toFixed(0)) : qsTr("Unknown")
            fallbackIcon: "speed"
            onSelected: item => {
                const idx = refreshItemsInstantiator.objects.indexOf(item);
                if (idx >= 0 && root.mon)
                    Monitors.setRefreshRate(root.mon.name, root.availableRefreshRates[idx]);
            }
        }

        SelectRow {
            Layout.fillWidth: true
            label: qsTr("Rotation")
            subtext: qsTr("Screen orientation")
            menuItems: root.rotationItems
            active: {
                const t = root.mon?.transform ?? 0;
                return root.rotationItems[t] ?? root.rotationItems[0];
            }
            onSelected: item => {
                const idx = root.rotationItems.indexOf(item);
                if (idx >= 0 && root.mon)
                    Monitors.rotate(root.mon.name, root.rotationValues[idx]);
            }
        }

        SelectRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Scale")
            subtext: qsTr("UI scaling factor")
            menuItems: root.scaleItems
            active: root.getScaleItem()
            fallbackText: qsTr("%1×").arg((root.mon?.scale ?? 1.0).toFixed(2))
            fallbackIcon: "zoom_in"
            onSelected: item => {
                const idx = root.scaleItems.indexOf(item);
                if (idx >= 0 && root.mon)
                    Monitors.setScale(root.mon.name, root.scaleValues[idx]);
            }
        }

        // ── Display information ───────────────────────────────
        SectionHeader {
            text: qsTr("Display information")
        }

        InfoRow {
            Layout.fillWidth: true
            first: true
            label: qsTr("Position")
            value: root.mon != null ? qsTr("x: %1, y: %2").arg(root.mon.x ?? 0).arg(root.mon.y ?? 0) : qsTr("N/A")
        }
        InfoRow {
            Layout.fillWidth: true
            label: qsTr("Monitor ID")
            value: root.mon != null ? String(root.mon.id ?? "—") : "—"
        }
        InfoRow {
            Layout.fillWidth: true
            label: qsTr("Make / Model")
            value: {
                const parts = [root.mon?.make, root.mon?.model].filter(v => v && v.length > 0);
                return parts.length > 0 ? parts.join(" ") : qsTr("Unknown");
            }
        }
        InfoRow {
            Layout.fillWidth: true
            label: qsTr("Serial")
            value: root.mon?.serial || qsTr("Unknown")
        }
        InfoRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Focused")
            value: (root.mon?.focused ?? false) ? qsTr("Yes") : qsTr("No")
        }
    }
}
