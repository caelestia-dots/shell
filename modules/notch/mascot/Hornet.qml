pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.components
import qs.components.hallownest
import qs.services

// Hornet, Princess-Protector of Hallownest (~/Pictures/InkScape/hornet.svg, page coordinates).
// Same interface as Knight; "boss" morphs her mask into its final form.
Item {
    id: root

    property bool dozing
    property bool running
    property bool music
    property bool tracking
    property real targetX
    property real targetY
    property real size: 40
    property real voidness
    property real soulness
    readonly property color cloak: Hallownest.isMono ? "#787a82" : "#b3373f"
    readonly property color maskColour: Qt.tint(Qt.tint(Hallownest.isMono ? "#e4e5e8" : "#daebeb", Qt.rgba(1, 1, 1, soulness * 0.7)), Qt.rgba(0.03, 0.03, 0.045, voidness))
    readonly property color rimColour: Qt.tint(Hallownest.light ? Qt.rgba(0, 0, 0, 0.55) : "transparent", Qt.alpha(Hallownest.soul, Math.max(soulness, voidness)))
    readonly property color eyeColour: Qt.tint(Qt.tint(Qt.tint("black", Qt.alpha(Hallownest.infection, infect)), Qt.rgba(0.66, 0.74, 0.84, soulness)), Qt.rgba(0.95, 0.97, 0.98, voidness))
    readonly property color threadColour: Hallownest.light ? "#5a5f6b" : "#e8e4dc"

    readonly property real originX: 0
    readonly property real originY: 4
    readonly property real canvasWidth: 64
    readonly property real canvasHeight: 47
    readonly property real ratio: size / canvasHeight
    readonly property bool reacting: celebrateAnim.running || vibeAnim.running || sadAnim.running || cryAnim.running || infectAnim.running || angryAnim.running || shockedAnim.running || soulAnim.running || voidAnim.running || bossAnim.running
    readonly property bool acting: blink2Anim.running || lookAnim.running || tiltAnim.running || hopAnim.running || confusedAnim.running || sighAnim.running || stareAnim.running || dashAnim.running
    readonly property bool busy: wakeAnim.running || leaveAnim.running || flareAnim.running || acting || reacting

    readonly property var reactionNames: ["happy", "vibe", "sad", "cry", "infected", "angry", "shocked", "soul", "void", "boss"]
    readonly property var actionNames: ["look", "tilt", "hop", "confused", "sigh", "stare", "dash"]

    // open, happy, sad
    property string expression: "open"
    property real breath
    property real nod
    property real sway
    property real tilt
    property real hop
    property real squash
    property real blink: 1
    property real lid: dozing && !reacting ? 0.1 : 1
    property real widen: 1
    property real zProgress
    property bool scanning
    property real scanX
    property real scanY
    property real droop
    property real tears
    property real dripTime
    property real infect
    property real shake
    property real anger
    property real angerBeat
    property real question
    property real dash
    property real speed
    property real vanish
    property real threads
    property real threadTime
    property real boss
    // Set for the whole transformation so the notch can grow before the taller mask appears
    property bool bossShown

    property real idleX: 0.7
    property real idleY: -0.2
    readonly property real lookX: scanning ? scanX : tracking ? targetX : idleX
    readonly property real lookY: scanning ? scanY : tracking ? targetY : idleY
    property real smoothLookX: lookX
    property real smoothLookY: lookY

    signal woke

    function allAnims(): var {
        return [celebrateAnim, vibeAnim, sadAnim, cryAnim, infectAnim, angryAnim, shockedAnim, soulAnim, voidAnim, bossAnim, blink2Anim, lookAnim, tiltAnim, hopAnim, confusedAnim, sighAnim, stareAnim, dashAnim];
    }

    function resetFace(): void {
        for (const anim of allAnims())
            anim.stop();
        expression = "open";
        scanning = false;
        scanX = 0;
        scanY = 0;
        droop = 0;
        tears = 0;
        infect = 0;
        shake = 0;
        anger = 0;
        angerBeat = 0;
        question = 0;
        dash = 0;
        speed = 0;
        vanish = 0;
        threads = 0;
        boss = 0;
        bossShown = false;
        soulness = 0;
        voidness = 0;
        widen = 1;
        tilt = 0;
        hop = 0;
        squash = 0;
    }

    function wake(): void {
        if (wakeAnim.running || leaveAnim.running || flareAnim.running)
            return;
        if (boss > 0 || vanish > 0) {
            for (const anim of allAnims())
                anim.stop();
            flareAnim.restart();
            return;
        }
        const startle = lid < 0.5;
        resetFace();
        wakeAnim.startle = startle;
        wakeAnim.restart();
    }

    function leave(): void {
        if (wakeAnim.running || leaveAnim.running || flareAnim.running)
            return;
        resetFace();
        leaveAnim.restart();
    }

    function react(name: string): void {
        const anims = {
            happy: celebrateAnim,
            vibe: vibeAnim,
            sad: sadAnim,
            cry: cryAnim,
            infected: infectAnim,
            angry: angryAnim,
            shocked: shockedAnim,
            soul: soulAnim,
            void: voidAnim,
            boss: bossAnim
        };
        if (!anims[name] || wakeAnim.running || leaveAnim.running || flareAnim.running || bossAnim.running)
            return;
        resetFace();
        anims[name].restart();
    }

    function act(name: string): void {
        const anims = {
            blink2: blink2Anim,
            look: lookAnim,
            tilt: tiltAnim,
            hop: hopAnim,
            confused: confusedAnim,
            sigh: sighAnim,
            stare: stareAnim,
            dash: dashAnim
        };
        if (!anims[name] || wakeAnim.running || leaveAnim.running || flareAnim.running || bossAnim.running)
            return;
        resetFace();
        anims[name].restart();
    }

    function angerPath(cx: real, cy: real, q: real): string {
        return [[-1, -1], [1, -1], [-1, 1], [1, 1]].map(([sx, sy]) => `M ${cx + sx * q} ${cy + sy * 4 * q} Q ${cx + sx * q} ${cy + sy * q} ${cx + sx * 4 * q} ${cy + sy * q}`).join(" ");
    }

    function randomAction(): void {
        if (Math.random() < 0.03) {
            react("boss");
            return;
        }
        const actions = ["blink2", "look", "tilt", "tilt", "happy", "hop", "confused", "sigh", "stare", "dash", "dash", "void"];
        const action = actions[Math.floor(Math.random() * actions.length)];
        if (reactionNames.includes(action))
            react(action);
        else
            act(action);
    }

    function surprise(): void {
        const all = reactionNames.concat(actionNames);
        play(all[Math.floor(Math.random() * all.length)]);
    }

    function play(name: string): void {
        if (reactionNames.includes(name))
            react(name);
        else
            act(name);
    }

    implicitWidth: canvasWidth * ratio
    implicitHeight: size

    onVisibleChanged: {
        if (!visible)
            resetFace();
    }

    Behavior on lid {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Behavior on smoothLookX {
        SpringAnimation {
            spring: 3.6
            damping: 0.32
            epsilon: 0.005
        }
    }

    Behavior on smoothLookY {
        SpringAnimation {
            spring: 3.6
            damping: 0.32
            epsilon: 0.005
        }
    }

    SequentialAnimation {
        running: root.running
        loops: Animation.Infinite

        onRunningChanged: {
            if (!running)
                root.breath = 0;
        }

        To {
            property: "breath"
            to: 1
            duration: root.dozing ? 2800 : 1900
        }
        To {
            property: "breath"
            to: 0
            duration: root.dozing ? 2800 : 1900
        }
    }

    SequentialAnimation {
        running: root.running && root.dozing && !root.busy
        loops: Animation.Infinite

        onRunningChanged: {
            if (!running)
                root.nod = 0;
        }

        To {
            property: "nod"
            to: 1
            duration: 2800
        }
        To {
            property: "nod"
            to: -0.3
            duration: 2800
        }
    }

    SequentialAnimation {
        running: root.running && (root.music && !groove.locked || vibeAnim.running) && !root.dozing
        loops: Animation.Infinite

        onRunningChanged: {
            if (!running)
                root.sway = 0;
        }

        To {
            property: "sway"
            to: 1
            duration: 650
        }
        To {
            property: "sway"
            to: -1
            duration: 1300
        }
        To {
            property: "sway"
            to: 0
            duration: 650
        }
    }

    Groove {
        id: groove

        mascot: root
        active: root.running && root.music && !root.dozing && !root.busy
    }

    NumberAnimation {
        target: root
        property: "zProgress"
        running: root.dozing && root.running
        loops: Animation.Infinite
        from: 0
        to: 1
        duration: 2600
    }

    NumberAnimation {
        target: root
        property: "threadTime"
        running: root.running && root.threads > 0.01
        loops: Animation.Infinite
        from: 0
        to: 1
        duration: 2000
    }

    NumberAnimation {
        target: root
        property: "dripTime"
        running: root.running && root.tears > 0.01
        loops: Animation.Infinite
        from: 0
        to: 1
        duration: 1100
    }

    Timer {
        running: root.running && !root.dozing && (!root.busy || root.boss === 1)
        repeat: true
        interval: 3500

        onTriggered: {
            interval = 2500 + Math.random() * 4000;
            blinkAnim.restart();
        }
    }

    Timer {
        running: root.running && !root.dozing && !root.busy
        repeat: true
        interval: 6000

        onTriggered: {
            interval = 4000 + Math.random() * 6000;
            root.randomAction();
        }
    }

    Timer {
        running: root.running && !root.tracking && !root.dozing && !root.scanning
        repeat: true
        interval: 1200

        onTriggered: {
            interval = 900 + Math.random() * 1700;
            if (Math.random() < 0.2) {
                root.idleX = (Math.random() - 0.5) * 0.4;
            } else {
                const side = root.idleX > 0 ? -1 : 1;
                root.idleX = side * (0.7 + Math.random() * 0.3);
            }
            root.idleY = -0.6 + Math.random() * 1;
        }
    }

    SequentialAnimation {
        id: blinkAnim

        To {
            property: "blink"
            to: 0.1
            duration: 70
        }
        To {
            property: "blink"
            to: 1
            duration: 110
        }
    }

    SequentialAnimation {
        id: blink2Anim

        ScriptAction {
            script: blinkAnim.restart()
        }
        PauseAnimation {
            duration: 260
        }
        ScriptAction {
            script: blinkAnim.restart()
        }
        PauseAnimation {
            duration: 200
        }
    }

    SequentialAnimation {
        id: lookAnim

        ScriptAction {
            script: {
                root.scanX = root.smoothLookX;
                root.scanY = 0;
                root.scanning = true;
            }
        }
        To {
            property: "scanX"
            to: -1
            duration: 500
        }
        PauseAnimation {
            duration: 700
        }
        To {
            property: "scanX"
            to: 1
            duration: 700
        }
        PauseAnimation {
            duration: 700
        }
        To {
            property: "scanX"
            to: 0
            duration: 400
        }
        ScriptAction {
            script: root.scanning = false
        }
    }

    SequentialAnimation {
        id: tiltAnim

        To {
            property: "tilt"
            to: Math.random() < 0.5 ? -12 : 12
            duration: 380
        }
        PauseAnimation {
            duration: 1100
        }
        To {
            property: "tilt"
            to: 0
            duration: 420
        }
    }

    SequentialAnimation {
        id: hopAnim

        Bounce {
            height: 1.3
        }
        To {
            property: "squash"
            to: 0
            duration: 200
            easing.type: Easing.OutBack
        }
    }

    SequentialAnimation {
        id: confusedAnim

        ParallelAnimation {
            To {
                property: "tilt"
                to: -13
                duration: 400
            }
            To {
                property: "question"
                to: 1
                duration: 300
            }
        }
        PauseAnimation {
            duration: 1600
        }
        ParallelAnimation {
            To {
                property: "tilt"
                to: 0
                duration: 400
            }
            To {
                property: "question"
                to: 0
                duration: 300
            }
        }
    }

    SequentialAnimation {
        id: sighAnim

        ScriptAction {
            script: root.expression = "sad"
        }
        To {
            property: "droop"
            to: 0.5
            duration: 700
        }
        PauseAnimation {
            duration: 1100
        }
        To {
            property: "droop"
            to: 0
            duration: 600
        }
        ScriptAction {
            script: root.expression = "open"
        }
    }

    SequentialAnimation {
        id: stareAnim

        ScriptAction {
            script: {
                root.scanX = root.smoothLookX;
                root.scanY = root.smoothLookY;
                root.scanning = true;
            }
        }
        ParallelAnimation {
            To {
                property: "scanX"
                to: 0
                duration: 400
            }
            To {
                property: "scanY"
                to: 0.2
                duration: 400
            }
            To {
                property: "widen"
                to: 1.15
                duration: 400
            }
        }
        PauseAnimation {
            duration: 2200
        }
        To {
            property: "widen"
            to: 1
            duration: 300
        }
        ScriptAction {
            script: root.scanning = false
        }
    }

    // A dash to the left, then one to the right, with speed lines
    SequentialAnimation {
        id: dashAnim

        ParallelAnimation {
            To {
                property: "dash"
                to: 0.3
                duration: 200
            }
            To {
                property: "squash"
                to: 0.35
                duration: 200
            }
        }
        ParallelAnimation {
            To {
                property: "dash"
                to: -1.2
                duration: 140
                easing.type: Easing.OutQuad
            }
            To {
                property: "squash"
                to: -0.5
                duration: 140
            }
            To {
                property: "speed"
                to: 1
                duration: 100
            }
            To {
                property: "tilt"
                to: -8
                duration: 140
            }
        }
        ParallelAnimation {
            To {
                property: "squash"
                to: 0
                duration: 260
                easing.type: Easing.OutBack
            }
            To {
                property: "speed"
                to: 0
                duration: 300
            }
            To {
                property: "tilt"
                to: 0
                duration: 300
            }
        }
        PauseAnimation {
            duration: 250
        }
        ParallelAnimation {
            To {
                property: "dash"
                to: 1.2
                duration: 140
                easing.type: Easing.OutQuad
            }
            To {
                property: "squash"
                to: -0.5
                duration: 140
            }
            To {
                property: "speed"
                to: 1
                duration: 100
            }
            To {
                property: "tilt"
                to: 8
                duration: 140
            }
        }
        ParallelAnimation {
            To {
                property: "squash"
                to: 0
                duration: 260
                easing.type: Easing.OutBack
            }
            To {
                property: "speed"
                to: 0
                duration: 300
            }
            To {
                property: "tilt"
                to: 0
                duration: 300
            }
        }
        PauseAnimation {
            duration: 300
        }
        To {
            property: "dash"
            to: 0
            duration: 450
        }
    }

    SequentialAnimation {
        id: celebrateAnim

        ScriptAction {
            script: root.expression = "happy"
        }
        Bounce {
            height: 1.2
            lean: -6
        }
        Bounce {
            height: 1.2
            lean: 6
        }
        To {
            property: "tilt"
            to: 0
            duration: 200
        }
        To {
            property: "squash"
            to: 0
            duration: 200
            easing.type: Easing.OutBack
        }
        PauseAnimation {
            duration: 900
        }
        ScriptAction {
            script: root.expression = "open"
        }
    }

    SequentialAnimation {
        id: vibeAnim

        ScriptAction {
            script: root.expression = "happy"
        }
        SequentialAnimation {
            loops: 4

            To {
                property: "hop"
                to: 0.25
                duration: 300
            }
            To {
                property: "hop"
                to: 0
                duration: 350
            }
        }
        ScriptAction {
            script: root.expression = "open"
        }
    }

    SequentialAnimation {
        id: sadAnim

        ScriptAction {
            script: root.expression = "sad"
        }
        To {
            property: "droop"
            to: 1
            duration: 800
        }
        PauseAnimation {
            duration: 2600
        }
        To {
            property: "droop"
            to: 0
            duration: 700
        }
        ScriptAction {
            script: root.expression = "open"
        }
    }

    SequentialAnimation {
        id: cryAnim

        ScriptAction {
            script: root.expression = "sad"
        }
        ParallelAnimation {
            To {
                property: "droop"
                to: 1
                duration: 700
            }
            To {
                property: "tears"
                to: 1
                duration: 700
            }
        }
        PauseAnimation {
            duration: 3600
        }
        ParallelAnimation {
            To {
                property: "droop"
                to: 0
                duration: 700
            }
            To {
                property: "tears"
                to: 0
                duration: 700
            }
        }
        ScriptAction {
            script: root.expression = "open"
        }
    }

    SequentialAnimation {
        id: infectAnim

        To {
            property: "infect"
            to: 1
            duration: 900
        }
        Shake {
            amount: 0.8
            times: 5
        }
        PauseAnimation {
            duration: 1600
        }
        To {
            property: "infect"
            to: 0
            duration: 900
        }
    }

    SequentialAnimation {
        id: angryAnim

        To {
            property: "anger"
            to: 1
            duration: 250
        }
        Shake {
            amount: 1.2
            times: 6
        }
        SequentialAnimation {
            loops: 4

            To {
                property: "angerBeat"
                to: 1
                duration: 200
            }
            To {
                property: "angerBeat"
                to: 0
                duration: 300
            }
        }
        To {
            property: "anger"
            to: 0
            duration: 400
        }
    }

    SequentialAnimation {
        id: shockedAnim

        ParallelAnimation {
            To {
                property: "widen"
                to: 1.35
                duration: 150
            }
            To {
                property: "hop"
                to: 1
                duration: 180
            }
        }
        To {
            property: "hop"
            to: 0
            duration: 260
            easing.type: Easing.InQuad
        }
        PauseAnimation {
            duration: 1500
        }
        To {
            property: "widen"
            to: 1
            duration: 400
        }
    }

    SequentialAnimation {
        id: soulAnim

        ScriptAction {
            script: root.expression = "happy"
        }
        To {
            property: "soulness"
            to: 1
            duration: 700
        }
        PauseAnimation {
            duration: 2600
        }
        To {
            property: "soulness"
            to: 0
            duration: 900
        }
        ScriptAction {
            script: root.expression = "open"
        }
    }

    SequentialAnimation {
        id: voidAnim

        To {
            property: "voidness"
            to: 1
            duration: 900
        }
        PauseAnimation {
            duration: 2600
        }
        To {
            property: "voidness"
            to: 0
            duration: 900
        }
    }

    // Final form: the notch grows, silk threads rise and the mask stretches into its taller shape
    SequentialAnimation {
        id: bossAnim

        ScriptAction {
            script: root.bossShown = true
        }
        PauseAnimation {
            duration: 300
        }
        ParallelAnimation {
            To {
                property: "threads"
                to: 1
                duration: 500
            }
            Shake {
                amount: 1
                times: 4
            }
        }
        To {
            property: "boss"
            to: 1
            duration: 900
        }
        PauseAnimation {
            duration: 7000
        }
        To {
            property: "boss"
            to: 0
            duration: 700
        }
        To {
            property: "threads"
            to: 0
            duration: 500
        }
        ScriptAction {
            script: root.bossShown = false
        }
    }

    SequentialAnimation {
        id: wakeAnim

        property bool startle

        ScriptAction {
            script: {
                root.nod = 0;
                root.widen = wakeAnim.startle ? 1.3 : 1;
            }
        }
        Bounce {
            height: wakeAnim.startle ? 1.5 : 0.8
        }
        ParallelAnimation {
            To {
                property: "squash"
                to: 0
                duration: 220
                easing.type: Easing.OutBack
            }
            To {
                property: "widen"
                to: 1
                duration: 300
            }
        }
        ScriptAction {
            script: root.woke()
        }
    }

    // The final form (or a half-done exit) unravels into silk
    SequentialAnimation {
        id: flareAnim

        To {
            property: "threads"
            to: 1
            duration: 250
        }
        To {
            property: "vanish"
            to: 1
            duration: 320
            easing.type: Easing.InQuad
        }
        ScriptAction {
            script: root.woke()
        }
    }

    // She dashes out of the notch
    SequentialAnimation {
        id: leaveAnim

        ParallelAnimation {
            To {
                property: "dash"
                to: -0.5
                duration: 220
            }
            To {
                property: "squash"
                to: 0.4
                duration: 220
            }
        }
        ParallelAnimation {
            To {
                property: "dash"
                to: 4
                duration: 260
                easing.type: Easing.InQuad
            }
            To {
                property: "speed"
                to: 1
                duration: 120
            }
            To {
                property: "vanish"
                to: 1
                duration: 260
                easing.type: Easing.InQuad
            }
        }
        ScriptAction {
            script: root.woke()
        }
    }

    Item {
        width: root.canvasWidth
        height: root.canvasHeight
        scale: root.ratio
        transformOrigin: Item.TopLeft

        Item {
            id: body

            readonly property real pivotX: 32.08 - root.originX
            // Room above the mask for the soul glow and the taller final form
            readonly property real headroom: 20
            readonly property real pivotY: 48.88 - root.originY + headroom

            anchors.fill: parent
            anchors.topMargin: -headroom
            opacity: 1 - root.vanish
            layer.enabled: root.soulness > 0.01 || root.voidness > 0.01
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Hallownest.soul
                shadowOpacity: Math.max(root.soulness, root.voidness)
                shadowBlur: root.voidness > root.soulness ? 0.15 : 1
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
                blurMax: root.voidness > root.soulness ? 5 : 24
            }

            transform: [
                Scale {
                    origin.x: body.pivotX
                    origin.y: body.pivotY
                    xScale: 1 + root.squash * 0.12 - root.breath * 0.012 + root.boss * 0.06
                    yScale: 1 - root.squash * 0.14 + root.breath * 0.02 + root.boss * 0.06
                },
                Rotation {
                    origin.x: body.pivotX
                    origin.y: body.pivotY
                    angle: root.tilt + root.nod * 7 + root.sway * 5 - root.droop * 5
                },
                Translate {
                    x: root.shake + root.dash * 6
                    y: -root.hop * 7 + (root.dozing ? 2 : 0) + root.droop * 2
                }
            ]

            Item {
                x: -root.originX
                y: -root.originY + body.headroom

                // Her usual mask, stretching upwards as it gives way to the final form
                Item {
                    opacity: 1 - root.boss
                    visible: opacity > 0.01
                    transform: Scale {
                        origin.x: 32.08
                        origin.y: 48.88
                        yScale: 1 + root.boss * 0.32
                    }

                    Shape {
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            fillColor: root.maskColour
                            strokeColor: root.rimColour
                            strokeWidth: 0.8
                            joinStyle: ShapePath.RoundJoin

                            PathSvg {
                                path: "M 10.210064,31.35092 C 8.6691133,22.708123 12.818355,16.810036 21.181937,8.3483274 c 1.675056,-1.69472 2.868413,-2.240646 4.129509,-1.889136 1.315159,0.36658 1.434966,1.47369 0.430457,3.9777656 -1.570004,3.913776 -6.262704,17.488484 6.345223,16.335655 13.109711,0.796384 9.062581,-8.997112 6.035071,-17.0794656 -0.42669,-1.024622 -0.49403,-2.193143 -0.15373,-2.667268 0.3508,-0.488744 1.34941,-0.793015 2.07697,-0.632834 3.80305,0.8373 16.61714,11.9119016 13.84208,25.4626826 -2.43658,11.898005 -11.79582,17.058165 -21.511689,17.025275 -9.822782,-0.0332 -20.001466,-5.3911 -22.165764,-17.530082 z"
                            }
                        }
                    }

                    EyeSet {
                        isLeft: true
                    }

                    EyeSet {
                        isLeft: false
                    }
                }

                // Final form, drawn beside the base mask in the SVG; moved over it and grown from its height
                Item {
                    opacity: root.boss
                    visible: opacity > 0.01
                    transform: [
                        Translate {
                            x: -54.67
                            y: -14.64
                        },
                        Scale {
                            origin.x: 32.08
                            origin.y: 48.88
                            yScale: 0.76 + root.boss * 0.24
                        }
                    ]

                    Shape {
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            fillColor: root.maskColour
                            strokeColor: root.rimColour
                            strokeWidth: 0.8
                            joinStyle: ShapePath.RoundJoin

                            PathSvg {
                                path: "M 64.871025,40.294499 C 63.330075,28.84634 67.479316,21.033795 75.842898,9.8255042 c 1.675056,-2.2448085 2.868413,-2.9679364 4.129509,-2.5023299 1.315159,0.485568 1.434966,1.9520344 0.430457,5.2689067 -1.570004,5.184147 -6.262704,23.165064 6.345223,21.638039 13.109714,1.054882 9.062581,-11.917481 6.035071,-22.623283 -0.42669,-1.357204 -0.49403,-2.905014 -0.15373,-3.533035 0.3508,-0.6473853 1.34941,-1.0504195 2.07697,-0.8382454 C 98.509448,8.3446355 111.32354,23.013938 108.54848,40.963161 106.1119,56.723135 96.752658,63.558229 87.036789,63.514663 77.214007,63.470687 67.035323,56.373668 64.871025,40.294499 Z"
                            }
                        }
                    }

                    FinalEye {
                        isLeft: true
                    }

                    FinalEye {
                        isLeft: false
                    }
                }

                Repeater {
                    model: 4

                    Oval {
                        required property int index
                        readonly property real t: (root.dripTime + (index % 2) / 2) % 1

                        x: (index < 2 ? 21.6 : 42.3) + root.smoothLookX * 1.2
                        y: 46 + t * 8
                        rx: 0.8
                        ry: 1.2
                        fill: Hallownest.soul
                        opacity: root.tears * Math.min(1, (1 - t) * 1.6)
                        visible: opacity > 0.01
                    }
                }

                Repeater {
                    model: 3

                    StyledText {
                        required property int index
                        readonly property real t: (root.zProgress + index / 3) % 1

                        x: 50 + t * 7
                        y: 14 - t * 14
                        visible: root.dozing && root.running
                        opacity: Math.min(1, t * 4, (1 - t) * 2)
                        text: "z"
                        color: Hallownest.steel
                        font.family: Hallownest.serif
                        font.pointSize: 5 + t * 4
                        font.bold: true
                    }
                }

                StyledText {
                    x: 52
                    y: 4
                    opacity: root.question
                    visible: opacity > 0
                    text: "?"
                    color: root.cloak
                    font.family: Hallownest.serif
                    font.pointSize: 10
                    font.bold: true
                }

                Shape {
                    preferredRendererType: Shape.CurveRenderer
                    opacity: root.anger
                    visible: opacity > 0
                    transform: Translate {
                        x: root.shake * -0.5
                    }

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: root.cloak
                        strokeWidth: 1
                        capStyle: ShapePath.RoundCap

                        PathSvg {
                            path: root.angerPath(55, 18, 0.9 + root.angerBeat * 0.3) + " " + root.angerPath(8, 24, 0.7 + root.angerBeat * 0.25)
                        }
                    }
                }

                // Speed lines trailing behind a dash
                Shape {
                    preferredRendererType: Shape.CurveRenderer
                    opacity: root.speed
                    visible: opacity > 0.01
                    // Mirrored to trail on the right while dashing left
                    transform: Scale {
                        origin.x: 32.08
                        xScale: root.dash < 0 ? -1 : 1
                    }

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: root.threadColour
                        strokeWidth: 0.7
                        capStyle: ShapePath.RoundCap

                        PathSvg {
                            path: "M 0 24 L 7 24 M -3 32 L 6 32 M 1 40 L 7 40"
                        }
                    }
                }
            }
        }

        // Outside the body so they keep rising while she unravels
        Item {
            x: -root.originX
            y: -root.originY

            Repeater {
                model: 7

                Thread {
                    required property int index
                    readonly property real t: (root.threadTime + index / 7) % 1
                    readonly property var spots: [6, 58, 14, 50, 32, 1, 63]

                    x: spots[index] + Math.sin((t + index) * 6.28) * 1.5
                    y: 52 - t * 34
                    scale: (index % 2 === 0 ? 1 : 0.75) * (1 - t * 0.4)
                    opacity: root.threads * Math.min(1, t * 5, (1 - t) * 2)
                    visible: opacity > 0.01
                }
            }
        }
    }

    SoulParticles {
        anchors.fill: parent
        anchors.margins: -4
        count: 8
        size: 2.5
        colour: root.voidness > root.soulness ? "#5a606e" : Hallownest.soul
        opacity: Math.max(root.soulness, root.voidness)
        visible: opacity > 0.01
        running: visible && root.running
        duration: 2200
    }

    component EyeSet: Item {
        id: eyeSet

        required property bool isLeft
        readonly property real cx: isLeft ? 21.63 : 42.26
        readonly property real cy: isLeft ? 39.02 : 39.2
        readonly property real open: Math.max(0.05, root.lid * root.blink * root.widen * (1 - root.anger * 0.25))

        transform: [
            Scale {
                origin.x: eyeSet.cx
                origin.y: eyeSet.cy
                xScale: 1 + (root.widen - 1) * 0.35
                yScale: eyeSet.open
            },
            Rotation {
                origin.x: eyeSet.cx
                origin.y: eyeSet.cy
                angle: (eyeSet.isLeft ? 1 : -1) * root.anger * 22
            },
            Translate {
                x: root.smoothLookX * 1.6
                y: root.smoothLookY * 1.2
            }
        ]

        Feature {
            shown: root.expression === "open"

            ShapePath {
                fillColor: root.eyeColour
                strokeWidth: -1

                PathSvg {
                    path: eyeSet.isLeft ? "m 27.37391,45.409986 c 0.58643,-0.284424 1.04494,-1.164093 1.04494,-2.00479 0,-1.01595 -0.952395,-3.317558 -1.923797,-4.649154 -2.172,-2.977347 -6.770435,-5.923487 -9.782118,-6.267236 -0.844553,-0.09635 -1.075817,-0.05172 -1.481163,0.285768 -0.42388,0.352977 -0.463044,0.522423 -0.333215,1.441595 0.743651,5.264895 6.672643,11.407265 10.990425,11.385966 0.604973,-0.0023 1.273186,-0.08939 1.484928,-0.192149 z" : "m 35.998059,45.41507 c -0.638582,-0.276901 -1.137871,-1.133304 -1.137871,-1.951764 0,-0.989076 1.037092,-3.229809 2.094882,-4.526184 2.365138,-2.898595 7.372496,-5.766808 10.651998,-6.101466 0.919656,-0.09381 1.171484,-0.05034 1.612877,0.27821 0.461574,0.343641 0.50422,0.508604 0.362846,1.403464 -0.809781,5.125637 -7.266018,11.105541 -11.967768,11.084805 -0.658763,-0.0023 -1.386397,-0.08703 -1.616964,-0.187065 z"
                }
            }
        }

        Feature {
            shown: root.expression === "happy"
            transform: Translate {
                x: eyeSet.isLeft ? 3.54 : -5.1
                y: eyeSet.isLeft ? -19.35 : -17.05
            }

            ShapePath {
                fillColor: root.eyeColour
                strokeWidth: -1

                PathSvg {
                    path: eyeSet.isLeft ? "m 23.137702,64.955337 c 0.457727,-0.293653 0.815611,-1.201865 0.815611,-2.069838 0,-1.048912 -1.182756,-6.048133 -1.615497,-7.584621 -0.967893,-3.436589 -3.250017,-3.839283 -4.59177,-3.403713 -2.136804,0.30834 -5.64885,6.12038 -5.506612,7.607503 0.244801,2.559428 2.084223,-0.555658 4.911,-2.627469 0.580309,-0.425323 2.158822,-0.885335 2.874286,0.729914 1.198565,2.705909 2.345631,7.854383 3.112982,7.348224 z" : "m 41.919668,62.602383 c -0.493982,-0.283358 -0.88021,-1.159729 -0.88021,-1.997273 0,-1.012139 1.276433,-5.836096 1.743447,-7.318717 1.044551,-3.316108 3.50742,-3.704684 4.95544,-3.284384 2.30604,0.29753 6.096243,5.905809 5.942749,7.340797 -0.264199,2.469698 -2.249307,-0.536178 -5.299964,-2.535354 -0.62627,-0.410412 -2.329801,-0.854297 -3.101931,0.704324 -1.293491,2.611043 -2.531406,7.579021 -3.359531,7.090607 z"
                }
            }
        }

        Feature {
            shown: root.expression === "sad"
            transform: Translate {
                x: eyeSet.isLeft ? -0.73 : 1.11
                y: eyeSet.isLeft ? -55.8 : -55.2
            }

            ShapePath {
                fillColor: root.eyeColour
                strokeWidth: -1

                PathSvg {
                    path: eyeSet.isLeft ? "m 26.177096,87.341215 c -0.225079,1.036926 -2.079744,4.198701 -3.175567,5.167527 -2.450175,2.166219 -6.084988,1.3848 -6.202435,4.05868 -0.03287,0.74982 0.322662,1.944796 0.639438,2.271237 0.331312,0.34136 0.480501,0.360976 1.269336,0.1669 4.518259,-1.111641 9.486286,-6.851894 9.209094,-10.640573 0.06895,-2.886676 -1.553904,-1.880488 -1.739866,-1.023771 z" : "m 37.094553,87.090629 c 0.239155,0.998978 2.209796,4.045042 3.374145,4.978412 2.603391,2.086942 6.4655,1.334121 6.59029,3.910145 0.03493,0.722379 -0.342838,1.873623 -0.679423,2.188117 -0.35203,0.328867 -0.510549,0.347765 -1.348712,0.160792 -4.800798,-1.070958 -10.07949,-6.601136 -9.784965,-10.251161 -0.07327,-2.781033 1.651074,-1.811668 1.848665,-0.986305 z"
                }
            }
        }
    }

    // Three slashes per eye; the left one is the right one mirrored, as in the drawing
    component FinalEye: Shape {
        id: finalEye

        required property bool isLeft
        readonly property real cx: isLeft ? 75.85 : 97.55
        readonly property real cy: isLeft ? 49.54 : 49.48

        preferredRendererType: Shape.CurveRenderer
        transform: [
            Scale {
                xScale: finalEye.isLeft ? -1 : 1
            },
            Translate {
                x: finalEye.isLeft ? 176.29053 : -2.8868756
                y: finalEye.isLeft ? 11.949 : 11.889287
            },
            Scale {
                origin.x: finalEye.cx
                origin.y: finalEye.cy
                yScale: Math.max(0.05, root.lid * root.blink)
            },
            Translate {
                x: root.smoothLookX * 1.6
                y: root.smoothLookY * 1.2
            }
        ]

        ShapePath {
            fillColor: root.eyeColour
            strokeWidth: -1

            PathSvg {
                path: "M 95.1986,39.825027 c -0.339549,-0.327499 -0.474345,-1.115505 -0.307191,-1.795883 0.202,-0.82221 1.302918,-2.526865 2.223806,-3.443331 2.059037,-2.04915 5.750795,-3.670392 7.853365,-3.448823 0.58961,0.06217 0.73693,0.136668 0.94362,0.47706 0.21613,0.356005 0.20889,0.499636 -0.0616,1.221981 -1.54911,4.137488 -6.77509,8.124653 -9.68727,7.390912 -0.408141,-0.102331 -0.842183,-0.283622 -0.96477,-0.401916 z M 95.539835,32.364548 c -0.153776,-0.166858 -0.214823,-0.568341 -0.139122,-0.914989 0.09148,-0.418909 0.590068,-1.287418 1.007121,-1.75435 0.9325,-1.044026 2.604427,-1.870037 3.556637,-1.757149 0.267029,0.03167 0.333749,0.06963 0.427349,0.243058 0.0979,0.181382 0.0946,0.254561 -0.0279,0.62259 -0.701559,2.108018 -3.068306,4.139448 -4.387179,3.765613 -0.18484,-0.05214 -0.381409,-0.144503 -0.436927,-0.204773 z M 95.684649,46.871563 c -0.247901,-0.254481 -0.346314,-0.866795 -0.224277,-1.395477 0.147478,-0.638891 0.951245,-1.96348 1.623575,-2.675612 1.503275,-1.592276 4.198583,-2.852049 5.733653,-2.679881 0.43046,0.04831 0.53802,0.106197 0.68892,0.370696 0.1578,0.276631 0.15251,0.388238 -0.045,0.949531 -1.13099,3.215001 -4.946418,6.313196 -7.072563,5.743048 -0.297979,-0.07952 -0.614868,-0.220386 -0.704368,-0.312305 z"
            }
        }
    }

    // A curl of silk rising from below
    component Thread: Shape {
        width: 0
        height: 0
        preferredRendererType: Shape.CurveRenderer
        transformOrigin: Item.TopLeft

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.threadColour
            strokeWidth: 0.6
            capStyle: ShapePath.RoundCap

            PathSvg {
                path: "M 0 0 C 2.5 -3, -2.5 -6, 0 -9 C 1.5 -11, -1 -12, 0.5 -14"
            }
        }
    }

    component Feature: Shape {
        property bool shown

        preferredRendererType: Shape.CurveRenderer
        opacity: shown ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
            }
        }
    }

    component Oval: Shape {
        id: oval

        required property real rx
        required property real ry
        required property color fill

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: oval.fill
            strokeWidth: -1

            PathAngleArc {
                centerX: 0
                centerY: 0
                radiusX: oval.rx
                radiusY: oval.ry
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    component To: NumberAnimation {
        target: root
        easing.type: Easing.InOutSine
    }

    component Shake: SequentialAnimation {
        id: shakeAnim

        property real amount: 1
        property int times: 4

        SequentialAnimation {
            loops: shakeAnim.times

            To {
                property: "shake"
                to: shakeAnim.amount
                duration: 45
            }
            To {
                property: "shake"
                to: -shakeAnim.amount
                duration: 90
            }
        }
        To {
            property: "shake"
            to: 0
            duration: 45
        }
    }

    component Bounce: SequentialAnimation {
        id: bounce

        property real height: 1
        property real lean

        To {
            property: "squash"
            to: 0.6
            duration: 100
            easing.type: Easing.OutQuad
        }
        ParallelAnimation {
            To {
                property: "squash"
                to: -0.7
                duration: 150
                easing.type: Easing.OutQuad
            }
            To {
                property: "hop"
                to: bounce.height
                duration: 190
                easing.type: Easing.OutQuad
            }
            To {
                property: "tilt"
                to: bounce.lean
                duration: 190
                easing.type: Easing.OutQuad
            }
        }
        ParallelAnimation {
            To {
                property: "squash"
                to: 0
                duration: 180
            }
            To {
                property: "hop"
                to: 0
                duration: 220
                easing.type: Easing.InQuad
            }
        }
        To {
            property: "squash"
            to: 0.45
            duration: 80
        }
    }
}
