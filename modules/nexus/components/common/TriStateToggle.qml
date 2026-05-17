pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property string value: ""

    signal triStateChanged(string newValue)

    implicitHeight: row.implicitHeight
    implicitWidth: row.implicitWidth

    RowLayout {
        id: row

        anchors.fill: parent
        spacing: Math.floor(Tokens.spacing.small / 2)

        Repeater {
            model: [
                {
                    key: "disable",
                    icon: "close",
                    accent: "error"
                },
                {
                    key: "",
                    icon: "remove",
                    accent: "surfaceContainer"
                },
                {
                    key: "enable",
                    icon: "check",
                    accent: "primary"
                }
            ]

            delegate: StyledRect {
                id: seg

                required property var modelData

                readonly property bool selected: root.value === modelData.key
                readonly property color baseColor: {
                    if (!selected)
                        return Colours.layer(Colours.palette.m3surfaceContainerHigh, 1);
                    if (modelData.key === "enable")
                        return Colours.palette.m3primary;
                    if (modelData.key === "disable")
                        return Colours.palette.m3error;
                    return Colours.layer(Colours.palette.m3surfaceContainerHighest, 2);
                }
                readonly property color iconColor: {
                    if (!selected)
                        return Qt.alpha(Colours.palette.m3onSurface, 0.7);
                    if (modelData.key === "enable")
                        return Colours.palette.m3onPrimary;
                    if (modelData.key === "disable")
                        return Colours.palette.m3onError;
                    return Colours.palette.m3onSurface;
                }

                Layout.preferredWidth: Tokens.font.size.large * 2
                Layout.preferredHeight: Tokens.font.size.large * 2
                radius: Tokens.rounding.full
                color: baseColor

                Behavior on color {
                    CAnim {}
                }

                StateLayer {
                    function onClicked(): void {
                        root.triStateChanged(seg.modelData.key);
                    }

                    radius: Tokens.rounding.full
                    color: seg.iconColor
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: seg.modelData.icon
                    color: seg.iconColor
                    font.pointSize: Tokens.font.size.normal
                    fill: seg.selected ? 1 : 0

                    Behavior on color {
                        CAnim {}
                    }
                }
            }
        }
    }
}
