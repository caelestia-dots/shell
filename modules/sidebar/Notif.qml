pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property Notifs.Notif modelData
    required property Props props
    required property bool expanded
    required property var visibilities

    readonly property StyledText body: expandedContent.item?.body ?? null
    readonly property real nonAnimHeight: expanded ? summary.implicitHeight + expandedContent.implicitHeight + expandedContent.anchors.topMargin + Appearance.padding.normal * 2 : summaryHeightMetrics.height

    implicitHeight: nonAnimHeight

    radius: Appearance.rounding.small
    color: {
        const c = root.modelData.urgency === "critical" ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2);
        return expanded ? c : Qt.alpha(c, 0);
    }

    states: State {
        name: "expanded"
        when: root.expanded

        PropertyChanges {
            summary.anchors.margins: Appearance.padding.normal
            dummySummary.anchors.margins: Appearance.padding.normal
            compactBody.anchors.margins: Appearance.padding.normal
            timeStr.anchors.margins: Appearance.padding.normal
            expandedContent.anchors.margins: Appearance.padding.normal
            summary.width: root.width - Appearance.padding.normal * 2 - timeStr.implicitWidth - Appearance.spacing.small
            summary.maximumLineCount: Number.MAX_SAFE_INTEGER
        }
    }

    transitions: Transition {
        Anim {
            properties: "margins,width,maximumLineCount"
        }
    }

    TextMetrics {
        id: summaryHeightMetrics

        font: summary.font
        text: " " // Use this height to prevent weird characters from changing the line height
    }

    StyledText {
        id: summary

        anchors.top: parent.top
        anchors.left: parent.left

        width: parent.width
        text: root.modelData.summary
        color: root.modelData.urgency === "critical" ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        elide: Text.ElideRight
        wrapMode: Text.WordWrap
        maximumLineCount: 1
    }

    StyledText {
        id: dummySummary

        anchors.top: parent.top
        anchors.left: parent.left

        visible: false
        text: root.modelData.summary
    }

    WrappedLoader {
        id: compactBody

        shouldBeActive: !root.expanded
        anchors.top: parent.top
        anchors.left: dummySummary.right
        anchors.right: parent.right
        anchors.leftMargin: Appearance.spacing.small

        sourceComponent: StyledText {
            text: root.modelData.body.replace(/\n/g, " ")
            color: root.modelData.urgency === "critical" ? Colours.palette.m3secondary : Colours.palette.m3outline
            elide: Text.ElideRight
        }
    }

    WrappedLoader {
        id: timeStr

        shouldBeActive: root.expanded
        anchors.top: parent.top
        anchors.right: parent.right

        sourceComponent: StyledText {
            animate: true
            text: root.modelData.timeStr
            color: Colours.palette.m3outline
            font.pointSize: Appearance.font.size.small
        }
    }

    WrappedLoader {
        id: expandedContent

        shouldBeActive: root.expanded
        anchors.top: summary.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Appearance.spacing.small / 2

        sourceComponent: ColumnLayout {
            readonly property alias body: body

            spacing: Appearance.spacing.smaller

            StyledText {
                id: body

                Layout.fillWidth: true
                textFormat: Text.MarkdownText
                text: root.modelData.body.replace(/(.)\n(?!\n)/g, "$1\n\n") || qsTr("No body here! :/")
                color: root.modelData.urgency === "critical" ? Colours.palette.m3secondary : Colours.palette.m3outline
                wrapMode: Text.WordWrap

                onLinkActivated: link => {
                    Quickshell.execDetached(["app2unit", "-O", "--", link]);
                    root.visibilities.sidebar = false;
                }
            }

            NotifActionList {
                notif: root.modelData
            }
        }
    }

    Behavior on implicitHeight {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    component WrappedLoader: Loader {
        required property bool shouldBeActive

        opacity: shouldBeActive ? 1 : 0
        active: opacity > 0

        Behavior on opacity {
            Anim {}
        }
    }
}
