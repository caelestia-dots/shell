import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell.Io
import Caelestia.Components
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.extraLarge

    implicitWidth: Tokens.sizes.dashboard.perfNetworkCardWidth
    implicitHeight: Tokens.sizes.dashboard.perfNetworkCardHeight

    ServiceRef {
        service: NetworkUsage
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        anchors.bottomMargin: Tokens.padding.medium
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "swap_vert"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: qsTr("Network")
                font: Tokens.font.title.medium
            }

            Item {
                Layout.fillWidth: true
            }

            IconButton {
                id: speedBtn

                property int phase: 0
                property real baseAngle: phase === 1 ? 78 : (phase === 2 ? 0 : (phase === 3 ? 65 : -90))
                property real jitter: 0

                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                type: IconButton.Tonal
                implicitWidth: 32
                implicitHeight: 32
                isRound: false
                defaultRadius: Tokens.rounding.small
                checkedRadius: implicitHeight / 2
                checked: speedProc.running
                radiusAnim.type: Anim.DefaultSpatial
                label.visible: false

                onClicked: {
                    if (speedProc.running)
                        return;
                    speedBtn.phase = 1;
                    speedProc.running = true;
                }

                Timer {
                    id: jitterTimer

                    interval: 45
                    repeat: true
                    running: speedBtn.phase === 1 || speedBtn.phase === 3
                    onTriggered: {
                        const spread = speedBtn.phase === 1 ? 9 : 6;
                        speedBtn.jitter = (Math.random() * spread) - (spread / 2);
                    }
                }

                Item {
                    anchors.centerIn: parent
                    width: 24
                    height: 20

                    Shape {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.samples: 4

                        ShapePath {
                            strokeWidth: 1.5
                            strokeColor: speedBtn.onColour
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin

                            PathAngleArc {
                                centerX: 12
                                centerY: 11
                                radiusX: 8.5
                                radiusY: 8.5
                                startAngle: 180
                                sweepAngle: 180
                            }
                        }

                        ShapePath {
                            strokeWidth: 1.5
                            strokeColor: speedBtn.onColour
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            startX: 3.5
                            startY: 11

                            PathLine {
                                x: 5.7
                                y: 11
                            }
                        }

                        ShapePath {
                            strokeWidth: 1.5
                            strokeColor: speedBtn.onColour
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            startX: 12
                            startY: 2.5

                            PathLine {
                                x: 12
                                y: 4.7
                            }
                        }

                        ShapePath {
                            strokeWidth: 1.5
                            strokeColor: speedBtn.onColour
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            startX: 20.5
                            startY: 11

                            PathLine {
                                x: 18.3
                                y: 11
                            }
                        }
                    }

                    Item {
                        x: 12
                        y: 11
                        rotation: speedBtn.baseAngle

                        Behavior on rotation {
                            NumberAnimation {
                                duration: speedBtn.phase === 2 ? 450 : (speedBtn.phase === 0 ? 550 : 500)
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: speedBtn.phase === 2 ? [0.05, 0.7, 0.1, 1.0, 1.0, 1.0] : (speedBtn.phase === 0 ? [0.22, 1.0, 0.36, 1.0, 1.0, 1.0] : [0.2, 0.0, 0.0, 1.0, 1.0, 1.0])
                            }
                        }

                        Item {
                            rotation: speedBtn.jitter

                            Behavior on rotation {
                                NumberAnimation {
                                    duration: 40
                                    easing.type: Easing.Linear
                                }
                            }

                            Rectangle {
                                x: -0.75
                                y: -5.5
                                width: 1.5
                                height: 5.5
                                radius: 0.75
                                color: speedBtn.onColour
                            }
                        }
                    }

                    Rectangle {
                        x: 10.5
                        y: 9.5
                        width: 3
                        height: 3
                        radius: 1.5
                        color: speedBtn.onColour
                    }
                }
            }

            Process {
                id: speedProc

                command: ["bash", "-c", 'export LC_ALL=C\nget_rx() { awk \'NR>2 && $1!~/lo:/ {rx+=$2} END {print rx+0}\' /proc/net/dev 2>/dev/null || echo 0; }\nget_tx() { awk \'NR>2 && $1!~/lo:/ {tx+=$10} END {print tx+0}\' /proc/net/dev 2>/dev/null || echo 0; }\nformat_speed() {\n  awk -v b="$1" -v t="$2" \'BEGIN { if (t<=0 || b<=0) { print "0.0 B/s"; exit; } r=b/t; if (r<1024) printf "%.1f B/s", r; else if (r<1048576) printf "%.1f KB/s", r/1024; else if (r<1073741824) printf "%.1f MB/s", r/1048576; else printf "%.1f GB/s", r/1073741824; }\'\n}\nRUNTIME_DIR="${XDG_RUNTIME_DIR:-/dev/shm}"\n[ -d "$RUNTIME_DIR" ] || RUNTIME_DIR="/tmp"\nTEMP_PAYLOAD=$(mktemp "${RUNTIME_DIR}/caelestia-speed-XXXXXX.dat" 2>/dev/null || echo "${RUNTIME_DIR}/caelestia_spd_$$.dat")\ntrap \'trap "" TERM INT; kill -- -$$ 2>/dev/null; rm -f "$TEMP_PAYLOAD"\' EXIT INT TERM HUP\necho "PHASE_DL"\nrx_before=$(get_rx)\nt_dl_start=$(date +%s%N)\ntimeout 3.5 bash -c \' (while true; do curl -s -f --connect-timeout 1 -o /dev/null "https://registry.npmjs.org/typescript/-/typescript-5.7.3.tgz" 2>/dev/null || break; done) & (while true; do curl -s -f --connect-timeout 1 -o /dev/null "https://registry.npmjs.org/@tensorflow/tfjs-core/-/tfjs-core-4.22.0.tgz" 2>/dev/null || break; done) & (while true; do curl -s -f --connect-timeout 1 -o /dev/null "https://registry.npmjs.org/typescript/-/typescript-5.7.3.tgz" 2>/dev/null || break; done) & (while true; do curl -s -f --connect-timeout 1 -o /dev/null "https://registry.npmjs.org/@tensorflow/tfjs-core/-/tfjs-core-4.22.0.tgz" 2>/dev/null || break; done) & wait \' 2>/dev/null || true\nt_dl_end=$(date +%s%N)\nrx_after=$(get_rx)\necho "PHASE_MID"\nsleep 0.45\necho "PHASE_UL"\nhead -c 10000000 /dev/zero > "$TEMP_PAYLOAD" 2>/dev/null || true\ntx_before=$(get_tx)\nt_ul_start=$(date +%s%N)\ntimeout 3.5 bash -c \' (while true; do curl -s -f --connect-timeout 1 -o /dev/null -X POST --data-binary "@\'"$TEMP_PAYLOAD"\'" "https://speed.cloudflare.com/__up" 2>/dev/null || break; done) & (while true; do curl -s -f --connect-timeout 1 -o /dev/null -X POST --data-binary "@\'"$TEMP_PAYLOAD"\'" "https://speed.cloudflare.com/__up" 2>/dev/null || break; done) & (while true; do curl -s -f --connect-timeout 1 -o /dev/null -X POST --data-binary "@\'"$TEMP_PAYLOAD"\'" "https://speed.cloudflare.com/__up" 2>/dev/null || break; done) & (while true; do curl -s -f --connect-timeout 1 -o /dev/null -X POST --data-binary "@\'"$TEMP_PAYLOAD"\'" "https://speed.cloudflare.com/__up" 2>/dev/null || break; done) & wait \' 2>/dev/null || true\nt_ul_end=$(date +%s%N)\ntx_after=$(get_tx)\necho "DONE"\ndl_elapsed=$(awk "BEGIN {printf \\"%.3f\\", ($t_dl_end - $t_dl_start)/1000000000}")\nul_elapsed=$(awk "BEGIN {printf \\"%.3f\\", ($t_ul_end - $t_ul_start)/1000000000}")\ndl_bytes=$(awk "BEGIN {print $rx_after - $rx_before}")\nul_bytes=$(awk "BEGIN {print $tx_after - $tx_before}")\ndl_str=$(format_speed "$dl_bytes" "$dl_elapsed")\nul_str=$(format_speed "$ul_bytes" "$ul_elapsed")\nif [ "$dl_bytes" -le 0 ] && [ "$ul_bytes" -le 0 ]; then notify-send -i network-error "Network Speed Test" "Failed to measure bandwidth (network unreachable)." -a "caelestia-shell"; else notify-send -i network-wireless "Network Speed Test" "Download: ${dl_str}\\nUpload: ${ul_str}" -a "caelestia-shell"; fi']

                stdout: SplitParser {
                    onRead: line => {
                        const trimmed = line.trim();
                        if (trimmed === "PHASE_DL") {
                            speedBtn.phase = 1;
                        } else if (trimmed === "PHASE_MID") {
                            speedBtn.phase = 2;
                        } else if (trimmed === "PHASE_UL") {
                            speedBtn.phase = 3;
                        } else if (trimmed === "DONE") {
                            speedBtn.phase = 0;
                        }
                    }
                }

                onRunningChanged: {
                    if (!running)
                        speedBtn.phase = 0;
                }
            }
        }

        // Sparkline graph
        Item {
            Layout.topMargin: Tokens.spacing.medium
            Layout.bottomMargin: Tokens.spacing.small
            Layout.fillWidth: true
            Layout.fillHeight: true

            SparklineItem {
                id: sparkline

                property real targetMax: 1024
                property real smoothMax: targetMax

                anchors.fill: parent
                line1: NetworkUsage.uploadBuffer
                line1Color: Colours.palette.m3secondary
                line1FillAlpha: 0.15
                line2: NetworkUsage.downloadBuffer
                line2Color: Colours.palette.m3tertiary
                line2FillAlpha: 0.2
                maxValue: smoothMax
                historyLength: NetworkUsage.historyLength

                Connections {
                    function onValuesChanged(): void {
                        sparkline.targetMax = Math.max(NetworkUsage.downloadBuffer.maximum, NetworkUsage.uploadBuffer.maximum, 1024);
                        slideAnim.restart();
                    }

                    target: NetworkUsage.downloadBuffer
                }

                NumberAnimation {
                    id: slideAnim

                    target: sparkline
                    property: "slideProgress"
                    from: 0
                    to: 1
                    easing.type: Easing.Linear
                    duration: GlobalConfig.dashboard.resourceUpdateInterval
                }

                Behavior on smoothMax {
                    Anim {}
                }
            }

            // "Collecting data" placeholder
            StyledText {
                anchors.centerIn: parent
                text: qsTr("Collecting data...")
                font: Tokens.font.body.small
                color: Colours.palette.m3outline
                visible: NetworkUsage.downloadBuffer.count < 2
            }
        }

        // Download row
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "download"
                color: Colours.palette.m3tertiary
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: qsTr("Download")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: {
                    const fmt = NetworkUsage.formatBytesRate(NetworkUsage.downloadSpeed ?? 0);
                    return fmt ? `${fmt.value.toFixed(1)} ${fmt.unit}` : "0.0 B/s";
                }
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                color: Colours.palette.m3tertiary
            }
        }

        // Upload row
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "upload"
                color: Colours.palette.m3secondary
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: qsTr("Upload")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: {
                    const fmt = NetworkUsage.formatBytesRate(NetworkUsage.uploadSpeed ?? 0);
                    return fmt ? `${fmt.value.toFixed(1)} ${fmt.unit}` : "0.0 B/s";
                }
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                color: Colours.palette.m3secondary
            }
        }

        // Session totals
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "history"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: qsTr("Total")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: {
                    const down = NetworkUsage.formatBytes(NetworkUsage.downloadTotal ?? 0);
                    const up = NetworkUsage.formatBytes(NetworkUsage.uploadTotal ?? 0);
                    return (down && up) ? `↓${down.value.toFixed(1)}${down.unit} ↑${up.value.toFixed(1)}${up.unit}` : "↓0.0B ↑0.0B";
                }
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
