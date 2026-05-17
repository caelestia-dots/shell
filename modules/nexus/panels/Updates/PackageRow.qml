pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: pkgDelegate

    property int index: 0
    property var pkg: ({})
    property bool expanded: false
    property var panel: null

    Layout.fillWidth: true
    spacing: 0

    Rectangle {
        id: pkgRow

        Layout.fillWidth: true
        implicitHeight: pkgContent.implicitHeight + Tokens.padding.larger * 2
        radius: Tokens.rounding.normal
        color: pkgDelegate.pkg.hasUpdate ? Qt.alpha(Colours.palette.m3primary, 0.12) : Qt.alpha(Colours.palette.m3primary, 0.06)

        RowLayout {
            id: pkgContent

            anchors.fill: parent
            anchors.margins: Tokens.padding.larger
            spacing: Tokens.spacing.normal

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: Tokens.rounding.small
                color: pkgDelegate.pkg.hasUpdate ? Qt.alpha(Colours.palette.m3primary, 0.12) : Qt.alpha(Colours.palette.m3onSurface, 0.06)

                MaterialIcon {
                    id: pkgIcon

                    property real _spinRotation: 0

                    anchors.centerIn: parent
                    text: pkgDelegate.pkg.checking ? "sync" : (pkgDelegate.pkg.hasUpdate ? "download" : "check_circle")
                    font.pointSize: Tokens.font.size.normal
                    color: pkgDelegate.pkg.checking ? Colours.palette.m3primary : (pkgDelegate.pkg.hasUpdate ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3onSurface, 0.5))
                    rotation: pkgDelegate.pkg.checking ? _spinRotation : 0

                    NumberAnimation on _spinRotation {
                        running: pkgDelegate.pkg.checking
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                    }
                }
            }

            // Name + badge
            ColumnLayout {
                spacing: 1

                RowLayout {
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: pkgDelegate.pkg.display
                        font.pointSize: Tokens.font.size.normal
                        font.weight: Font.Medium
                        color: Colours.palette.m3onSurface
                    }

                    // Install method badge
                    Rectangle {
                        visible: pkgDelegate.pkg.badge !== ""
                        implicitWidth: badgeText.implicitWidth + Tokens.padding.small * 4
                        implicitHeight: badgeText.implicitHeight + 4
                        radius: Tokens.rounding.small
                        color: pkgDelegate.pkg.badge === "git" ? Qt.alpha(Colours.palette.m3tertiary, 0.15) : Qt.alpha(Colours.palette.m3secondary, 0.15)

                        StyledText {
                            id: badgeText

                            anchors.centerIn: parent
                            text: pkgDelegate.pkg.badge
                            font.pointSize: Tokens.font.size.small - 2
                            font.weight: Font.Medium
                            color: pkgDelegate.pkg.badge === "git" ? Colours.palette.m3tertiary : Colours.palette.m3secondary
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // Version info
            RowLayout {
                spacing: Tokens.spacing.small
                visible: pkgDelegate.pkg.installed !== ""

                StyledText {
                    text: pkgDelegate.pkg.installed
                    font.pointSize: Tokens.font.size.small
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
                }

                StyledText {
                    text: "→"
                    font.pointSize: Tokens.font.size.small
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.3)
                    visible: pkgDelegate.pkg.hasUpdate
                }

                StyledText {
                    text: pkgDelegate.pkg.available
                    font.pointSize: Tokens.font.size.small
                    font.weight: Font.Medium
                    color: Colours.palette.m3primary
                    visible: pkgDelegate.pkg.hasUpdate
                }
            }

            Rectangle {
                id: previewBtn

                implicitWidth: 32
                implicitHeight: 32
                radius: Tokens.rounding.full
                color: pkgDelegate.expanded ? Qt.alpha(Colours.palette.m3primary, 0.12) : "transparent"

                MaterialIcon {
                    anchors.centerIn: parent
                    text: pkgDelegate.expanded ? "expand_less" : "expand_more"
                    font.pointSize: Tokens.font.size.normal
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
                }

                TapHandler {
                    onTapped: pkgDelegate.panel.showPreview(pkgDelegate.index)
                }

                HoverHandler {
                    id: previewHover

                    onHoveredChanged: {
                        if (!pkgDelegate.expanded) {
                            previewBtn.color = hovered ? Qt.alpha(Colours.palette.m3onSurface, 0.06) : "transparent";
                        }
                    }
                }
            }

            Rectangle {
                id: pkgUpdateBtn

                visible: pkgDelegate.pkg.hasUpdate
                implicitWidth: 32
                implicitHeight: 32
                radius: Tokens.rounding.full
                color: Qt.alpha(Colours.palette.m3onSurface, 0.1)
                opacity: pkgDelegate.panel.installing ? 0.5 : 1.0

                MaterialIcon {
                    anchors.centerIn: parent
                    text: pkgDelegate.panel.installing && pkgDelegate.panel.installTarget === pkgDelegate.pkg.key ? "hourglass_empty" : "download"
                    font.pointSize: Tokens.font.size.small
                    color: Colours.palette.m3primary
                }

                TapHandler {
                    enabled: !pkgDelegate.panel.installing
                    onTapped: pkgDelegate.panel.updatePackage(pkgDelegate.index)
                }

                HoverHandler {
                    id: pkgUpdateHover

                    onHoveredChanged: pkgUpdateBtn.color = hovered ? Qt.alpha(Colours.palette.m3onSurface, 0.15) : Qt.alpha(Colours.palette.m3onSurface, 0.1)
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Tokens.anim.durations.small
                    }
                }
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: Tokens.anim.durations.small
            }
        }
    }

    Rectangle {
        id: previewPanel

        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small
        visible: pkgDelegate.expanded
        implicitHeight: pkgDelegate.expanded ? previewContent.implicitHeight + Tokens.padding.large * 2 : 0
        radius: Tokens.rounding.small
        color: Qt.alpha(Colours.palette.m3primary, 0.06)

        Behavior on implicitHeight {
            NumberAnimation {
                duration: Tokens.anim.durations.small
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            id: previewContent

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.small

            RowLayout {
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: pkgDelegate.pkg.method === "git" ? "commit" : "inventory_2"
                    font.pointSize: Tokens.font.size.small
                    color: Colours.palette.m3primary
                }

                StyledText {
                    text: pkgDelegate.pkg.method === "git" ? "Pending commits" : "Package info"
                    font.pointSize: Tokens.font.size.small
                    font.weight: Font.Medium
                    color: Colours.palette.m3primary
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: pkgDelegate.pkg.preview || "Loading..."
                font.pointSize: Tokens.font.size.small
                font.family: "monospace"
                color: Qt.alpha(Colours.palette.m3onSurface, 0.7)
                wrapMode: Text.Wrap
                maximumLineCount: 20
                elide: Text.ElideRight
            }
        }
    }
}
