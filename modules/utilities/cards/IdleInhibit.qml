import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    property bool manualOpen: false

    // Live countdown state, driven by IdleInhibitor.until (persisted, so
    // this correctly resumes mid-countdown across a shell reload).
    readonly property bool countingDown: IdleInhibitor.enabled && IdleInhibitor.until.getTime() > 0
    readonly property real totalMs: Math.max(1, IdleInhibitor.until.getTime() - IdleInhibitor.enabledSince.getTime())
    readonly property real remainingMs: countingDown ? Math.max(0, IdleInhibitor.until.getTime() - liveNow) : 0
    readonly property real ringFraction: remainingMs / totalMs
    readonly property int remainingMinutes: Math.max(0, Math.ceil(remainingMs / 60000))
    // The duration originally picked on the dial, recovered from
    // until/enabledSince rather than needing its own persisted state --
    // this is what the ring's fill fraction was at the moment Start was
    // pressed, so the ring depletes back down to it exactly. Note:
    // dialMinMinutes/dialMaxMinutes must match KeepAwakeDial's own
    // minMinutes/maxMinutes defaults -- can't reference them directly, an
    // id inside a Loader's sourceComponent isn't visible out here.
    readonly property real dialMinMinutes: 15
    readonly property real dialMaxMinutes: 240
    readonly property real originalMinutes: totalMs / 60000
    readonly property real startValue: Math.max(0, Math.min(1, (originalMinutes - dialMinMinutes) / (dialMaxMinutes - dialMinMinutes)))
    readonly property real ringValue: startValue * ringFraction

    readonly property bool showDial: manualOpen || countingDown

    property real liveNow: Date.now()

    readonly property real chipHeight: activeChip.item ? activeChip.item.implicitHeight + activeChip.anchors.topMargin : 0

    readonly property real dialHeight: dial.item ? dial.item.implicitHeight + Tokens.padding.large * 2 : 0

    readonly property bool showChip: IdleInhibitor.enabled && !countingDown

    readonly property real nonAnimHeight: layout.implicitHeight + (showChip ? chipHeight : 0) + (showDial ? dialHeight : 0) + Tokens.padding.extraLargeIncreased

    implicitHeight: nonAnimHeight

    radius: Tokens.rounding.large

    color: Colours.tPalette.m3surfaceContainer

    clip: true

    Timer {
        interval: 1000
        repeat: true
        running: root.countingDown
        triggeredOnStart: true
        onTriggered: root.liveNow = Date.now()
    }

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
            color: IdleInhibitor.enabled ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

            MaterialIcon {
                id: icon

                anchors.centerIn: parent
                text: "coffee"
                color: IdleInhibitor.enabled ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                fontStyle: Tokens.font.icon.large
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Keep Awake")
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: IdleInhibitor.enabled ? (root.countingDown ? qsTr("Preventing sleep until %1").arg(Qt.formatTime(IdleInhibitor.until, GlobalConfig.services.useTwelveHourClock ? "hh:mm a" : "hh:mm")) : qsTr("Preventing sleep mode")) : qsTr("Normal power management")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }

        IconButton {
            icon: "schedule"
            isToggle: true
            checked: root.manualOpen
            disabled: root.countingDown
            onClicked: root.manualOpen = !root.manualOpen
        }

        StyledSwitch {
            checked: IdleInhibitor.enabled
            onToggled: {
                IdleInhibitor.enabled = checked;
                if (checked)
                    root.manualOpen = false;
            }
        }
    }

    Loader {
        id: dial

        asynchronous: true
        anchors.top: layout.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: root.showDial ? Tokens.padding.large : -implicitHeight
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.large

        opacity: root.showDial ? 1 : 0
        scale: root.showDial ? 1 : 0.9

        Component.onCompleted: active = Qt.binding(() => opacity > 0)

        sourceComponent: ColumnLayout {
            spacing: Tokens.spacing.medium

            KeepAwakeDial {
                id: keepAwakeDial

                Layout.alignment: Qt.AlignHCenter

                readOnly: root.countingDown
                overrideValue: root.ringValue
                overrideMinutes: root.remainingMinutes
                hintText: qsTr("until %1").arg(Qt.formatTime(IdleInhibitor.until, GlobalConfig.services.useTwelveHourClock ? "hh:mm a" : "hh:mm"))
            }

            IconTextButton {
                Layout.alignment: Qt.AlignHCenter
                visible: !root.countingDown
                icon: "coffee"
                text: qsTr("Start")
                type: IconTextButton.Filled

                onClicked: {
                    IdleInhibitor.enableFor(keepAwakeDial.minutes);
                    root.manualOpen = false;
                }
            }
        }

        Behavior on anchors.topMargin {
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

    Loader {
        id: activeChip

        asynchronous: true
        anchors.top: dial.bottom
        anchors.left: parent.left
        anchors.topMargin: root.showChip ? Tokens.spacing.large : -implicitHeight
        anchors.bottomMargin: root.showChip ? Tokens.padding.large : 0
        anchors.leftMargin: Tokens.padding.large

        opacity: root.showChip ? 1 : 0
        scale: root.showChip ? 1 : 0.5

        Component.onCompleted: active = Qt.binding(() => opacity > 0)

        sourceComponent: StyledRect {
            implicitWidth: activeText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: activeText.implicitHeight + Tokens.padding.small

            radius: Tokens.rounding.full
            color: Colours.palette.m3primary

            StyledText {
                id: activeText

                anchors.centerIn: parent
                text: qsTr("Active since %1").arg(Qt.formatTime(IdleInhibitor.enabledSince, GlobalConfig.services.useTwelveHourClock ? "hh:mm a" : "hh:mm"))
                color: Colours.palette.m3onPrimary
                font: Tokens.font.body.builders.small.size(Math.round(Tokens.font.body.small.pointSize * 0.9)).build()
            }
        }

        Behavior on anchors.topMargin {
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
