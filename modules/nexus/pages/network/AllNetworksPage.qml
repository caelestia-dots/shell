pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("All networks")
    isSubPage: true
    flickable.bottomMargin: Tokens.padding.extraExtraLarge * 2 // Extra scrolling space at the bottom

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Timer {
            running: root.visible && Nmcli.wifiEnabled
            repeat: true
            triggeredOnStart: true
            interval: GlobalConfig.nexus.networkRescanInterval
            onTriggered: Nmcli.rescanWifi()
        }

        ConnectedRect {
            Layout.fillWidth: true
            implicitHeight: headerLayout.implicitHeight + Tokens.padding.medium * 2
            first: true

            RowLayout {
                id: headerLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.large
                anchors.verticalCenterOffset: 1

                spacing: Tokens.spacing.extraSmall / 2

                StyledText {
                    text: qsTr("Filters")
                    font: Tokens.font.title.small
                }

                Item {
                    Layout.fillWidth: true
                }

                FilterButton {
                    id: savedFilter

                    function internalFilter(ap: Nmcli.AccessPoint): bool {
                        return Nmcli.hasSavedProfile(ap.ssid);
                    }

                    text: qsTr("Saved")
                    topLeftRadius: pressed ? pressedRadius : implicitHeight / 2
                    bottomLeftRadius: pressed ? pressedRadius : implicitHeight / 2

                    Behavior on topLeftRadius {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    Behavior on bottomLeftRadius {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                FilterButton {
                    id: secureFilter

                    function internalFilter(ap: Nmcli.AccessPoint): bool {
                        return ap.security !== "none";
                    }

                    text: qsTr("Secured")
                }

                FilterButton {
                    id: highFreqFilter

                    function internalFilter(ap: Nmcli.AccessPoint): bool {
                        return ap.frequency >= 4900 && ap.frequency <= 5900;
                    }

                    text: qsTr("5 GHz")
                }

                FilterButton {
                    id: lowFreqFilter

                    function internalFilter(ap: Nmcli.AccessPoint): bool {
                        return ap.frequency >= 2400 && ap.frequency <= 2500;
                    }

                    text: qsTr("2.4 GHz")
                    topRightRadius: pressed ? pressedRadius : implicitHeight / 2
                    bottomRightRadius: pressed ? pressedRadius : implicitHeight / 2

                    Behavior on topRightRadius {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    Behavior on bottomRightRadius {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
            }
        }

        NetworkList {
            id: networkList

            function networkFilter(ap: Nmcli.AccessPoint): bool {
                return savedFilter.filter(ap) && secureFilter.filter(ap) && highFreqFilter.filter(ap) && lowFreqFilter.filter(ap);
            }

            nState: root.nState
            enableFilter: true
            last: true
        }
    }

    component FilterButton: IconTextButton {
        id: filter

        property int filterState // 0 = default, 1 = on, 2 = negate

        function filter(ap: Nmcli.AccessPoint): bool {
            if (filterState === 0)
                return true;
            if (filterState === 1)
                return internalFilter(ap);
            return !internalFilter(ap);
        }

        function internalFilter(ap: Nmcli.AccessPoint): bool {
            return true;
        }

        onClicked: filterState = (filterState + 1) % 3

        defaultRadius: filterState > 0 ? implicitHeight / 2 : Tokens.rounding.small
        pressedRadius: Tokens.rounding.extraSmall
        spacing: Tokens.spacing.extraSmall

        icon: ["check_indeterminate_small", "check", "close"][filterState]
        inactiveColour: [Colours.palette.m3secondaryContainer, Colours.palette.m3secondary, Colours.palette.m3tertiary][filterState]
        inactiveOnColour: [Colours.palette.m3onSecondaryContainer, Colours.palette.m3onSecondary, Colours.palette.m3onTertiary][filterState]
    }
}
