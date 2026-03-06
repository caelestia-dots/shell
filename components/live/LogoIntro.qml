pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import QtQuick.Effects
import ".."

Item {
    id: root

    implicitWidth: 128
    implicitHeight: 90.38

    property real blurAmount: skipIntroAnimation ? 0.0 : 1.0
    property bool skipIntroAnimation: false

    signal animationCompleted()

    property real star1Opacity: skipIntroAnimation ? 1.0 : 0.0
    property real star2Opacity: skipIntroAnimation ? 1.0 : 0.0
    property real star3Opacity: skipIntroAnimation ? 1.0 : 0.0

    property real star1Scale: skipIntroAnimation ? 1.0 : 0.0
    property real star2Scale: skipIntroAnimation ? 1.0 : 0.0
    property real star3Scale: skipIntroAnimation ? 1.0 : 0.0

    property Item star1: null
    property Item star2: null
    property Item star3: null

    Logo {
        id: logo

        anchors.fill: parent
        lightTheme: Colours.currentLight
        accentColor: Colours.palette.m3primary

        transformOrigin: Item.Center
        scale: root.skipIntroAnimation ? 1.0 : 0.0
        opacity: root.skipIntroAnimation ? 1.0 : 0.0
        rotation: 0.0

        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blurAmount
            blurMax: 60
        }

        Component.onCompleted: {
            const content = logo.children[0]
            root.star1 = content.children[2]
            root.star2 = content.children[3]
            root.star3 = content.children[4]

            root.star1.opacity = Qt.binding(() => root.star1Opacity)
            root.star1.scale = Qt.binding(() => root.star1Scale)

            root.star2.opacity = Qt.binding(() => root.star2Opacity)
            root.star2.scale = Qt.binding(() => root.star2Scale)

            root.star3.opacity = Qt.binding(() => root.star3Opacity)
            root.star3.scale = Qt.binding(() => root.star3Scale)
        }
    }

    SequentialAnimation {
        running: !root.skipIntroAnimation

        PauseAnimation { duration: 300 }

        ParallelAnimation {
            SequentialAnimation {
                NumberAnimation {
                    target: logo
                    property: "rotation"
                    from: 0
                    to: 750
                    duration: 1000
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: logo
                    property: "rotation"
                    from: 750
                    to: 710
                    duration: 300
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: logo
                    property: "rotation"
                    from: 710
                    to: 725
                    duration: 350
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: logo
                    property: "rotation"
                    from: 725
                    to: 720
                    duration: 250
                    easing.type: Easing.OutQuad
                }

                ScriptAction { script: logo.rotation = 0 }
            }

            SequentialAnimation {
                NumberAnimation {
                    target: logo
                    property: "scale"
                    from: 0.0
                    to: 1.08
                    duration: 1000
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: logo
                    property: "scale"
                    from: 1.08
                    to: 0.96
                    duration: 200
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: logo
                    property: "scale"
                    from: 0.96
                    to: 1.0
                    duration: 250
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.05
                }
            }

            NumberAnimation {
                target: logo
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 600
                easing.type: Easing.InOutQuad
            }

            NumberAnimation {
                target: root
                property: "blurAmount"
                from: 1.0
                to: 0.0
                duration: 900
                easing.type: Easing.OutCubic
            }

            SequentialAnimation {
                PauseAnimation { duration: 1100 }

                ParallelAnimation {
                    NumberAnimation {
                        target: root
                        property: "star1Opacity"
                        from: 0.0
                        to: 1.0
                        duration: 700
                        easing.type: Easing.InOutQuad
                    }

                    SequentialAnimation {
                        NumberAnimation {
                            target: root
                            property: "star1Scale"
                            from: 0.0
                            to: 1.08
                            duration: 500
                            easing.type: Easing.OutQuad
                        }

                        NumberAnimation {
                            target: root
                            property: "star1Scale"
                            from: 1.08
                            to: 1.0
                            duration: 400
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }

            SequentialAnimation {
                PauseAnimation { duration: 1250 }

                ParallelAnimation {
                    NumberAnimation {
                        target: root
                        property: "star2Opacity"
                        from: 0.0
                        to: 1.0
                        duration: 700
                        easing.type: Easing.InOutQuad
                    }

                    SequentialAnimation {
                        NumberAnimation {
                            target: root
                            property: "star2Scale"
                            from: 0.0
                            to: 1.08
                            duration: 500
                            easing.type: Easing.OutQuad
                        }

                        NumberAnimation {
                            target: root
                            property: "star2Scale"
                            from: 1.08
                            to: 1.0
                            duration: 400
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }

            SequentialAnimation {
                PauseAnimation { duration: 1400 }

                ParallelAnimation {
                    NumberAnimation {
                        target: root
                        property: "star3Opacity"
                        from: 0.0
                        to: 1.0
                        duration: 700
                        easing.type: Easing.InOutQuad
                    }

                    SequentialAnimation {
                        NumberAnimation {
                            target: root
                            property: "star3Scale"
                            from: 0.0
                            to: 1.08
                            duration: 500
                            easing.type: Easing.OutQuad
                        }

                        NumberAnimation {
                            target: root
                            property: "star3Scale"
                            from: 1.08
                            to: 1.0
                            duration: 400
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }

        onFinished: {
            root.animationCompleted()
        }
    }

    SequentialAnimation {
        running: true
        loops: Animation.Infinite

        PauseAnimation { duration: 2500 }

        ParallelAnimation {
            SequentialAnimation {
                loops: Animation.Infinite

                NumberAnimation {
                    target: root.star1
                    property: "y"
                    from: root.star1.y
                    to: root.star1.y - 5
                    duration: 2500
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root.star1
                    property: "y"
                    from: root.star1.y - 5
                    to: root.star1.y
                    duration: 2500
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation {
                loops: Animation.Infinite

                NumberAnimation {
                    target: root.star2
                    property: "y"
                    from: root.star2.y
                    to: root.star2.y + 5
                    duration: 3000
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root.star2
                    property: "y"
                    from: root.star2.y + 5
                    to: root.star2.y
                    duration: 3000
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation {
                loops: Animation.Infinite

                NumberAnimation {
                    target: root.star3
                    property: "y"
                    from: root.star3.y
                    to: root.star3.y - 5
                    duration: 2800
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root.star3
                    property: "y"
                    from: root.star3.y - 5
                    to: root.star3.y
                    duration: 2800
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation {
                loops: Animation.Infinite

                NumberAnimation {
                    target: root.star1
                    property: "scale"
                    from: 1.0
                    to: 1.08
                    duration: 2500
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root.star1
                    property: "scale"
                    from: 1.08
                    to: 1.0
                    duration: 2500
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation {
                loops: Animation.Infinite

                NumberAnimation {
                    target: root.star2
                    property: "scale"
                    from: 1.0
                    to: 1.12
                    duration: 3000
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root.star2
                    property: "scale"
                    from: 1.12
                    to: 1.0
                    duration: 3000
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation {
                loops: Animation.Infinite

                NumberAnimation {
                    target: root.star3
                    property: "scale"
                    from: 1.0
                    to: 1.08
                    duration: 2800
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root.star3
                    property: "scale"
                    from: 1.08
                    to: 1.0
                    duration: 2800
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
