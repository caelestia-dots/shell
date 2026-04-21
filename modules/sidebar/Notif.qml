pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property NotifData modelData
    required property Props props
    required property bool expanded
    required property DrawerVisibilities visibilities

    readonly property StyledText body: (expandedContent.item as ExpandedBody)?.body ?? null
    readonly property real nonAnimHeight: expanded ? summary.implicitHeight + expandedContent.implicitHeight + expandedContent.anchors.topMargin + Tokens.padding.normal * 2 : summaryHeightMetrics.height

    implicitHeight: nonAnimHeight

    radius: Tokens.rounding.small
    color: {
        const c = root.modelData?.urgency === "critical" ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2);
        return expanded ? c : Qt.alpha(c, 0);
    }

    state: expanded ? "expanded" : ""

    states: State {
        name: "expanded"

        PropertyChanges {
            summary.anchors.margins: root.Tokens.padding.normal
            dummySummary.anchors.margins: root.Tokens.padding.normal
            compactBody.anchors.margins: root.Tokens.padding.normal
            timeStr.anchors.margins: root.Tokens.padding.normal
            expandedContent.anchors.margins: root.Tokens.padding.normal
            summary.width: root.width - root.Tokens.padding.normal * 2 - timeStr.implicitWidth - root.Tokens.spacing.small
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
        text: root.modelData?.summary ?? ""
        color: root.modelData?.urgency === "critical" ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        elide: Text.ElideRight
        wrapMode: Text.WordWrap
        maximumLineCount: 1
    }

    StyledText {
        id: dummySummary

        anchors.top: parent.top
        anchors.left: parent.left

        visible: false
        text: root.modelData?.summary ?? ""
    }

    WrappedLoader {
        id: compactBody

        shouldBeActive: !root.expanded
        anchors.top: parent.top
        anchors.left: dummySummary.right
        anchors.right: parent.right
        anchors.leftMargin: Tokens.spacing.small

        sourceComponent: StyledText {
            text: String(root.modelData?.body ?? "").replace(/\n/g, " ")
            color: root.modelData?.urgency === "critical" ? Colours.palette.m3secondary : Colours.palette.m3outline
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
            text: root.modelData?.timeStr ?? ""
            color: Colours.palette.m3outline
            font.pointSize: Tokens.font.size.small
        }
    }

    WrappedLoader {
        id: expandedContent

        shouldBeActive: root.expanded
        anchors.top: summary.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Tokens.spacing.small / 2

        sourceComponent: ExpandedBody {}
    }

    Behavior on implicitHeight {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    component ExpandedBody: ColumnLayout {
        readonly property alias body: bodyText

        spacing: Tokens.spacing.smaller

        StyledText {
            id: bodyText

            Layout.fillWidth: true
            textFormat: Text.MarkdownText
            text: String(root.modelData?.body ?? "").replace(/(.)\n(?!\n)/g, "$1\n\n") || qsTr("No body here! :/")
            color: root.modelData?.urgency === "critical" ? Colours.palette.m3secondary : Colours.palette.m3outline
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
                        property: "opacity"
                    }
                }
            },
            Transition {
                from: "active"
                to: ""

                SequentialAnimation {
                    Anim {
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
