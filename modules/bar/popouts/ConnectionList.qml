import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services

Item {
    id: root

    property alias model: list.model
    property alias delegate: list.delegate
    readonly property alias list: list

    property bool showList: true
    property string placeholderIcon
    property string placeholderText
    property real maxRows: 5.5

    readonly property bool hasItems: showList && list.count > 0
    readonly property real rowHeight: sizer.implicitHeight
    readonly property real listHeight: list.count * (rowHeight + list.spacing) - list.spacing
    property bool ready

    Layout.fillWidth: true
    implicitHeight: hasItems ? Math.min(listHeight, (rowHeight + list.spacing) * maxRows) : placeholder.implicitHeight + Tokens.padding.extraLarge * 2
    clip: true

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer
        opacity: root.hasItems ? 0 : 1

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    StyledListView {
        id: list

        anchors.fill: parent
        spacing: Tokens.spacing.extraSmall / 2
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        opacity: root.hasItems ? 1 : 0
        visible: opacity > 0

        // Rows slide in one after another when the popout opens
        populate: Transition {
            id: populateTrans

            SequentialAnimation {
                PropertyAction {
                    property: "opacity"
                    value: 0
                }
                PauseAnimation {
                    duration: populateTrans.ViewTransition.index * Tokens.anim.durations.small / 5
                }
                ParallelAnimation {
                    Anim {
                        property: "opacity"
                        to: 1
                        type: Anim.DefaultEffects
                    }
                    Anim {
                        property: "x"
                        from: -Tokens.padding.large
                        to: 0
                    }
                }
            }
        }

        add: Transition {
            Anim {
                property: "opacity"
                from: 0
                to: 1
                type: Anim.DefaultEffects
            }
            Anim {
                property: "scale"
                from: 0.9
                to: 1
            }
        }

        remove: Transition {
            Anim {
                property: "opacity"
                to: 0
                type: Anim.DefaultEffects
            }
            Anim {
                property: "scale"
                to: 0.9
            }
        }

        displaced: Transition {
            Anim {
                property: "y"
            }
            Anim {
                properties: "opacity,scale"
                to: 1
                type: Anim.DefaultEffects
            }
        }

        move: Transition {
            Anim {
                property: "y"
            }
            Anim {
                properties: "opacity,scale"
                to: 1
                type: Anim.DefaultEffects
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    ColumnLayout {
        id: placeholder

        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall
        opacity: root.hasItems ? 0 : 1
        scale: root.hasItems ? 0.8 : 1
        visible: opacity > 0

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            animate: true
            text: root.placeholderIcon
            color: Colours.palette.m3outline
            fontStyle: Tokens.font.icon.large
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            animate: true
            text: root.placeholderText
            color: Colours.palette.m3outline
            font: Tokens.font.body.medium
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on scale {
            Anim {}
        }
    }

    // Used to size the list before the delegates are created, not shown
    ConnectionRow {
        id: sizer

        visible: false
        title: " "
        subtitle: " "
    }

    // Only animate size changes after the initial layout, otherwise the popout grows when opening
    Timer {
        running: true
        interval: Tokens.anim.durations.small
        onTriggered: root.ready = true
    }

    Behavior on implicitHeight {
        enabled: root.ready

        Anim {}
    }
}
