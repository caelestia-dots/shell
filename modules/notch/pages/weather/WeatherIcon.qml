pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property string icon
    property font fontStyle: Tokens.font.icon.extraLarge
    property real size: fontStyle.pointSize * 1.45
    property color colour: Hallownest.soul
    property bool animate
    property bool ambient: animate
    property bool active: hover.hovered
    property bool glow: true
    property real t

    readonly property string kind: {
        switch (icon) {
        case "clear_day":
        case "wb_sunny":
            return "sun";
        case "wb_twilight":
            return "twilight";
        case "bedtime":
        case "clear_night":
            return "moon";
        case "partly_cloudy_day":
        case "partly_cloudy_night":
            return "partly";
        case "cloud":
            return "cloud";
        case "foggy":
            return "fog";
        case "rainy":
            return "rain";
        case "cloudy_snowing":
        case "snowing_heavy":
            return "snow";
        case "thunderstorm":
            return "storm";
        case "air":
            return "wind";
        case "water_drop":
            return "drop";
        case "thermostat":
            return "temp";
        default:
            return "";
        }
    }
    readonly property bool precip: kind === "rain" || kind === "snow" || kind === "storm"
    readonly property real wave: Math.sin(t * Math.PI * 2)
    readonly property real flash: (t > 0.08 && t < 0.14) || (t > 0.2 && t < 0.25) ? 1 : 0

    function phase(offset: real): real {
        return (t + offset) % 1;
    }

    function drop(x: real, y: real, s: real): string {
        return `M ${x} ${y - 3.4 * s} Q ${x + 2.6 * s} ${y + 0.6 * s} ${x} ${y + 2.2 * s} Q ${x - 2.6 * s} ${y + 0.6 * s} ${x} ${y - 3.4 * s} Z`;
    }

    function diamond(x: real, y: real, s: real): string {
        return `M ${x} ${y - s} L ${x + s} ${y} L ${x} ${y + s} L ${x - s} ${y} Z`;
    }

    implicitWidth: size
    implicitHeight: size

    NumberAnimation on t {
        running: root.visible && (root.ambient || root.active) && root.kind !== ""
        loops: Animation.Infinite
        from: 0
        to: 1
        duration: root.kind === "fog" || root.kind === "wind" || root.kind === "sun" ? 6000 : 2400
    }

    HoverHandler {
        id: hover
    }

    MaterialIcon {
        anchors.centerIn: parent
        visible: root.kind === ""
        text: root.icon
        fontStyle: root.fontStyle
        color: root.colour
    }

    Item {
        width: 48
        height: 48
        scale: root.size / 48
        transformOrigin: Item.TopLeft
        visible: root.kind !== ""
        layer.enabled: root.glow
        layer.smooth: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.colour
            shadowOpacity: 0.55
            shadowBlur: 0.7
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            blurMax: 16
        }

        Shape {
            width: 48
            height: 48
            visible: root.kind === "sun" || (root.kind === "partly" && root.icon !== "partly_cloudy_night")
            x: root.kind === "partly" ? 7 : 0
            y: root.kind === "partly" ? -7 : 0
            scale: root.kind === "partly" ? 0.72 : 1
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: root.colour
                strokeWidth: 1.6
                capStyle: ShapePath.RoundCap

                PathSvg {
                    path: {
                        let d = "";
                        for (let i = 0; i < 8; i++) {
                            const a = (i / 8 + root.t / 8) * Math.PI * 2;
                            const r1 = 12.5;
                            const r2 = i % 2 ? 15.5 : 18.5;
                            d += `M ${24 + Math.cos(a) * r1} ${24 + Math.sin(a) * r1} L ${24 + Math.cos(a) * r2} ${24 + Math.sin(a) * r2} `;
                        }
                        return d;
                    }
                }
            }

            ShapePath {
                fillColor: root.colour
                strokeWidth: -1

                PathAngleArc {
                    centerX: 24
                    centerY: 24
                    radiusX: 8 + root.wave * 0.5
                    radiusY: 8 + root.wave * 0.5
                    startAngle: 0
                    sweepAngle: 360
                }
            }

            ShapePath {
                fillColor: Hallownest.void_
                strokeWidth: -1

                PathSvg {
                    path: root.diamond(24, 24, 2.2)
                }
            }
        }

        Shape {
            visible: root.kind === "twilight"
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: root.colour
                strokeWidth: 1.6
                capStyle: ShapePath.RoundCap

                PathSvg {
                    path: {
                        let d = "M 6 33 L 42 33 ";
                        for (let i = 0; i < 5; i++) {
                            const a = Math.PI + (i + 1) / 6 * Math.PI;
                            const r2 = 15 + Math.abs(root.wave) * 1.5 + (i % 2 ? 0 : 2);
                            d += `M ${24 + Math.cos(a) * 12} ${33 + Math.sin(a) * 12} L ${24 + Math.cos(a) * r2} ${33 + Math.sin(a) * r2} `;
                        }
                        return d + "M 12 38 L 36 38 M 18 42 L 30 42";
                    }
                }
            }

            ShapePath {
                fillColor: root.colour
                strokeWidth: -1

                PathSvg {
                    path: "M 15.5 33 A 8.5 8.5 0 0 1 32.5 33 Z"
                }
            }
        }

        Shape {
            width: 48
            height: 48
            visible: root.kind === "moon" || root.icon === "partly_cloudy_night"
            x: root.icon === "partly_cloudy_night" ? 7 : 0
            y: (root.icon === "partly_cloudy_night" ? -7 : 0) + root.wave * 0.8
            scale: root.icon === "partly_cloudy_night" ? 0.72 : 1
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: root.colour
                strokeWidth: -1

                PathSvg {
                    path: "M 28 9 A 15 15 0 1 0 39 33 A 12 12 0 1 1 28 9 Z"
                }
            }

            ShapePath {
                fillColor: Qt.alpha(root.colour, 0.4 + 0.6 * Math.abs(Math.sin(root.t * Math.PI * 2)))
                strokeWidth: -1

                PathSvg {
                    path: root.diamond(37, 12, 2.2)
                }
            }

            ShapePath {
                fillColor: Qt.alpha(root.colour, 0.4 + 0.6 * Math.abs(Math.cos(root.t * Math.PI * 2)))
                strokeWidth: -1

                PathSvg {
                    path: root.diamond(42, 21, 1.5)
                }
            }
        }

        Shape {
            visible: root.kind === "fog" || root.kind === "wind"
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: root.colour
                strokeWidth: 1.8
                capStyle: ShapePath.RoundCap

                PathSvg {
                    path: {
                        if (root.kind === "wind") {
                            const s = root.wave * 1.5;
                            return `M ${6 + s} 17 L ${30 + s} 17 A 4.5 4.5 0 1 0 ${26 + s} 12.5 M ${4 - s} 25 L ${36 - s} 25 A 5 5 0 1 1 ${32 - s} 30 M ${10 + s} 33 L ${24 + s} 33`;
                        }
                        let d = "";
                        for (let i = 0; i < 3; i++) {
                            const y = 16 + i * 8;
                            const s = Math.sin((root.t + i / 3) * Math.PI * 2) * 3;
                            d += `M ${7 + s + i * 2} ${y} Q ${15 + s} ${y - 3} ${24 + s} ${y} T ${41 + s - i * 2} ${y} `;
                        }
                        return d;
                    }
                }
            }
        }

        Shape {
            visible: root.kind === "drop"
            y: root.wave * 1
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Qt.alpha(Hallownest.lifeblood, 0.25)
                strokeColor: Hallownest.lifeblood
                strokeWidth: 1.8

                PathSvg {
                    path: root.drop(24, 26, 4.5)
                }
            }
        }

        Shape {
            visible: root.kind === "temp"
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: root.colour
                strokeWidth: 1.8
                capStyle: ShapePath.RoundCap

                PathSvg {
                    path: "M 20 30 L 20 10 A 4 4 0 0 1 28 10 L 28 30 A 7 7 0 1 1 20 30 Z"
                }
            }

            ShapePath {
                fillColor: Hallownest.lifeblood
                strokeWidth: -1

                PathSvg {
                    path: `M 22.5 ${28 - Math.abs(root.wave) * 4} L 25.5 ${28 - Math.abs(root.wave) * 4} L 25.5 33 A 3.5 3.5 0 1 1 22.5 33 Z`
                }
            }
        }

        Cloud {
            visible: root.kind === "cloud" || root.kind === "partly" || root.precip
            x: root.kind === "partly" ? -3 + root.wave * 1.2 : root.wave * 0.8
            y: root.kind === "partly" ? 5 : root.precip ? -6 : 0
            brightness: root.kind === "storm" ? root.flash : 0
        }

        Repeater {
            model: root.kind === "rain" ? 3 : 0

            Shape {
                id: raindrop

                required property int index
                readonly property real p: root.phase(index / 3)

                opacity: Math.sin(p * Math.PI)
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: Hallownest.lifeblood
                    strokeWidth: -1

                    PathSvg {
                        path: root.drop(15 + raindrop.index * 9, 32 + raindrop.p * 13, 1.35)
                    }
                }
            }
        }

        Repeater {
            model: root.kind === "snow" ? 3 : 0

            Shape {
                id: flake

                required property int index
                readonly property real p: root.phase(index / 3)

                opacity: Math.sin(p * Math.PI)
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: Hallownest.crystal
                    strokeWidth: -1

                    PathSvg {
                        path: root.diamond(15 + flake.index * 9 + Math.sin(flake.p * Math.PI * 2) * 2, 32 + flake.p * 12, 2.5)
                    }
                }
            }
        }

        Shape {
            visible: root.kind === "storm"
            opacity: 0.45 + root.flash * 0.55
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Hallownest.soul
                strokeWidth: -1

                PathSvg {
                    path: "M 26 29 L 19.5 39 L 24 39 L 21 47 L 30.5 35.5 L 25.8 35.5 L 29 29 Z"
                }
            }
        }
    }

    component Cloud: Shape {
        id: cloud

        property real brightness

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Qt.tint(Hallownest.void_, Qt.rgba(1, 1, 1, cloud.brightness * 0.25))
            strokeColor: root.colour
            strokeWidth: 1.8
            joinStyle: ShapePath.RoundJoin

            PathSvg {
                path: "M 13 36 A 7 7 0 0 1 12.2 22.1 A 11 11 0 0 1 33.2 19.6 A 8.2 8.2 0 0 1 35.5 36 Z"
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.alpha(root.colour, 0.45)
            strokeWidth: 1.1
            capStyle: ShapePath.RoundCap

            PathSvg {
                path: "M 17 31 Q 22 27.5 27 31 M 25 25 Q 28.5 22.5 32 25"
            }
        }
    }
}
