pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates
import Caelestia
import Caelestia.Components
import Caelestia.Config
import Caelestia.Internal
import qs.components
import qs.services

ProgressBar {
    id: root

    enum IndeterminateAnimState {
        Running,
        Completing,
        Stopped
    }

    property color fgColour: Colours.palette.m3primary
    property color bgColour: Colours.palette.m3secondaryContainer

    property bool wavy
    property bool wavePaused
    property int waveFrequency: 6
    property real waveAmplitude: 0.5
    property int waveDuration: 1000

    property int indeterminateAnimState: StyledProgressBar.Stopped

    function toBounds(startFrac: real, endFrac: real, gapSize: real): point {
        startFrac = CUtils.clamp(startFrac, 0, 1);
        endFrac = CUtils.clamp(endFrac, 0, 1);

        // Ramp down gap size
        const GAP_RAMP_DOWN_THRESHOLD = 0.01;
        gapSize += height / 2;
        const startGapSize = (gapSize * CUtils.clamp(startFrac, 0, GAP_RAMP_DOWN_THRESHOLD) / GAP_RAMP_DOWN_THRESHOLD);
        const endGapSize = (gapSize * (1 - CUtils.clamp(endFrac, 1 - GAP_RAMP_DOWN_THRESHOLD, 1)) / GAP_RAMP_DOWN_THRESHOLD);
        const start = width * startFrac + startGapSize;
        const end = width * endFrac - endGapSize;

        return start >= end ? Qt.point(0, 0) : Qt.point(start, end);
    }

    function updateIAnimState(): void {
        if (indeterminate) {
            manager.completeEndProgress = 0;
            indeterminateAnimState = StyledProgressBar.Running;
        } else if (indeterminateAnimState === StyledProgressBar.Running) {
            indeterminateAnimState = StyledProgressBar.Completing;
        }
    }

    onIndeterminateChanged: updateIAnimState()
    Component.onCompleted: updateIAnimState()

    implicitWidth: 200
    implicitHeight: 4

    contentItem: Loader {
        anchors.fill: parent
        asynchronous: true
        sourceComponent: root.indeterminate || root.indeterminateAnimState !== StyledProgressBar.Stopped ? indeterminateComp : determinateComp
    }

    LinearIndicatorManager {
        id: manager

        gap: root.Tokens.spacing.extraSmall

        Anim on progress {
            running: root.indeterminateAnimState !== StyledProgressBar.Stopped
            from: 0
            to: 1
            duration: manager.duration
            easing.type: Easing.Linear
            loops: Animation.Infinite
        }

        Anim on completeEndProgress {
            running: root.indeterminateAnimState === StyledProgressBar.Completing
            to: 1
            duration: manager.completeEndDuration
            onFinished: {
                if (root.indeterminateAnimState === StyledProgressBar.Completing)
                    root.indeterminateAnimState = StyledProgressBar.Stopped;
            }
        }
    }

    Component {
        id: determinateComp

        Item {
            Line {
                id: remaining

                anchors.right: parent.right
                implicitWidth: parent.width - wave.implicitWidth - Tokens.spacing.extraSmall
            }

            Line {
                property real implicitSize

                Component.onCompleted: implicitSize = Qt.binding(() => parent.width - wave.implicitWidth < parent.height ? parent.height : 4)

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: (parent.height - implicitHeight) / 2

                implicitWidth: implicitSize
                implicitHeight: implicitSize

                radius: Tokens.rounding.full
                color: root.fgColour

                Behavior on implicitSize {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }
            }

            Wave {
                id: wave

                anchors.left: parent.left
                Component.onCompleted: implicitWidth = Qt.binding(() => parent.width * root.visualPosition)

                Behavior on implicitWidth {
                    Anim {}
                }
            }
        }
    }

    Component {
        id: indeterminateComp

        Item {
            id: content

            Line {
                bounds: {
                    const i = manager.activeIndicators[0]; // qmllint disable unresolved-type
                    return i ? root.toBounds(0, i.startFraction, i.gapSize / 2) : Qt.point(0, 0);
                }
            }

            Line {
                bounds: {
                    const i = manager.activeIndicators[manager.activeIndicators.length - 1]; // qmllint disable unresolved-type
                    return i ? root.toBounds(i.endFraction, 1, i.gapSize / 2) : Qt.point(0, 0);
                }
            }

            Instantiator {
                model: Math.max(manager.activeIndicators.length, 1) - 1 // qmllint disable unresolved-type

                delegate: Line {
                    required property int index
                    readonly property LinearIndicatorSegment cur: manager.activeIndicators[index] // qmllint disable unresolved-type
                    readonly property LinearIndicatorSegment next: manager.activeIndicators[index + 1 % manager.activeIndicators.length] // qmllint disable unresolved-type

                    bounds: root.toBounds(cur.endFraction, next.startFraction, cur.gapSize / 2)
                }

                onObjectAdded: (_, obj) => content.data.push(obj)
                onObjectRemoved: (_, obj) => {
                    const idx = content.data.indexOf(obj);
                    if (idx !== -1)
                        content.data.splice(idx, 1);
                }
            }

            Instantiator {
                model: manager.activeIndicators // qmllint disable unresolved-type

                delegate: Wave {
                    required property LinearIndicatorSegment modelData
                    readonly property point bounds: root.toBounds(modelData.startFraction, modelData.endFraction, modelData.gapSize / 2)

                    x: bounds.x
                    implicitWidth: bounds.y - bounds.x

                    color: root.fgColour
                }

                onObjectAdded: (_, obj) => content.data.push(obj)
                onObjectRemoved: (_, obj) => {
                    const idx = content.data.indexOf(obj);
                    if (idx !== -1)
                        content.data.splice(idx, 1);
                }
            }
        }
    }

    component Line: StyledRect {
        property point bounds

        x: bounds.x
        implicitWidth: bounds.y - bounds.x

        anchors.verticalCenter: parent.verticalCenter
        implicitHeight: parent.height

        radius: Tokens.rounding.full
        color: root.bgColour
    }

    component Wave: WavyLine {
        id: wave

        anchors.verticalCenter: parent.verticalCenter
        implicitHeight: lineWidth * amplitudeMultiplier * 2 + lineWidth

        lineWidth: parent.height
        amplitudeMultiplier: root.wavy ? root.waveAmplitude : 0
        frequency: root.waveFrequency
        startX: x
        fullLength: parent.width
        color: root.fgColour

        Anim on waveProgress {
            running: true
            paused: wave.amplitudeMultiplier === 0 || root.wavePaused
            from: 0
            to: 1
            duration: root.waveDuration
            easing.type: Easing.Linear
            loops: Animation.Infinite
        }

        Behavior on amplitudeMultiplier {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on color {
            CAnim {}
        }
    }
}
