pragma ComponentBehavior: Bound

import qs.components
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property Notifs.Notif modelData
    required property Props props
    required property bool expanded

    readonly property real nonAnimHeight: expanded ? summary.implicitHeight + expandedContent.implicitHeight + expandedContent.anchors.topMargin + Appearance.padding.normal * 2 : summary.implicitHeight

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
        }
    }

    transitions: Transition {
        Anim {
            properties: "margins,width"
        }
    }

    StyledText {
        id: summary

        anchors.top: parent.top
        anchors.left: parent.left

        width: parent.width
        text: root.modelData.summary
        color: root.modelData.urgency === "critical" ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        elide: Text.ElideRight
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
            spacing: Math.floor(Appearance.spacing.small / 2)

            StyledText {
                Layout.fillWidth: true
                textFormat: Text.MarkdownText
                text: root.modelData.body.replace(/(.)\n(?!\n)/g, "$1\n\n") || qsTr("No body here! :/")
                color: root.modelData.urgency === "critical" ? Colours.palette.m3secondary : Colours.palette.m3outline
                wrapMode: Text.WordWrap
            }

            StyledFlickable {
                Layout.topMargin: Appearance.spacing.small
                Layout.fillWidth: true
                implicitHeight: contentHeight
                contentWidth: Math.max(width, actionList.implicitWidth)
                contentHeight: actionList.implicitHeight

                RowLayout {
                    id: actionList

                    anchors.fill: parent
                    spacing: Appearance.spacing.small

                    Repeater {
                        model: [
                            {
                                isClose: true
                            },
                            ...root.modelData.actions,
                            {
                                isCopy: true
                            }
                        ]

                        StyledRect {
                            id: action

                            required property var modelData

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            implicitWidth: actionInner.implicitWidth + Appearance.padding.normal * 2
                            implicitHeight: actionInner.implicitHeight + Appearance.padding.small * 2

                            Layout.preferredWidth: implicitWidth + (actionStateLayer.pressed ? Appearance.padding.large : 0)
                            radius: actionStateLayer.pressed ? Appearance.rounding.small / 2 : Appearance.rounding.small
                            color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 4)

                            Timer {
                                id: copyTimer

                                interval: 3000
                                onTriggered: actionInner.item.text = "content_copy"
                            }

                            StateLayer {
                                id: actionStateLayer

                                function onClicked(): void {
                                    if (action.modelData.isClose) {
                                        root.modelData.close();
                                    } else if (action.modelData.isCopy) {
                                        Quickshell.clipboardText = root.modelData.body;
                                        actionInner.item.text = "inventory";
                                        copyTimer.start();
                                    } else if (action.modelData.invoke) {
                                        action.modelData.invoke();
                                    } else if (!root.modelData.resident) {
                                        root.modelData.close();
                                    }
                                }
                            }

                            Loader {
                                id: actionInner

                                anchors.centerIn: parent
                                sourceComponent: action.modelData.isClose || action.modelData.isCopy ? iconBtn : root.modelData.hasActionIcons ? iconComp : textComp
                            }

                            Component {
                                id: iconBtn

                                MaterialIcon {
                                    animate: action.modelData.isCopy ?? false
                                    text: action.modelData.isCopy ? "content_copy" : "close"
                                }
                            }

                            Component {
                                id: iconComp

                                IconImage {
                                    source: Quickshell.iconPath(action.modelData.identifier)
                                }
                            }

                            Component {
                                id: textComp

                                StyledText {
                                    text: action.modelData.text
                                }
                            }

                            Behavior on Layout.preferredWidth {
                                Anim {
                                    duration: Appearance.anim.durations.expressiveFastSpatial
                                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                                }
                            }

                            Behavior on radius {
                                Anim {
                                    duration: Appearance.anim.durations.expressiveFastSpatial
                                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                                }
                            }
                        }
                    }
                }
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
