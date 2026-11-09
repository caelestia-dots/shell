pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import Caelestia.State
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    readonly property real nonAnimHeight: layout.implicitHeight + (PersistentState.keepAwakeEnabled ? activeChip.implicitHeight + activeChip.anchors.topMargin : 0) + Tokens.padding.extraLargeIncreased

    function formatEnabledDuration(enabledAt: real): string {
        if (!enabledAt || enabledAt <= 0 || !isFinite(enabledAt))
            return Tr.tr("Enabled");

        const now = Time.date.getTime();
        const elapsedSecs = Math.max(0, Math.floor((now - enabledAt) / 1000));
        const minutes = Math.floor(elapsedSecs / 60);
        const hours = Math.floor(elapsedSecs / 3600);
        const days = Math.floor(elapsedSecs / 86400);
        const weeks = Math.floor(days / 7);

        // TRANSLATORS: joins duration components, e.g. "3 days, 4 hours" or "2 weeks, 3 days"
        const sep = Tr.trCtx(", ", "duration component separator");

        let duration = "";
        if (weeks >= 1) {
            const remDays = days % 7;
            const parts = [Tr.trN("%n week", "%n weeks", weeks)];
            if (remDays > 0)
                parts.push(Tr.trN("%n day", "%n days", remDays));
            duration = parts.join(sep);
        } else if (days >= 1) {
            const remHours = Math.floor((elapsedSecs % 86400) / 3600);
            const parts = [Tr.trN("%n day", "%n days", days)];
            if (remHours > 0)
                parts.push(Tr.trN("%n hour", "%n hours", remHours));
            duration = parts.join(sep);
        } else if (hours >= 1) {
            duration = Tr.trN("%n hour", "%n hours", hours);
        } else {
            duration = Tr.trN("%n minute", "%n minutes", minutes);
        }

        // TRANSLATORS: %1 = formatted duration, e.g. "35 minutes", "5 hours", "3 days, 4 hours", "2 weeks, 3 days"
        return Tr.tr("Enabled for %1").arg(duration);
    }

    implicitHeight: nonAnimHeight

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer
    clip: true

    RowLayout {
        id: layout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: icon.implicitHeight + Tokens.padding.large

            radius: Tokens.rounding.full
            color: PersistentState.keepAwakeEnabled ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

            MaterialIcon {
                id: icon

                anchors.centerIn: parent
                text: "coffee"
                color: PersistentState.keepAwakeEnabled ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                fontStyle: Tokens.font.icon.large
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: Tr.trCtx("Keep awake", "idle inhibitor")
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: PersistentState.keepAwakeEnabled ? Tr.trCtx("Preventing sleep mode", "idle inhibitor") : Tr.trCtx("Normal power management", "idle inhibitor")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }

        StyledSwitch {
            checked: PersistentState.keepAwakeEnabled
            onToggled: {
                if (checked) {
                    PersistentState.keepAwakeEnabled = true;
                    PersistentState.keepAwakeEnabledAt = new Date().getTime();
                } else {
                    PersistentState.keepAwakeEnabled = false;
                    PersistentState.keepAwakeEnabledAt = -1;
                }
            }
        }
    }

    Loader {
        id: activeChip

        asynchronous: true
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.topMargin: Tokens.spacing.large
        anchors.bottomMargin: PersistentState.keepAwakeEnabled ? Tokens.padding.large : -implicitHeight
        anchors.leftMargin: Tokens.padding.large

        opacity: PersistentState.keepAwakeEnabled ? 1 : 0
        scale: PersistentState.keepAwakeEnabled ? 1 : 0.5

        Component.onCompleted: active = Qt.binding(() => opacity > 0)

        sourceComponent: StyledRect {
            implicitWidth: activeText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: activeText.implicitHeight + Tokens.padding.small

            radius: Tokens.rounding.full
            color: Colours.palette.m3primary

            StyledText {
                id: activeText

                anchors.centerIn: parent
                text: root.formatEnabledDuration(PersistentState.keepAwakeEnabledAt)
                color: Colours.palette.m3onPrimary
                font: Tokens.font.body.builders.small.size(Math.round(Tokens.font.body.small.pointSize * 0.9)).build()
            }
        }

        Behavior on anchors.bottomMargin {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.StandardSmall
            }
        }

        Behavior on scale {
            Anim {}
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
