import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.hallownest
import qs.services

ColumnLayout {
    id: root

    required property HyprlandToplevel client

    anchors.fill: parent
    spacing: Tokens.spacing.small

    Label {
        Layout.topMargin: Tokens.padding.extraLargeIncreased

        text: root.client?.title ?? Tr.tr("No active client")
        color: Hallownest.soul
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere

        font.family: Hallownest.serif
        font.pointSize: 14
        font.weight: Font.Bold
    }

    Label {
        text: root.client?.lastIpcObject.class ?? Tr.tr("No active client")
        color: Hallownest.lifeblood

        font.family: Hallownest.mono
        font.pointSize: 10
    }

    HkDivider {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.extraLargeIncreased
        Layout.rightMargin: Tokens.padding.extraLargeIncreased
        Layout.topMargin: Tokens.spacing.small
        Layout.bottomMargin: Tokens.spacing.medium
    }

    Detail {
        icon: "location_on"
        text: {
            const addr = root.client?.address;
            if (addr)
                return Tr.trCtx("Address: %1", "window address").arg(`0x${addr}`);
            return Tr.trCtx("Address: unknown", "window address");
        }
        color: Hallownest.soul
    }

    Detail {
        icon: "location_searching"
        // TRANSLATORS: %1/%2 = x and y position in pixels
        text: Tr.tr("Position: %1, %2").arg(root.client?.lastIpcObject.at[0] ?? -1).arg(root.client?.lastIpcObject.at[1] ?? -1)
    }

    Detail {
        icon: "resize"
        // TRANSLATORS: %1/%2 = width and height in pixels; the x is a multiplication sign
        text: Tr.tr("Size: %1 x %2").arg(root.client?.lastIpcObject.size[0] ?? -1).arg(root.client?.lastIpcObject.size[1] ?? -1)
        color: Hallownest.lifeblood
    }

    Detail {
        icon: "workspaces"
        // TRANSLATORS: %1 = workspace name, %2 = workspace id
        text: Tr.tr("Workspace: %1 (%2)").arg(root.client?.workspace.name ?? -1).arg(root.client?.workspace.id ?? -1)
        color: Hallownest.steel
    }

    Detail {
        icon: "desktop_windows"
        text: {
            const mon = root.client?.monitor;
            if (mon)
                // TRANSLATORS: %1 = monitor name, %2 = monitor id, %3/%4 = x/y position in pixels
                return Tr.tr("Monitor: %1 (%2) at %3, %4").arg(mon.name).arg(mon.id).arg(mon.x).arg(mon.y);
            return Tr.tr("Monitor: unknown");
        }
    }

    Detail {
        icon: "page_header"
        text: {
            const title = root.client?.lastIpcObject.initialTitle;
            if (title)
                return Tr.tr("Initial title: %1").arg(title);
            return Tr.tr("Initial title: unknown");
        }
        color: Hallownest.crystal
    }

    Detail {
        icon: "category"
        text: {
            const cls = root.client?.lastIpcObject.initialClass;
            if (cls)
                return Tr.tr("Initial class: %1").arg(cls);
            return Tr.tr("Initial class: unknown");
        }
    }

    Detail {
        icon: "account_tree"
        // TRANSLATORS: %1 = process id
        text: Tr.tr("Process id: %1").arg(String(root.client?.lastIpcObject.pid ?? -1))
        color: Hallownest.soul
    }

    Detail {
        icon: "picture_in_picture_center"
        text: root.client?.lastIpcObject.floating ? Tr.tr("Floating: yes") : Tr.tr("Floating: no")
        color: Hallownest.steel
    }

    Detail {
        icon: "gradient"
        text: root.client?.lastIpcObject.xwayland ? Tr.tr("Xwayland: yes") : Tr.tr("Xwayland: no")
    }

    Detail {
        icon: "keep"
        text: root.client?.lastIpcObject.pinned ? Tr.tr("Pinned: yes") : Tr.tr("Pinned: no")
        color: Hallownest.steel
    }

    Detail {
        icon: "fullscreen"
        text: {
            const fs = root.client?.lastIpcObject.fullscreen;
            if (fs === 0)
                return Tr.tr("Fullscreen state: off");
            if (fs === 1)
                return Tr.tr("Fullscreen state: maximised");
            if (fs !== undefined)
                return Tr.tr("Fullscreen state: on");
            return Tr.tr("Fullscreen state: unknown");
        }
        color: Hallownest.crystal
    }

    Item {
        Layout.fillHeight: true
    }

    component Detail: RowLayout {
        id: detail

        required property string icon
        required property string text
        property alias color: icon.color

        Layout.leftMargin: Tokens.padding.large
        Layout.rightMargin: Tokens.padding.large
        Layout.fillWidth: true

        spacing: Tokens.spacing.medium

        MaterialIcon {
            id: icon

            Layout.alignment: Qt.AlignVCenter
            text: detail.icon
        }

        StyledText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            text: detail.text
            elide: Text.ElideRight
            font: Tokens.font.body.medium
        }
    }

    component Label: StyledText {
        Layout.leftMargin: Tokens.padding.large
        Layout.rightMargin: Tokens.padding.large
        Layout.fillWidth: true
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        animate: true
    }
}
