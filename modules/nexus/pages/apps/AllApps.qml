pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("All apps")
    isSubPage: true

    // Only creates the rows near the visible part of the page (there can be hundreds of apps)
    LazyListView {
        id: list

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        implicitHeight: contentHeight
        spacing: Tokens.spacing.extraSmall / 2

        cacheBuffer: 400
        useCustomViewport: true
        viewport: {
            tWatcher.transform; // mapToItem is not reactive so use this to trigger updates
            return Qt.rect(0, root.flickable.contentY - mapToItem(root.flickable.contentItem, 0, 0).y, width, root.flickable.height);
        }

        model: ScriptModel {
            values: [...DesktopEntries.applications.values].sort((a, b) => a.name.localeCompare(b.name))
        }

        delegate: Component {
            ConnectedRect {
                id: appItem

                required property DesktopEntry modelData
                required property int index

                first: index === 0
                last: index === list.count - 1
                implicitHeight: appRow.implicitHeight + appRow.anchors.margins * 2

                StateLayer {
                    onClicked: {
                        root.nState.selectedApp = appItem.modelData;
                        root.nState.openSubPage(SubPage.AppInfo);
                    }
                }

                RowLayout {
                    id: appRow

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    IconImage {
                        asynchronous: true
                        implicitSize: Math.round(Tokens.font.icon.large.pointSize * 1.8)
                        source: Quickshell.iconPath(appItem.modelData.icon, "image-missing")
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: appItem.modelData.name
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: text
                            text: (appItem.modelData.comment || appItem.modelData.genericName) ?? ""
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    MaterialIcon {
                        visible: Strings.testRegexList(GlobalConfig.launcher.favouriteApps, appItem.modelData.id)
                        text: "favorite"
                        fill: 1
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.small
                    }

                    MaterialIcon {
                        text: "chevron_right"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                    }
                }
            }
        }

        TransformWatcher {
            id: tWatcher

            a: root.flickable.contentItem
            b: list
        }
    }
}
