pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import qs.services
import qs.components
import qs.components.controls
import qs.config

RowLayout {
    id: root

    required property var sourceModel

    spacing: Appearance.spacing.larger

    ColumnLayout {
        IconButton {
            icon: "chevron_left"
            font.bold: true
            onClicked: {
                applicationsCarousel.decrementCurrentIndex();
            }
        }
    }

    ListView {
        id: applicationsCarousel

        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight
        implicitHeight: currentItem ? currentItem.implicitHeight : 200
        clip: true
        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: 0
        preferredHighlightEnd: width
        interactive: true
        boundsBehavior: Flickable.DragOverBounds

        Behavior on implicitHeight {
            Anim {
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }

        property int realCurrentIndex: 0
        property bool isTeleporting: false
        property bool isAnimating: false

        Component.onCompleted: {
            isTeleporting = true;
            Qt.callLater(() => {
                contentX = width;
                isTeleporting = false;
            });
        }

        function incrementCurrentIndex() {
            if (isAnimating || isTeleporting) return;

            const currentViewIndex = indexAt(contentX + width / 2, height / 2);
            const realCount = root.sourceModel.length;

            if (currentViewIndex === count - 1) {
                isTeleporting = true;
                positionViewAtIndex(1, ListView.SnapPosition);
                realCurrentIndex = 0;
                Qt.callLater(() => { isTeleporting = false; });
                return;
            }

            isAnimating = true;
            contentX += width;
        }

        function decrementCurrentIndex() {
            if (isAnimating || isTeleporting) return;

            const currentViewIndex = indexAt(contentX + width / 2, height / 2);
            const realCount = root.sourceModel.length;

            if (currentViewIndex === 0) {
                isTeleporting = true;
                positionViewAtIndex(realCount, ListView.SnapPosition);
                realCurrentIndex = realCount - 1;
                Qt.callLater(() => { isTeleporting = false; });
                return;
            }

            isAnimating = true;
            contentX -= width;
        }

        onMovementStarted: {
            isAnimating = true;
        }

        onMovementEnded: {
            isAnimating = false;

            if (isTeleporting) return;

            const viewIndex = indexAt(contentX + width / 2, height / 2);
            if (viewIndex === -1) return;

            const realCount = root.sourceModel.length;

            if (viewIndex === 0) {
                isTeleporting = true;
                positionViewAtIndex(realCount, ListView.SnapPosition);
                realCurrentIndex = realCount - 1;
                Qt.callLater(() => { isTeleporting = false; });
            } else if (viewIndex === count - 1) {
                isTeleporting = true;
                positionViewAtIndex(1, ListView.SnapPosition);
                realCurrentIndex = 0;
                Qt.callLater(() => { isTeleporting = false; });
            } else {
                realCurrentIndex = viewIndex - 1;
            }
        }

        Behavior on contentX {
            enabled: !applicationsCarousel.isTeleporting
            Anim {
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasized
                onRunningChanged: {
                    if (!running) {
                        applicationsCarousel.isAnimating = false;

                        const viewIndex = applicationsCarousel.indexAt(
                            applicationsCarousel.contentX + applicationsCarousel.width / 2,
                            applicationsCarousel.height / 2
                        );
                        const realCount = root.sourceModel.length;

                        if (viewIndex === 0) {
                            applicationsCarousel.isTeleporting = true;
                            applicationsCarousel.positionViewAtIndex(realCount, ListView.SnapPosition);
                            applicationsCarousel.realCurrentIndex = realCount - 1;
                            Qt.callLater(() => { applicationsCarousel.isTeleporting = false; });
                        } else if (viewIndex === applicationsCarousel.count - 1) {
                            applicationsCarousel.isTeleporting = true;
                            applicationsCarousel.positionViewAtIndex(1, ListView.SnapPosition);
                            applicationsCarousel.realCurrentIndex = 0;
                            Qt.callLater(() => { applicationsCarousel.isTeleporting = false; });
                        }
                    }
                }
            }
        }

        model: {
            if (!root.sourceModel || root.sourceModel.length === 0) return [];
            const extended = [];
            extended.push(root.sourceModel[root.sourceModel.length - 1]);
            for (let i = 0; i < root.sourceModel.length; i++) {
                extended.push(root.sourceModel[i]);
            }
            extended.push(root.sourceModel[0]);
            return extended;
        }

        delegate: Item {
            id: application

            required property var modelData
            required property int index

            width: applicationsCarousel.width
            implicitHeight: applicationRow.implicitHeight + Appearance.padding.large * 2

            RowLayout {
                id: applicationRow

                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.larger

                VectorImage {
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    Layout.alignment: Qt.AlignTop
                    preferredRendererType: VectorImage.CurveRenderer
                    fillMode: VectorImage.PreserveAspectFit
                    source: application.modelData.icon
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: parent.width
                    Layout.alignment: Qt.AlignTop

                    Text {
                        font.bold: true
                        font.pointSize: Appearance.font.size.larger
                        color: Colours.palette.m3onSurface
                        text: application.modelData.cat + " - " + application.modelData.title
                    }

                    Text {
                        Layout.preferredWidth: parent.width
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3onSurface
                        wrapMode: Text.WordWrap
                        text: application.modelData.desc
                    }

                    RowLayout {
                        Layout.topMargin: Appearance.padding.normal

                        spacing: Appearance.spacing.normal
                        visible: application.modelData.links

                        Repeater {
                            model: application.modelData.links

                            TextButton {
                                id: applicationLink

                                required property var modelData

                                text: applicationLink.modelData.title
                                radius: Appearance.rounding.small

                                onClicked: Qt.openUrlExternally(applicationLink.modelData.url)
                            }
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        IconButton {
            icon: "chevron_right"
            font.bold: true
            onClicked: {
                applicationsCarousel.incrementCurrentIndex();
            }
        }
    }
}