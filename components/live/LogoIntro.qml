pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import QtQuick.Effects

Item {
    id: root

    implicitWidth: logo.implicitWidth
    implicitHeight: logo.implicitHeight

    property real blurAmount: 1.0
    property bool skipIntroAnimation: false
    
    signal animationCompleted()

    Logo {
        id: logo
        anchors.centerIn: parent
        lightTheme: Colours.currentLight

        transformOrigin: Item.Center
        scale: skipIntroAnimation ? 1.0 : 0.0
        opacity: skipIntroAnimation ? 1.0 : 0.0
        rotation: 0.0

        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blurAmount
            blurMax: 60
        }
    }

    Component.onCompleted: {
        if (skipIntroAnimation) {
            logo.star1.opacity = 1.0
            logo.star1.scale = 1.0
            logo.star2.opacity = 1.0
            logo.star2.scale = 1.0
            logo.star3.opacity = 1.0
            logo.star3.scale = 1.0
            root.blurAmount = 0.0
        }
    }

    SequentialAnimation {
        running: !root.skipIntroAnimation

        PauseAnimation { duration: 300 }

        ParallelAnimation {
            SequentialAnimation {
                NumberAnimation {
                    target: logo; property: "rotation"
                    from: 0; to: 750
                    duration: 1000; easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: logo; property: "rotation"
                    from: 750; to: 710
                    duration: 300; easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: logo; property: "rotation"
                    from: 710; to: 725
                    duration: 350; easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: logo; property: "rotation"
                    from: 725; to: 720
                    duration: 250; easing.type: Easing.OutQuad
                }
                ScriptAction { script: logo.rotation = 0 }
            }

            SequentialAnimation {
                NumberAnimation {
                    target: logo; property: "scale"
                    from: 0.0; to: 1.08
                    duration: 1000; easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: logo; property: "scale"
                    from: 1.08; to: 0.96
                    duration: 200; easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: logo; property: "scale"
                    from: 0.96; to: 1.0
                    duration: 250; easing.type: Easing.OutBack
                    easing.overshoot: 1.05
                }
            }

            NumberAnimation {
                target: logo; property: "opacity"
                from: 0.0; to: 1.0
                duration: 600; easing.type: Easing.InOutQuad
            }

            NumberAnimation {
                target: root; property: "blurAmount"
                from: 1.0; to: 0.0
                duration: 900; easing.type: Easing.OutCubic
            }

            SequentialAnimation {
                PauseAnimation { duration: 1100 }
                ParallelAnimation {
                    NumberAnimation {
                        target: logo.star1; property: "opacity"
                        from: 0.0; to: 1.0
                        duration: 700; easing.type: Easing.InOutQuad
                    }
                    SequentialAnimation {
                        NumberAnimation {
                            target: logo.star1; property: "scale"
                            from: 0.0; to: 1.08
                            duration: 500; easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: logo.star1; property: "scale"
                            from: 1.08; to: 1.0
                            duration: 400; easing.type: Easing.InOutQuad
                        }
                    }
                }
            }

            SequentialAnimation {
                PauseAnimation { duration: 1250 }
                ParallelAnimation {
                    NumberAnimation {
                        target: logo.star2; property: "opacity"
                        from: 0.0; to: 1.0
                        duration: 700; easing.type: Easing.InOutQuad
                    }
                    SequentialAnimation {
                        NumberAnimation {
                            target: logo.star2; property: "scale"
                            from: 0.0; to: 1.08
                            duration: 500; easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: logo.star2; property: "scale"
                            from: 1.08; to: 1.0
                            duration: 400; easing.type: Easing.InOutQuad
                        }
                    }
                }
            }

            SequentialAnimation {
                PauseAnimation { duration: 1400 }
                ParallelAnimation {
                    NumberAnimation {
                        target: logo.star3; property: "opacity"
                        from: 0.0; to: 1.0
                        duration: 700; easing.type: Easing.InOutQuad
                    }
                    SequentialAnimation {
                        NumberAnimation {
                            target: logo.star3; property: "scale"
                            from: 0.0; to: 1.08
                            duration: 500; easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: logo.star3; property: "scale"
                            from: 1.08; to: 1.0
                            duration: 400; easing.type: Easing.InOutQuad
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
                    target: logo.star1; property: "y"
                    from: logo.star1.y; to: logo.star1.y - 5
                    duration: 2500; easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: logo.star1; property: "y"
                    from: logo.star1.y - 5; to: logo.star1.y
                    duration: 2500; easing.type: Easing.InOutQuad
                }
            }
            SequentialAnimation {
                loops: Animation.Infinite
                NumberAnimation {
                    target: logo.star2; property: "y"
                    from: logo.star2.y; to: logo.star2.y + 5
                    duration: 3000; easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: logo.star2; property: "y"
                    from: logo.star2.y + 5; to: logo.star2.y
                    duration: 3000; easing.type: Easing.InOutQuad
                }
            }
            SequentialAnimation {
                loops: Animation.Infinite
                NumberAnimation {
                    target: logo.star3; property: "y"
                    from: logo.star3.y; to: logo.star3.y - 5
                    duration: 2800; easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: logo.star3; property: "y"
                    from: logo.star3.y - 5; to: logo.star3.y
                    duration: 2800; easing.type: Easing.InOutQuad
                }
            }
            SequentialAnimation {
                loops: Animation.Infinite
                NumberAnimation {
                    target: logo.star1; property: "scale"
                    from: 1.0; to: 1.08
                    duration: 2500; easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: logo.star1; property: "scale"
                    from: 1.08; to: 1.0
                    duration: 2500; easing.type: Easing.InOutQuad
                }
            }
            SequentialAnimation {
                loops: Animation.Infinite
                NumberAnimation {
                    target: logo.star2; property: "scale"
                    from: 1.0; to: 1.12
                    duration: 3000; easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: logo.star2; property: "scale"
                    from: 1.12; to: 1.0
                    duration: 3000; easing.type: Easing.InOutQuad
                }
            }
            SequentialAnimation {
                loops: Animation.Infinite
                NumberAnimation {
                    target: logo.star3; property: "scale"
                    from: 1.0; to: 1.08
                    duration: 2800; easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: logo.star3; property: "scale"
                    from: 1.08; to: 1.0
                    duration: 2800; easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
