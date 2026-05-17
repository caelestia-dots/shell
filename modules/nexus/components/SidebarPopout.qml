pragma ComponentBehavior: Bound

import QtQuick
import qs.components

Item {
    id: root

    required property bool open
    property string popoutType: ""
    property int popoutWidth: 320
    property int popoutPadding: 16
    property bool touchingTop: false
    property real extraLeftMargin: 0
    property real flyoutDrawerWidth: 0
    property bool flyoutOpen: false

    readonly property real drawerWidth: drawer.width
    readonly property real drawerHeight: drawer.height

    property string _prevType: ""
    property Component _searchComponent: null
    property Component _configComponent: null

    function setComponents(searchComp, configComp) {
        _searchComponent = searchComp;
        _configComponent = configComp;
    }

    implicitWidth: drawer.width
    implicitHeight: drawer.height

    onPopoutTypeChanged: {
        if (popoutType === "") {
            _prevType = "";
            contentFadeOut.start();
        } else if (_prevType === "") {
            _prevType = popoutType;
            contentContainer.opacity = 0;
            contentFadeOut.stop();
            contentFadeIn.restart();
        } else {
            contentFadeOut.start();
        }
    }

    Rectangle {
        id: drawer

        clip: true
        width: root.open ? root.popoutWidth + root.extraLeftMargin : 0
        height: (contentLoader.item?.implicitHeight ?? 0) + root.popoutPadding * 2 // qmllint disable missing-property

        color: "transparent"
        radius: 0

        Behavior on width {
            enabled: root.flyoutOpen === (root.flyoutDrawerWidth >= 100)

            Anim {
                type: Anim.DefaultSpatial
            }
        }

        Behavior on height {
            Anim {
                type: Anim.DefaultSpatial
            }
        }

        Item {
            id: contentContainer

            anchors.fill: parent
            anchors.leftMargin: root.open ? root.popoutPadding + root.extraLeftMargin : 0
            anchors.rightMargin: root.open ? root.popoutPadding : 0
            anchors.topMargin: root.open ? root.popoutPadding : 0
            anchors.bottomMargin: root.open ? root.popoutPadding : 0
            opacity: 1

            NumberAnimation {
                id: contentFadeOut

                target: contentContainer
                property: "opacity"
                from: 1
                to: 0
                duration: 120
                onFinished: {
                    root._prevType = root.popoutType;
                    contentFadeIn.start();
                }
            }

            NumberAnimation {
                id: contentFadeIn

                target: contentContainer
                property: "opacity"
                from: 0
                to: 1
                duration: 250
            }

            Loader {
                id: contentLoader

                anchors.fill: parent
                sourceComponent: root._prevType === "search" ? root._searchComponent : root._prevType === "config" ? root._configComponent : null
            }

            Behavior on anchors.leftMargin {
                enabled: root.flyoutOpen === (root.flyoutDrawerWidth >= 100)

                Anim {
                    type: Anim.DefaultSpatial
                }
            }
        }
    }
}
