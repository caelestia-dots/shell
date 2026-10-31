pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Models
import Caelestia.Scheme
import qs.components

StyledRect {
    id: root

    required property NotifData modelData
    required property bool expanded
    required property color expandedColour
    required property color buttonColour
    property bool showAvatar: true
    property bool single: false
    property real headerHeight
    property real headerTitleWidth

    readonly property bool critical: modelData.urgency === NotifData.Critical
    readonly property StyledText body: (expandedContent.item as ExpandedBody)?.body ?? null
    readonly property real padding: single ? 0 : Tokens.padding.medium
    readonly property real headerSummaryOffset: -(headerHeight + summaryHeightMetrics.height) / 2
    readonly property real nonAnimHeight: {
        if (!expanded)
            return summaryHeightMetrics.height;
        const contentHeight = summary.implicitHeight + expandedContent.implicitHeight + expandedContent.anchors.topMargin + padding * 2;
        return single ? contentHeight : Math.max(contentHeight, TokenConfig.sizes.notifs.image + Tokens.padding.extraSmall * 2);
    }

    signal linkActivated

    implicitHeight: nonAnimHeight

    radius: Tokens.rounding.medium
    color: {
        const c = root.critical ? Colours.palette.secondaryContainer : root.expandedColour;
        return expanded && !single ? c : Qt.alpha(c, 0);
    }

    TextMetrics {
        id: summaryHeightMetrics

        font: dummySummary.font
        text: " " // Use this height to prevent weird characters from changing the line height
    }

    TextMetrics {
        id: summaryMetrics

        font: dummySummary.font
        text: root.modelData.summary
        elide: Text.ElideRight
        elideWidth: root.single ? root.headerTitleWidth : root.width
    }

    WrappedLoader {
        id: avatar

        shouldBeActive: root.expanded && root.showAvatar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: Tokens.padding.extraSmall
        anchors.leftMargin: -(TokenConfig.sizes.notifs.image + Tokens.spacing.medium)

        sourceComponent: NotifAvatar {
            image: root.modelData.image
            icon: root.modelData.appIcon
            urgency: root.modelData.urgency
            lowFillColour: root.buttonColour
            summary: root.modelData.summary
            progress: (root.modelData.hints.value ?? 0) / 100
        }
    }

    WrappedLoader {
        id: compactSummary

        shouldBeActive: !root.expanded
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: root.single && !root.expanded ? root.headerSummaryOffset : 0

        sourceComponent: StyledText {
            animate: true
            text: summaryMetrics.elidedText
            color: root.critical ? Colours.palette.onSecondaryContainer : Colours.palette.onSurface
        }

        Behavior on anchors.topMargin {
            Anim {}
        }
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
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.single ? 0 : dummySummary.width + Tokens.spacing.small
        anchors.topMargin: root.single && root.expanded ? summary.implicitHeight + expandedContent.anchors.topMargin : 0

        sourceComponent: StyledText {
            text: root.modelData.body.replace(/\n/g, " ")
            color: root.critical ? Colours.palette.secondary : Colours.palette.outline
            elide: Text.ElideRight
        }

        Behavior on anchors.leftMargin {
            Anim {}
        }

        Behavior on anchors.topMargin {
            Anim {}
        }
    }

    WrappedLoader {
        id: summary

        shouldBeActive: root.expanded
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: root.padding
        anchors.topMargin: root.single && !root.expanded ? root.headerSummaryOffset : root.padding
        width: root.width - root.padding * 2 - timeStr.implicitWidth - Tokens.spacing.small

        sourceComponent: StyledText {
            text: root.modelData.summary
            color: root.critical ? Colours.palette.onSecondaryContainer : Colours.palette.onSurface
            wrapMode: Text.WordWrap
        }

        Behavior on anchors.topMargin {
            Anim {}
        }
    }

    WrappedLoader {
        id: timeStr

        shouldBeActive: root.expanded && !root.single
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: root.padding

        sourceComponent: StyledText {
            animate: true
            text: Tr.trMarked(root.modelData.timeStr)
            color: Colours.palette.outline
            font: Tokens.font.body.small
        }
    }

    WrappedLoader {
        id: expandedContent

        shouldBeActive: root.expanded
        anchors.top: summary.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: root.padding
        anchors.topMargin: Tokens.spacing.extraSmall

        sourceComponent: ExpandedBody {}
    }

    Behavior on implicitHeight {
        Anim {}
    }

    component ExpandedBody: ColumnLayout {
        readonly property alias body: bodyText

        spacing: Tokens.spacing.medium

        StyledText {
            id: bodyText

            Layout.fillWidth: true
            textFormat: Text.MarkdownText
            text: root.modelData.body.replace(/(.)\n(?!\n)/g, "$1\n\n") || Tr.tr("No body here! :/")
            color: root.critical ? Colours.palette.secondary : Colours.palette.outline
            wrapMode: Text.WordWrap

            onLinkActivated: link => {
                Qt.openUrlExternally(link);
                root.linkActivated();
            }
        }

        NotifActions {
            Layout.fillWidth: true
            notif: root.modelData
            buttonColour: root.buttonColour
        }
    }

    component WrappedLoader: Loader {
        id: comp

        required property bool shouldBeActive

        active: false
        opacity: 0

        // Makes the loader load on the same frame shouldBeActive becomes true, which ensures size is set
        states: State {
            name: "active"
            when: comp.shouldBeActive

            PropertyChanges {
                comp.opacity: 1
                comp.active: true
            }
        }

        transitions: [
            Transition {
                from: ""
                to: "active"

                SequentialAnimation {
                    PropertyAction {
                        property: "active"
                    }
                    Anim {
                        type: Anim.DefaultEffects
                        property: "opacity"
                    }
                }
            },
            Transition {
                from: "active"
                to: ""

                SequentialAnimation {
                    Anim {
                        type: Anim.DefaultEffects
                        property: "opacity"
                    }
                    PropertyAction {
                        property: "active"
                    }
                }
            }
        ]
    }
}
