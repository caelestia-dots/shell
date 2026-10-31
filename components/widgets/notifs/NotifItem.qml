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

    readonly property bool critical: modelData.urgency === NotifData.Critical
    readonly property StyledText body: (expandedContent.item as ExpandedBody)?.body ?? null
    readonly property real nonAnimHeight: expanded ? summary.implicitHeight + expandedContent.implicitHeight + expandedContent.anchors.topMargin + Tokens.padding.medium * 2 : summaryHeightMetrics.height

    signal linkActivated

    implicitHeight: nonAnimHeight

    radius: Tokens.rounding.medium
    color: {
        const c = root.critical ? Colours.palette.secondaryContainer : Colours.layer(Colours.palette.surfaceContainerHigh, 2);
        return expanded ? c : Qt.alpha(c, 0);
    }

    state: expanded ? "expanded" : ""

    states: State {
        name: "expanded"

        PropertyChanges {
            summary.anchors.margins: root.Tokens.padding.medium
            dummySummary.anchors.margins: root.Tokens.padding.medium
            compactBody.anchors.margins: root.Tokens.padding.medium
            timeStr.anchors.margins: root.Tokens.padding.medium
            expandedContent.anchors.margins: root.Tokens.padding.medium
            summary.width: root.width - root.Tokens.padding.medium * 2 - timeStr.implicitWidth - root.Tokens.spacing.small
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
        color: root.critical ? Colours.palette.onSecondaryContainer : Colours.palette.onSurface
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
        anchors.leftMargin: Tokens.spacing.small

        sourceComponent: StyledText {
            text: root.modelData.body.replace(/\n/g, " ")
            color: root.critical ? Colours.palette.secondary : Colours.palette.outline
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
