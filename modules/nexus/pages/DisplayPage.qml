pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<var> modeOptions: [
        {
            id: "extend",
            icon: "vital_signs",
            title: Tr.tr("Extend right"),
            subtitle: Tr.tr("Place external display to the right of built-in display")
        },
        {
            id: "extend-up",
            icon: "keyboard_double_arrow_up",
            title: Tr.tr("Extend above"),
            subtitle: Tr.tr("Place external display above built-in display")
        },
        {
            id: "extend-left",
            icon: "keyboard_double_arrow_left",
            title: Tr.tr("Extend left"),
            subtitle: Tr.tr("Place external display to the left of built-in display")
        },
        {
            id: "mirror",
            icon: "cast",
            title: Tr.tr("Mirror / Duplicate"),
            subtitle: Tr.tr("Mirror primary display onto external display")
        },
        {
            id: "external",
            icon: "desktop_windows",
            title: Tr.tr("External only"),
            subtitle: Tr.tr("Disable built-in display and use external display only")
        },
        {
            id: "internal",
            icon: "laptop_chromebook",
            title: Tr.tr("Built-in only"),
            subtitle: Tr.tr("Disable external display")
        }
    ]

    readonly property list<var> scaleOptions: [
        {
            value: 1,
            label: "100% (1.0x)",
            desc: Tr.tr("Native resolution (1080p / 1440p)")
        },
        {
            value: 1.25,
            label: "125% (1.25x)",
            desc: Tr.tr("Slightly enlarged UI")
        },
        {
            value: 1.5,
            label: "150% (1.5x)",
            desc: Tr.tr("Recommended for 27\"–32\" 4K displays")
        },
        {
            value: 1.75,
            label: "175% (1.75x)",
            desc: Tr.tr("Large UI scaling")
        },
        {
            value: 2,
            label: "200% (2.0x)",
            desc: Tr.tr("HiDPI / 4K scaling")
        }
    ]

    title: Tr.tr("Display")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Connected displays")
        }

        Repeater {
            model: Hypr.monitors.values

            InfoRow {
                required property var modelData
                required property int index

                readonly property var ipc: modelData.lastIpcObject

                first: index === 0
                last: index === Hypr.monitors.values.length - 1
                icon: (modelData.name.startsWith("eDP") || modelData.name.startsWith("LVDS")) ? "laptop_chromebook" : "monitor"
                label: ipc?.description ? `${modelData.name} — ${ipc.description}` : modelData.name
                subtext: ipc?.mirrorOf && ipc.mirrorOf !== "none" ? Tr.tr("Mirroring %1").arg(ipc.mirrorOf) : Tr.tr("Active")
                value: ipc ? `${ipc.width}x${ipc.height}@${Math.round(ipc.refreshRate)}Hz (${modelData.scale}x)` : ""
            }
        }

        SectionHeader {
            text: Tr.tr("Projection mode")
        }

        Repeater {
            model: root.modeOptions

            RowButton {
                required property var modelData
                required property int index

                first: index === 0
                last: index === root.modeOptions.length - 1
                icon: modelData.icon
                text: modelData.title
                subtext: modelData.subtitle
                trailingIcon: Hypr.projectionMode === modelData.id ? "check" : ""
                onClicked: Hypr.applyMonitorLayout(modelData.id, Hypr.externalScale)
            }
        }

        SectionHeader {
            text: Tr.tr("External display scale")
        }

        Repeater {
            model: root.scaleOptions

            RowButton {
                required property var modelData
                required property int index

                first: index === 0
                last: index === root.scaleOptions.length - 1
                icon: "aspect_ratio"
                text: modelData.label
                subtext: modelData.desc
                trailingIcon: Math.abs(Hypr.externalScale - modelData.value) < 0.01 ? "check" : ""
                onClicked: Hypr.applyMonitorLayout(Hypr.projectionMode, modelData.value)
            }
        }
    }
}
