pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import Caelestia
import Caelestia.Models
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// ============================
// OVERFLOW-PROOF EXPANDABLE LIST
// Key ideas:
//  1) Only the VIEWPORT animates height (Layout.preferredHeight) and owns clipping.
//  2) Placeholder is drawn in a dedicated CLIPPED wrapper with height bound to the
//     viewport's CURRENT animatedHeight (not target), so it can never paint past the bottom.
//  3) The placeholder slides from TOP -> CENTER immediately, but its y is CLAMPED each frame
//     against (viewport.animatedHeight - effectiveHeight) so scale/slide can never exceed bounds.
//  4) We account for SCALE when clamping by using transformOrigin: Item.Top and multiplying height * scale.
//  5) We avoid anchor churn; positions are computed numerically (x/y), per Qt docs.
// ============================

ColumnLayout {
    id: root

    required property var props
    required property var visibilities
    required property string title
    required property string path
    required property var nameFilters
    required property string firstIcon
    required property var firstApp
    required property string textPrefix
    required property string expandedProp

    spacing: 0

    // ---------- HEADER ----------
    WrapperMouseArea {
        Layout.fillWidth: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.props[root.expandedProp] = !root.props[root.expandedProp]

        RowLayout {
            spacing: Appearance.spacing.smaller

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                text: "list"
                font.pointSize: Appearance.font.size.large
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                text: qsTr(root.title)
                font.pointSize: Appearance.font.size.normal
            }

            IconButton {
                icon: root.props[root.expandedProp] ? "unfold_less" : "unfold_more"
                type: IconButton.Text
                label.animate: true
                onClicked: root.props[root.expandedProp] = !root.props[root.expandedProp]
            }
        }
    }

    // ---------- VIEWPORT (the only resizable, clipping parent) ----------
    Item {
        id: viewport
        Layout.fillWidth: true
        Layout.rightMargin: -Appearance.spacing.small
        clip: true
        // Enforce a separate layer to guarantee clipping across z-stacking
        layer.enabled: true
        layer.smooth: true

        readonly property real rowHeight: Appearance.font.size.larger + Appearance.padding.small
        readonly property int collapsedRows: 3
        readonly property int expandedRows: 10
        readonly property real targetHeight: rowHeight * (root.props[root.expandedProp] ? expandedRows : collapsedRows)
        property real animatedHeight: targetHeight

        // Live target toggle (drives immediate slide/scale)
        property bool expandedTarget: root.props[root.expandedProp]

        Layout.preferredHeight: animatedHeight
        height: animatedHeight

        Behavior on animatedHeight {
            Anim {
                id: heightAnim
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }

        // ---------- LIST ----------
        StyledListView {
            id: list
            anchors.fill: parent
            clip: true

            model: FileSystemModel {
                path: root.path
                nameFilters: root.nameFilters
                sortReverse: true
            }

            StyledScrollBar.vertical: StyledScrollBar { flickable: list }

            delegate: RowLayout {
                id: item
                required property FileSystemEntry modelData
                property string baseName

                anchors.left: list.contentItem.left
                anchors.right: list.contentItem.right
                anchors.rightMargin: Appearance.spacing.small
                spacing: Appearance.spacing.small / 2

                Component.onCompleted: baseName = modelData.baseName

                StyledText {
                    Layout.fillWidth: true
                    Layout.rightMargin: Appearance.spacing.small / 2
                    text: {
                        const time = item.baseName;
                        const rx = new RegExp(`^${root.textPrefix}_(\\d{4})(\\d{2})(\\d{2})_(\\d{2})-(\\d{2})-(\\d{2})`);
                        const m = time.match(rx);
                        if (!m) return time;
                        const y = +m[1], mo = (+m[2]) - 1, d = +m[3], hh = +m[4], mm = +m[5], ss = +m[6];
                        const date = new Date(y, mo, d, hh, mm, ss);
                        return qsTr(`${root.textPrefix} at %1`).arg(Qt.formatDateTime(date, Qt.locale()));
                    }
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }

                IconButton {
                    icon: root.firstIcon
                    type: IconButton.Text
                    onClicked: {
                        root.visibilities.utilities = false;
                        root.visibilities.sidebar = false;
                        Quickshell.execDetached(["app2unit", "--", ...root.firstApp, item.modelData.path]);
                    }
                }

                IconButton {
                    icon: "folder"
                    type: IconButton.Text
                    onClicked: {
                        root.visibilities.utilities = false;
                        root.visibilities.sidebar = false;
                        Quickshell.execDetached(["app2unit", "--", ...Config.general.apps.explorer, item.modelData.path]);
                    }
                }

                IconButton {
                    icon: "delete_forever"
                    type: IconButton.Text
                    label.color: Colours.palette.m3error
                    stateLayer.color: Colours.palette.m3error
                    enabled: true
                    onClicked: root.props[root.textPrefix.toLowerCase() + "ConfirmDelete"] = item.modelData.path
                }
            }

            add: Transition { Anim { property: "opacity"; from: 0; to: 1 } Anim { property: "scale"; from: 0.5; to: 1 } }
            remove: Transition { Anim { property: "opacity"; to: 0 } Anim { property: "scale"; to: 0.5 } }
            displaced: Transition { Anim { properties: "opacity,scale"; to: 1 } Anim { property: "y" } }
        }

        // ---------- PSEUDO CONTAINER (TARGET CENTER REFERENCE) ----------
        Item {
            id: pseudoContainer
            width: parent.width
            height: viewport.targetHeight // center reference independent of current height
        }

        // ---------- PLACEHOLDER (NO DATA) ----------
        // Fully isolated wrapper clipped to current viewport height.
        Item {
            id: phWrap
            width: parent.width
            height: viewport.animatedHeight // HARD bound to current animated height
            clip: true
            anchors.top: parent.top
            z: 10
            visible: list.count === 0
            // separate layer to ensure clipping is preserved with z ordering
            layer.enabled: true
            layer.smooth: true

            // Which visual style to show
            readonly property bool showBig: viewport.expandedTarget
            readonly property bool showSmall: !viewport.expandedTarget

            // Utility to clamp Y using *effective* height (height * scale)
            function clampedYFor(node, desired) {
                const effH = node.height * node.scale;
                const maxY = Math.max(0, phWrap.height - effH);
                return Math.min(Math.max(0, desired), maxY);
            }

            // ---- BIG variant ----
            Item {
                id: big
                visible: phWrap.showBig
                opacity: visible ? 1 : 0
                // To make scaling grow downward (so bottom clamp is reliable), scale around TOP
                transformOrigin: Item.Top
                scale: visible ? 1 : 0.95
                width: bigCol.implicitWidth
                height: bigCol.implicitHeight
                x: Math.max(0, (phWrap.width - width) / 2)
                
                // Desired center based on CURRENT animated height to prevent overflow during animation
                property real desiredCenter: Math.max(0, (viewport.animatedHeight - height) / 2)

                y: phWrap.clampedYFor(big, viewport.expandedTarget ? big.desiredCenter : 0)

                Behavior on opacity { Anim { duration: heightAnim.duration } }
                Behavior on scale   { Anim { duration: heightAnim.duration } }
                Behavior on y       { Anim { duration: heightAnim.duration * 0.6; easing: heightAnim.easing } }

                Column {
                    id: bigCol
                    spacing: Appearance.spacing.small
                    anchors.horizontalCenter: parent.horizontalCenter

                    MaterialIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.textPrefix === "Screenshot" ? "image" : "videocam"
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.extraLarge
                    }
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("No %1 found").arg(root.title.toLowerCase())
                        color: Colours.palette.m3outline
                    }
                }
            }

            // ---- SMALL variant ----
            Item {
                id: small
                visible: phWrap.showSmall
                opacity: visible ? 1 : 0
                transformOrigin: Item.Top
                scale: visible ? 1 : 0.95
                width: smallRow.implicitWidth
                height: smallRow.implicitHeight
                x: Math.max(0, (phWrap.width - width) / 2)

                property real desiredCenter: Math.max(0, (viewport.animatedHeight - height) / 2)
                y: phWrap.clampedYFor(small, viewport.expandedTarget ? small.desiredCenter : small.desiredCenter)

                Behavior on opacity { Anim { duration: heightAnim.duration } }
                Behavior on scale   { Anim { duration: heightAnim.duration } }
                // Remove Y animation for small variant to eliminate stagger during collapse
                // Behavior on y       { Anim { duration: heightAnim.duration * 0.6; easing: heightAnim.easing } }


                Row {
                    id: smallRow
                    spacing: Appearance.spacing.smaller
                    anchors.horizontalCenter: parent.horizontalCenter
                    MaterialIcon { text: root.textPrefix === "Screenshot" ? "image" : "videocam"; color: Colours.palette.m3outline }
                    StyledText   { text: qsTr("No %1").arg(root.title.toLowerCase()); color: Colours.palette.m3outline }
                }
            }
        }
    }
}
