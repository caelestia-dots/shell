pragma ComponentBehavior: Bound

import "cards"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property var props
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property matrix4x4 deformMatrix
    required property var wrapper

    clip: true

    readonly property int enabledCards:
        (idleInhibit.active ? 1 : 0)
        + (record.active ? 1 : 0)
        + (toggles.active ? 1 : 0)
        + (phoneShare.active ? 1 : 0)

    //
    // Utilities always keeps its normal height.
    //
    readonly property real nonAnimHeight:
        ((idleInhibit.item as IdleInhibit)?.nonAnimHeight ?? 0)
        + ((record.item as Record)?.nonAnimHeight ?? 0)
        + ((toggles.item as Toggles)?.implicitHeight ?? 0)
        + ((phoneShare.item as PhoneShare)?.nonAnimHeight ?? 0)
        + mainLayout.spacing
            * Math.max(0, enabledCards - 1)

    implicitWidth:
        mainLayout.implicitWidth

    implicitHeight:
        nonAnimHeight

    //
    // =========================
    // Main Utilities page
    // =========================
    //
    Item {
        id: mainPage

        anchors.top: parent.top

        width: root.width
        height: root.height

        x:
            root.wrapper.browserOpen
                ? -root.width
                : 0

        opacity:
            root.wrapper.browserOpen
                ? 0
                : 1

        ColumnLayout {
            id: mainLayout

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            spacing:
                Tokens.spacing.medium

            Loader {
                id: idleInhibit

                Layout.fillWidth: true

                active:
                    Config.utilities.cards.keepAwake

                visible:
                    active

                sourceComponent: IdleInhibit {
                    objectName:
                        "utilitiesKeepAwake"
                }
            }

            Loader {
                id: record

                Layout.fillWidth: true

                active:
                    Config.utilities.cards.recorder

                visible:
                    active

                z: 1

                sourceComponent: Record {
                    objectName:
                        "utilitiesScreenRecorder"

                    props:
                        root.props

                    screenState:
                        root.screenState
                }
            }

            Loader {
                id: phoneShare

                Layout.fillWidth: true

                active:
                    Config.utilities.cards.phoneShare

                visible:
                    active

                sourceComponent: PhoneShare {
                    objectName:
                        "utilitiesPhoneShare"

                    screenState:
                        root.screenState

                    //
                    // Utilities Wrapper also controls
                    // the internal browser page.
                    //
                    phoneBrowser:
                        root.wrapper
                }
            }

            Loader {
                id: toggles

                Layout.fillWidth: true

                active:
                    Config.utilities.cards.quickToggles

                visible:
                    active

                sourceComponent: Toggles {
                    objectName:
                        "utilitiesQuickToggles"

                    screenState:
                        root.screenState

                    popouts:
                        root.popouts
                }
            }
        }

        Behavior on x {
            Anim {}
        }

        Behavior on opacity {
            Anim {}
        }
    }

    //
    // =========================
    // Phone Browser page
    // =========================
    //
    PhoneBrowser {
        id: phoneBrowser

        anchors.top:
            parent.top

        width:
            root.width

        height:
            root.height

        x:
            root.wrapper.browserOpen
                ? 0
                : root.width

        opacity:
            root.wrapper.browserOpen
                ? 1
                : 0

        wrapper:
            root.wrapper

        Behavior on x {
            Anim {}
        }

        Behavior on opacity {
            Anim {}
        }
    }

    RecordingDeleteModal {
        props:
            root.props

        deformMatrix:
            root.deformMatrix
    }
}
