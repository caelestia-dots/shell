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

    readonly property string currentResolution: mon ? Monitors.modeResolution(mon) : ""
    readonly property bool isDisabled: (mon?.disabled ?? false)
    readonly property string mirrorTarget: mon ? Monitors.mirrorTargetName(mon) : ""
    // Everything else describes a display that has its own place on the desktop
    readonly property bool isMirroring: mirrorTarget !== ""
    // Mirroring the only display with a place of its own would leave no desktop
    readonly property bool canMirror: !isDisabled && (isMirroring || Monitors.arrangedMonitors().length > 1)
    readonly property var mirrorCandidates: Monitors.arrangedMonitors().filter(m => m.name !== (root.mon?.name ?? ""))
    // Nothing would be left to turn it back on with
    readonly property bool isOnlyEnabled: !isDisabled && Monitors.enabledMonitors().length <= 1

    property var availableResolutions: []
    property var availableRefreshRates: []

    readonly property MenuItem extendItem: MenuItem {
        icon: "splitscreen_right"
        text: qsTr("Extend desktop")
        activeText: qsTr("Extend")
        onClicked: {
            if (root.mon)
                Monitors.setMirror(root.mon.name, "");
        }
    }

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

    // Resolution and refresh rate are not independent: availableModes pairs
    // them, so the rate list only ever shows what the current resolution can do.
    function updateModes(): void {
        if (!root.mon) {
            root.availableResolutions = [];
            root.availableRefreshRates = [];
            return;
        }

        const res = Monitors.resolutionsFor(root.mon);
        const rates = Monitors.refreshRatesFor(root.mon, root.currentResolution);

        // Rebuilding the instantiator models tears down any open dropdown, so
        // only publish when the contents actually differ.
        if (res.join("|") !== root.availableResolutions.join("|"))
            root.availableResolutions = res;
        if (rates.join("|") !== root.availableRefreshRates.join("|"))
            root.availableRefreshRates = rates;
    }

    function getRefreshItem(): var {
        if (!root.mon || !root.availableRefreshRates || root.availableRefreshRates.length === 0)
            return null;
        if (refreshItemsInstantiator.items.length === 0)
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
        return bestIdx >= 0 ? (refreshItemsInstantiator.items[bestIdx] ?? null) : null;
    }

    function getResolutionItem(): var {
        if (!root.mon || !root.availableResolutions || root.availableResolutions.length === 0)
            return null;
        const idx = root.availableResolutions.indexOf(root.currentResolution);
        return idx >= 0 ? (resolutionItemsInstantiator.items[idx] ?? null) : null;
    }

    function getMirrorItem(): var {
        if (!root.isMirroring)
            return root.extendItem;
        const idx = root.mirrorCandidates.findIndex(m => m.name === root.mirrorTarget);
        return idx >= 0 ? (mirrorItemsInstantiator.items[idx] ?? root.extendItem) : root.extendItem;
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

    onCurrentResolutionChanged: updateModes()

    Component.onCompleted: updateModes()

    // Instantiator keeps no list of what it built, so track it as it goes. A
    // model swap of the same length leaves `count` alone while replacing every
    // object, so counting is not enough to stay in sync.
    resources: [
        Instantiator {
            id: refreshItemsInstantiator

            property var items: []

            model: root.availableRefreshRates
            onObjectAdded: (index, object) => {
                const next = refreshItemsInstantiator.items.slice();
                next.splice(index, 0, object);
                refreshItemsInstantiator.items = next;
            }
            onObjectRemoved: (index, object) => {
                const next = refreshItemsInstantiator.items.slice();
                next.splice(index, 1);
                refreshItemsInstantiator.items = next;
            }

            delegate: MenuItem {
                required property var modelData

                text: Monitors.formatRate(modelData) + " Hz"
                onClicked: {
                    if (root.mon)
                        Monitors.setRefreshRate(root.mon.name, modelData);
                }
            }
        },
        Instantiator {
            id: mirrorItemsInstantiator

            property var items: []

            model: root.mirrorCandidates
            onObjectAdded: (index, object) => {
                const next = mirrorItemsInstantiator.items.slice();
                next.splice(index, 0, object);
                mirrorItemsInstantiator.items = next;
            }
            onObjectRemoved: (index, object) => {
                const next = mirrorItemsInstantiator.items.slice();
                next.splice(index, 1);
                mirrorItemsInstantiator.items = next;
            }

            delegate: MenuItem {
                required property var modelData

                icon: "content_copy"
                text: qsTr("Mirror %1").arg(modelData.name)
                activeText: qsTr("Mirror of %1").arg(modelData.name)
                onClicked: {
                    if (root.mon)
                        Monitors.setMirror(root.mon.name, modelData.name);
                }
            }
        },
        Instantiator {
            id: resolutionItemsInstantiator

            property var items: []

            model: root.availableResolutions
            onObjectAdded: (index, object) => {
                const next = resolutionItemsInstantiator.items.slice();
                next.splice(index, 0, object);
                resolutionItemsInstantiator.items = next;
            }
            onObjectRemoved: (index, object) => {
                const next = resolutionItemsInstantiator.items.slice();
                next.splice(index, 1);
                resolutionItemsInstantiator.items = next;
            }

            delegate: MenuItem {
                required property var modelData

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
                            return qsTr("%1 × %2 @ %3 Hz").arg(w).arg(h).arg(Monitors.formatRate(r));
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

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Enabled")
            font: Tokens.font.body.medium
            horizontalPadding: Tokens.padding.largeIncreased
            // Turning off the last display would leave nothing to turn it back on with
            disabled: root.isOnlyEnabled
            checked: !root.isDisabled
            onToggled: {
                // Toggling breaks the binding, so restore it and let the actual
                // monitor state drive the switch back
                checked = Qt.binding(() => !root.isDisabled);
                if (root.mon)
                    Monitors.setEnabled(root.mon.name, root.isDisabled);
            }
        }

        SelectRow {
            Layout.fillWidth: true
            visible: root.canMirror
            label: qsTr("Mode")
            subtext: qsTr("Give this display its own space, or show a copy of another")
            menuItems: [root.extendItem].concat(mirrorItemsInstantiator.items)
            active: root.getMirrorItem()
            fallbackText: root.isMirroring ? qsTr("Mirror of %1").arg(root.mirrorTarget) : qsTr("Extend")
            fallbackIcon: "splitscreen_right"
        }

        SliderRow {
            Layout.fillWidth: true
            visible: !root.isDisabled && root.brightnessMon !== null && root.brightnessMon !== undefined
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
            visible: !root.isDisabled
            label: qsTr("Resolution")
            subtext: qsTr("Display resolution")
            menuItems: resolutionItemsInstantiator.items
            active: root.getResolutionItem()
            fallbackText: root.mon ? qsTr("%1×%2").arg(root.mon.width).arg(root.mon.height) : qsTr("Unknown")
            fallbackIcon: "aspect_ratio"
        }

        SelectRow {
            Layout.fillWidth: true
            visible: !root.isDisabled
            label: qsTr("Refresh rate")
            subtext: qsTr("Rates available at %1").arg(root.currentResolution)
            menuItems: refreshItemsInstantiator.items
            active: root.getRefreshItem()
            fallbackText: root.mon?.refreshRate ? qsTr("%1 Hz").arg(Monitors.formatRate(root.mon.refreshRate)) : qsTr("Unknown")
            fallbackIcon: "speed"
        }

        SelectRow {
            Layout.fillWidth: true
            visible: !root.isDisabled
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
            visible: !root.isDisabled
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
