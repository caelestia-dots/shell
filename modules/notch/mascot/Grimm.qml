pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.components
import qs.components.hallownest
import qs.services

// Troupe Master Grimm, the notch mascot during the Grimm season (~/Pictures/InkScape/grimm.svg, page coordinates).
// Same interface as Knight; "boss" turns him into the Nightmare King.
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
    readonly property color scarlet: Hallownest.isMono ? "#84868e" : "#c64153"
    readonly property color crimson: Hallownest.isMono ? "#4a4c54" : "#811334"
    readonly property color headColour: Qt.tint(Qt.tint("black", Qt.alpha(scarlet, boss)), Qt.alpha(Hallownest.soul, soulness * 0.3))
    readonly property color rimColour: Qt.tint(Qt.tint(scarlet, Qt.alpha("black", boss)), Qt.alpha(Hallownest.soul, Math.max(soulness, voidness)))
    readonly property color faceColour: Qt.tint(Qt.tint(Hallownest.isMono ? "#e6e7ea" : "#e5ecf3", Qt.rgba(1, 1, 1, soulness * 0.7)), Qt.rgba(0.03, 0.03, 0.045, voidness))
    readonly property color eyeColour: Qt.tint(Qt.tint(Qt.tint("black", Qt.alpha(Hallownest.infection, infect)), Qt.rgba(0.66, 0.74, 0.84, soulness)), Qt.rgba(0.95, 0.97, 0.98, voidness))
    readonly property color whiskerColour: Qt.tint(Hallownest.light ? "black" : scarlet, Qt.alpha(crimson, boss))
    readonly property color whiskerRim: Qt.tint("black", Qt.alpha(scarlet, boss))

    readonly property real originX: 14
    readonly property real originY: 8
    readonly property real canvasWidth: 96
    readonly property real canvasHeight: 81
    readonly property real ratio: size / canvasHeight
    readonly property bool reacting: celebrateAnim.running || vibeAnim.running || sadAnim.running || cryAnim.running || infectAnim.running || angryAnim.running || shockedAnim.running || soulAnim.running || voidAnim.running || bossAnim.running
    readonly property bool acting: blink2Anim.running || lookAnim.running || tiltAnim.running || hopAnim.running || confusedAnim.running || sighAnim.running || stareAnim.running || bowAnim.running || teleportAnim.running
    readonly property bool busy: wakeAnim.running || leaveAnim.running || flareAnim.running || acting || reacting

    readonly property var reactionNames: ["happy", "vibe", "sad", "cry", "infected", "angry", "shocked", "soul", "void", "boss"]
    readonly property var actionNames: ["look", "tilt", "hop", "confused", "sigh", "stare", "bow", "teleport"]

    // open, happy, sad, red
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
    property real whisker
    property real tears
    property real dripTime
    property real infect
    property real shake
    property real anger
    property real angerBeat
    property real question
    property real bow
    property real vanish
    property real flames
    property real flameTime
    property real boss
    // Set for the whole transformation so the notch can grow before the bigger head appears
    property bool bossShown

    property real idleX: 0.7
    property real idleY: -0.2
    readonly property real lookX: scanning ? scanX : tracking ? targetX : idleX
    readonly property real lookY: scanning ? scanY : tracking ? targetY : idleY
    property real smoothLookX: lookX
    property real smoothLookY: lookY

    signal woke

    function allAnims(): var {
        return [celebrateAnim, vibeAnim, sadAnim, cryAnim, infectAnim, angryAnim, shockedAnim, soulAnim, voidAnim, bossAnim, blink2Anim, lookAnim, tiltAnim, hopAnim, confusedAnim, sighAnim, stareAnim, bowAnim, teleportAnim];
    }

    function resetFace(): void {
        for (const anim of allAnims())
            anim.stop();
        expression = "open";
        scanning = false;
        scanX = 0;
        scanY = 0;
        droop = 0;
        whisker = 0;
        tears = 0;
        infect = 0;
        shake = 0;
        anger = 0;
        angerBeat = 0;
        question = 0;
        bow = 0;
        vanish = 0;
        flames = 0;
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
            bow: bowAnim,
            teleport: teleportAnim
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
        const actions = ["blink2", "look", "tilt", "tilt", "happy", "hop", "confused", "sigh", "stare", "bow", "bow", "teleport", "void"];
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
        property: "flameTime"
        running: root.running && root.flames > 0.01
        loops: Animation.Infinite
        from: 0
        to: 1
        duration: 2400
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

    // Grimm's theatrical bow
    SequentialAnimation {
        id: bowAnim

        ScriptAction {
            script: root.expression = "happy"
        }
        To {
            property: "bow"
            to: 1
            duration: 650
        }
        PauseAnimation {
            duration: 700
        }
        To {
            property: "bow"
            to: 0
            duration: 550
        }
        ScriptAction {
            script: root.expression = "open"
        }
    }

    SequentialAnimation {
        id: teleportAnim

        Vanish {}
        PauseAnimation {
            duration: 450
        }
        ScriptAction {
            script: {
                root.idleX = -root.idleX;
                root.tilt = 0;
            }
        }
        To {
            property: "vanish"
            to: 0
            duration: 300
        }
        To {
            property: "flames"
            to: 0
            duration: 500
        }
    }

    SequentialAnimation {
        id: celebrateAnim

        ScriptAction {
            script: root.expression = "happy"
        }
        To {
            property: "flames"
            to: 0.6
            duration: 300
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
        To {
            property: "flames"
            to: 0
            duration: 600
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
                property: "whisker"
                to: 0.7
                duration: 320
            }
            To {
                property: "whisker"
                to: -0.3
                duration: 330
            }
        }
        To {
            property: "whisker"
            to: 0
            duration: 250
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
        ParallelAnimation {
            To {
                property: "droop"
                to: 1
                duration: 800
            }
            To {
                property: "whisker"
                to: -1
                duration: 800
            }
        }
        PauseAnimation {
            duration: 2600
        }
        ParallelAnimation {
            To {
                property: "droop"
                to: 0
                duration: 700
            }
            To {
                property: "whisker"
                to: 0
                duration: 700
            }
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
                property: "whisker"
                to: -1
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
                property: "whisker"
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

        ScriptAction {
            script: root.expression = "red"
        }
        ParallelAnimation {
            To {
                property: "whisker"
                to: 1
                duration: 250
            }
            To {
                property: "anger"
                to: 1
                duration: 250
            }
        }
        Shake {
            amount: 1.6
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
        ParallelAnimation {
            To {
                property: "whisker"
                to: 0
                duration: 400
            }
            To {
                property: "anger"
                to: 0
                duration: 400
            }
        }
        ScriptAction {
            script: root.expression = "open"
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
                property: "whisker"
                to: 1.2
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
        ParallelAnimation {
            To {
                property: "widen"
                to: 1
                duration: 400
            }
            To {
                property: "whisker"
                to: 0
                duration: 400
            }
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

    // Nightmare King: the notch grows, flames rise and the head turns scarlet
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
                property: "flames"
                to: 1
                duration: 500
            }
            Shake {
                amount: 1.2
                times: 4
            }
        }
        ScriptAction {
            script: root.expression = "red"
        }
        ParallelAnimation {
            To {
                property: "boss"
                to: 1
                duration: 900
            }
            To {
                property: "whisker"
                to: 0.6
                duration: 900
            }
        }
        PauseAnimation {
            duration: 7000
        }
        Vanish {}
        ScriptAction {
            script: {
                root.boss = 0;
                root.whisker = 0;
                root.expression = "open";
                root.bossShown = false;
            }
        }
        PauseAnimation {
            duration: 350
        }
        To {
            property: "vanish"
            to: 0
            duration: 300
        }
        To {
            property: "flames"
            to: 0
            duration: 500
        }
    }

    SequentialAnimation {
        id: wakeAnim

        property bool startle

        ScriptAction {
            script: {
                root.nod = 0;
                root.widen = wakeAnim.startle ? 1.3 : 1;
                root.whisker = wakeAnim.startle ? 1 : 0;
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
            To {
                property: "whisker"
                to: 0
                duration: 300
            }
        }
        ScriptAction {
            script: root.woke()
        }
    }

    // The Nightmare King (or a half-done teleport) leaves the way he came: in a burst of flame
    SequentialAnimation {
        id: flareAnim

        Vanish {}
        ScriptAction {
            script: root.woke()
        }
    }

    // A bow, then he vanishes in flames
    SequentialAnimation {
        id: leaveAnim

        ScriptAction {
            script: root.expression = "happy"
        }
        To {
            property: "bow"
            to: 1
            duration: 550
        }
        PauseAnimation {
            duration: 350
        }
        Vanish {}
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

            readonly property real pivotX: 62 - root.originX
            // Room above the head for the soul glow and the Nightmare King's bigger head
            readonly property real headroom: 30
            readonly property real pivotY: 87 - root.originY + headroom

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
                    xScale: (1 + root.squash * 0.12 - root.breath * 0.012 + root.boss * 0.22) * (1 - root.vanish * 0.4)
                    yScale: (1 - root.squash * 0.14 + root.breath * 0.02 - root.bow * 0.12 + root.boss * 0.22) * (1 + root.vanish * 0.3)
                },
                Rotation {
                    origin.x: body.pivotX
                    origin.y: body.pivotY
                    angle: root.tilt + root.nod * 7 + root.sway * 5 - root.bow * 16 - root.droop * 5
                },
                Translate {
                    x: root.shake
                    y: -root.hop * 9 + (root.dozing ? 2 : 0) + root.bow * 5 + root.droop * 3
                }
            ]

            Item {
                x: -root.originX
                y: -root.originY + body.headroom

                Whiskers {
                    isLeft: true
                }

                Whiskers {
                    isLeft: false
                }

                Shape {
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        fillColor: root.headColour
                        strokeColor: root.rimColour
                        strokeWidth: 1.1
                        joinStyle: ShapePath.RoundJoin

                        PathSvg {
                            path: "m 47.988381,11.219605 -0.72968,0.377238 c -1.37971,0.713475 -4.61871,3.483674 -6.20685,5.30872 -7.17824,8.249042 -12.155382,18.105562 -14.35003,28.418422 -0.621202,2.91907 -0.705102,3.91291 -0.715202,8.46667 -0.009,4.05418 0.09254,5.63232 0.473356,7.36699 2.071306,9.43508 7.132406,16.60557 15.782496,22.35936 h 5.2e-4 c 1.47878,0.98361 2.39588,1.53277 2.43448,1.48363 0.0146,-0.0291 -0.20629,-0.21955 -0.70797,-0.59273 -7.24382,-5.38841 -11.50678,-12.86216 -11.51248,-20.18378 -0.002,-2.61508 0.37589,-5.13903 0.92915,-6.20892 0.49741,-0.96189 3.32511,-2.26589 6.09523,-2.81017 2.83765,-0.55755 5.47899,-0.26277 8.31216,0.9276 4.67845,1.96568 9.30576,6.77743 13.09739,13.61879 l 1.00097,1.80558 1.03663,-1.911 c 2.54803,-4.69586 6.51128,-9.50686 9.53533,-11.57499 4.01585,-2.7464 8.07666,-3.70509 12.08971,-2.85461 2.41045,0.51084 5.13879,1.75504 5.66735,2.58486 1.15726,1.81687 1.40274,7.85894 0.46612,11.4675 -1.35522,5.22136 -4.7476,10.08957 -10.20971,14.65132 -0.45564,0.38053 -0.67449,0.57852 -0.67076,0.61598 l 0.003,0.004 c 0.0245,0.0108 0.16102,-0.0578 0.40308,-0.19844 3.72803,-2.16633 9.23642,-7.14808 11.54813,-10.44382 2.81918,-4.0192 4.80441,-8.80551 5.6379,-13.59451 0.85441,-4.90921 0.42022,-12.28792 -1.05265,-17.88831 -3.17089,-12.05698 -11.55664,-25.390945 -18.98954,-30.195061 -0.86708,-0.560423 -1.61408,-0.984305 -1.67432,-0.951363 l -0.002,0.002 c -0.0444,0.04435 0.0369,1.801411 0.18035,3.904154 0.5224,7.655666 -0.54211,14.879616 -2.90059,19.688206 -2.70018,5.50526 -6.38834,7.80312 -12.01219,7.48326 -3.07501,-0.17489 -5.56669,-1.34038 -7.583,-3.54655 -3.7577,-4.11151 -5.3901,-10.614703 -5.3821,-21.442103 z"
                        }
                    }

                    ShapePath {
                        fillColor: root.faceColour
                        strokeWidth: -1

                        PathSvg {
                            path: "m 81.536108,54.917578 c -3.023351,0.03957 -6.060427,1.093496 -9.072314,3.153296 -3.02405,2.06813 -6.987305,6.879144 -9.535335,11.575004 l -1.03663,1.910995 -1.000972,-1.805575 c -3.79163,-6.84136 -8.418942,-11.653127 -13.097392,-13.618807 -2.83317,-1.19037 -5.474504,-1.485142 -8.312154,-0.927592 -2.77012,0.54428 -5.597825,1.848274 -6.095235,2.810164 -0.55326,1.06989 -0.931142,3.593844 -0.929142,6.208924 0.0045,5.824801 2.703493,11.745961 7.454325,16.63671 0.362425,0.373099 0.736908,0.740102 1.122929,1.100708 0.9143,0.854105 1.89394,1.671792 2.935221,2.446363 0.489922,0.364433 0.711938,0.554846 0.708484,0.590661 l 0.132,0.128 c 8.089082,2.097976 12.191463,2.329403 17.519861,2.586923 12.004721,-0.970992 14.68873,-2.152048 17.500223,-3.219442 0.06777,-0.0815 0.280942,-0.269453 0.646989,-0.575159 5.46211,-4.56175 8.854493,-9.429942 10.209713,-14.651302 0.93662,-3.60856 0.691139,-9.650647 -0.466121,-11.467517 -0.52856,-0.82982 -3.256905,-2.074015 -5.667355,-2.584855 -1.003262,-0.21262 -2.009603,-0.311881 -3.017387,-0.29869 z"
                        }
                    }
                }

                EyeSet {
                    isLeft: true
                }

                EyeSet {
                    isLeft: false
                }

                Repeater {
                    model: 4

                    Oval {
                        required property int index
                        readonly property real t: (root.dripTime + (index % 2) / 2) % 1

                        x: (index < 2 ? 50 : 74) + root.smoothLookX * 1.5
                        y: 80 + t * 12
                        rx: 1.1
                        ry: 1.6
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

                        x: 96 + t * 9
                        y: 28 - t * 20
                        visible: root.dozing && root.running
                        opacity: Math.min(1, t * 4, (1 - t) * 2)
                        text: "z"
                        color: Hallownest.steel
                        font.family: Hallownest.serif
                        font.pointSize: 7 + t * 6
                        font.bold: true
                    }
                }

                StyledText {
                    x: 92
                    y: 14
                    opacity: root.question
                    visible: opacity > 0
                    text: "?"
                    color: root.scarlet
                    font.family: Hallownest.serif
                    font.pointSize: 16
                    font.bold: true
                }

                Shape {
                    preferredRendererType: Shape.CurveRenderer
                    opacity: root.anger
                    visible: opacity > 0

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: root.scarlet
                        strokeWidth: 1.4
                        capStyle: ShapePath.RoundCap

                        PathSvg {
                            path: root.angerPath(96, 22, 1.1 + root.angerBeat * 0.4) + " " + root.angerPath(26, 30, 0.8 + root.angerBeat * 0.3)
                        }
                    }
                }
            }
        }

        // Outside the body so they keep burning while he vanishes
        Item {
            x: -root.originX
            y: -root.originY

            Repeater {
                model: 7

                Flame {
                    required property int index
                    readonly property real t: (root.flameTime + index / 7) % 1
                    readonly property var spots: [20, 104, 34, 90, 62, 10, 114]

                    x: spots[index] + Math.sin((t + index) * 6.28) * 2
                    y: 92 - t * 46
                    big: index % 2 === 0
                    scale: (big ? 1.1 : 1.4) * (1 - t * 0.5)
                    opacity: root.flames * Math.min(1, t * 5, (1 - t) * 2)
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
        readonly property real cx: isLeft ? 47.6 : 77.5
        readonly property real cy: 71
        readonly property real open: Math.max(0.05, root.lid * root.blink * root.widen)

        transform: [
            Scale {
                origin.x: eyeSet.cx
                origin.y: eyeSet.cy
                xScale: 1 + (root.widen - 1) * 0.35
                yScale: eyeSet.open
            },
            Translate {
                x: root.smoothLookX * 2.2
                y: root.smoothLookY * 1.6
            }
        ]

        Feature {
            shown: root.expression === "open"

            ShapePath {
                fillColor: root.eyeColour
                strokeWidth: -1

                PathSvg {
                    path: eyeSet.isLeft ? "m 39.317776,60.851258 c -0.16327,0.16344 0.76116,6.87527 1.11776,8.11577 1.53586,5.34267 5.49567,8.92748 12.56255,11.37245 1.2241,0.4235 2.3158,0.77861 2.42621,0.78961 0.28052,0.0278 -0.0362,-2.7076 -0.53382,-4.61006 -1.21702,-4.65245 -3.99566,-8.368 -8.57054,-11.4608 -1.58942,-1.0745 -6.92756,-4.28167 -7.00216,-4.20697 z" : "m 85.143946,60.691122 c -0.19263,-0.1857 -7.49944,4.40547 -9.20771,5.78569 -3.85308,3.11314 -6.40491,7.80614 -6.80475,12.51398 l -0.16123,1.90221 1.69085,-0.52504 c 7.55666,-2.34572 11.9269,-6.19247 13.42554,-11.81686 0.49712,-1.86568 1.27525,-7.64988 1.0573,-7.85998 z"
                }
            }
        }

        Feature {
            shown: root.expression === "red"
            transform: Translate {
                x: eyeSet.isLeft ? -1.587 : -1.986
                y: eyeSet.isLeft ? -32.348 : -31.97
            }

            ShapePath {
                fillColor: root.scarlet
                strokeColor: "black"
                strokeWidth: 0.6

                PathSvg {
                    path: eyeSet.isLeft ? "m 40.904756,93.199666 c -0.16327,0.16344 0.76116,6.875274 1.11776,8.115774 1.53586,5.34267 5.49567,8.92748 12.56255,11.37245 1.2241,0.4235 2.3158,0.77861 2.42621,0.78961 0.28052,0.0278 -0.0362,-2.7076 -0.53382,-4.61006 -1.21702,-4.65245 -3.99566,-8.368 -8.57054,-11.460804 -1.58942,-1.0745 -6.92756,-4.28167 -7.00216,-4.20697 z" : "m 87.130252,92.661186 c -0.19263,-0.1857 -7.49944,4.40547 -9.20771,5.78569 -3.85308,3.113144 -6.40491,7.806144 -6.80475,12.513984 l -0.16123,1.90221 1.69085,-0.52504 c 7.55666,-2.34572 11.9269,-6.19247 13.42554,-11.81686 0.49712,-1.865684 1.27525,-7.649884 1.0573,-7.859984 z"
                }
            }

            ShapePath {
                fillColor: root.crimson
                strokeWidth: -1

                PathSvg {
                    path: eyeSet.isLeft ? "m 42.028339,95.109061 c -0.121564,0.142421 0.843768,5.733059 1.167224,6.760049 1.393113,4.42314 4.615244,7.2919 10.222242,9.10086 0.971225,0.31332 1.83658,0.57384 1.923195,0.57932 0.220061,0.0139 -0.126482,-2.26668 -0.584072,-3.84337 -1.119103,-3.85579 -3.423639,-6.87401 -7.108212,-9.309857 -1.280106,-0.846261 -5.564834,-3.352095 -5.620377,-3.287002 z" : "m 85.696105,94.908414 c 0.121564,0.142421 -0.843768,5.733056 -1.167224,6.760046 -1.393113,4.42314 -4.615244,7.2919 -10.222242,9.10086 -0.971225,0.31332 -1.83658,0.57384 -1.923195,0.57932 -0.220061,0.0139 0.126482,-2.26668 0.584072,-3.84337 1.119103,-3.85579 3.423639,-6.87401 7.108212,-9.309854 1.280106,-0.846261 5.564834,-3.352095 5.620377,-3.287002 z"
                }
            }
        }

        Feature {
            shown: root.expression === "happy"
            transform: Translate {
                x: -1.4
                y: -62.5
            }

            ShapePath {
                fillColor: root.eyeColour
                strokeWidth: -1

                PathSvg {
                    path: eyeSet.isLeft ? "m 58.551207,140.92868 c -0.69895,-0.87835 -1.78699,-2.3164 -2.27463,-2.80393 -5.23951,-4.19835 -11.16009,-6.15297 -17.01642,-4.61944 -1.16659,0.33904 -2.0142,1.27061 -2.66388,1.43445 0.55351,-2.01368 1.91968,-4.93753 3.50306,-6.79528 1.6541,-1.41494 3.85686,-2.30181 6.28875,-2.53912 3.28067,-0.0962 5.45512,1.02943 7.38562,2.56865 1.75857,1.4074 3.09969,3.43535 4.14374,5.90494 1.03829,2.57323 0.79158,4.6959 0.63376,6.84973 z" : "m 68.242137,140.32674 c 0.69895,-0.87836 1.78699,-2.3164 2.27463,-2.80393 5.23951,-4.19835 11.16009,-6.15297 17.01642,-4.61945 1.16659,0.33905 2.0142,1.27062 2.66388,1.43446 -0.55351,-2.01368 -1.91968,-4.93753 -3.50306,-6.79528 -1.6541,-1.41494 -3.85686,-2.30181 -6.28875,-2.53912 -3.28067,-0.0962 -5.45512,1.02943 -7.38562,2.56865 -1.75857,1.4074 -3.09969,3.43535 -4.14374,5.90494 -1.03829,2.57323 -0.79158,4.69589 -0.63376,6.84973 z"
                }
            }
        }

        Feature {
            shown: root.expression === "sad"
            transform: Translate {
                x: -1.2
                y: -78
            }

            ShapePath {
                fillColor: root.eyeColour
                strokeWidth: -1

                PathSvg {
                    path: eyeSet.isLeft ? "m 58.376454,144.36411 c -0.27342,0.80313 -2.41955,2.05268 -3.1718,2.37607 -4.64821,2.3248 -8.59513,3.36188 -13.55967,3.3521 -1.18915,-0.0666 -1.74695,-0.65741 -2.31043,-0.79244 0.48007,1.65957 1.66497,4.06924 3.03827,5.60029 1.43463,1.16612 3.34512,1.89703 5.45434,2.09261 2.84539,0.0793 4.73133,-0.8484 6.40568,-2.11694 1.52524,-1.1599 2.68842,-2.83123 3.59394,-4.86653 0.90053,-2.12071 0.68655,-3.87009 0.54967,-5.64516 z" : "m 68.166524,143.98576 c 0.32245,1.10224 1.67294,1.71417 2.09588,2.11596 4.64821,2.32481 9.671047,3.62199 14.635587,3.61222 1.05909,-0.0666 1.74695,-0.65741 2.31043,-0.79244 -0.48007,1.65956 -1.66497,4.06924 -3.03827,5.60029 -1.43463,1.16611 -3.34512,1.89702 -5.45434,2.0926 -2.845387,0.0793 -4.731327,-0.8484 -6.405677,-2.11694 -1.52524,-1.1599 -2.68842,-2.83122 -3.59394,-4.86652 -0.90053,-2.12072 -0.68655,-3.87009 -0.54967,-5.64517 z"
                }
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

    // The three neck spikes on one side, pivoting where they meet the head
    component Whiskers: Shape {
        id: whiskers

        required property bool isLeft

        preferredRendererType: Shape.CurveRenderer
        transform: [
            Translate {
                x: whiskers.isLeft ? 11.810841 : 10.963144
                y: whiskers.isLeft ? -25.998971 : -28.055282
            },
            Rotation {
                origin.x: whiskers.isLeft ? 36 : 88
                origin.y: 70
                angle: (whiskers.isLeft ? 1 : -1) * root.whisker * 14
            }
        ]

        ShapePath {
            fillColor: root.whiskerColour
            strokeColor: root.whiskerRim
            strokeWidth: 0.3

            PathSvg {
                path: whiskers.isLeft ? "m 22.414662,108.26657 c -1.472436,0.0852 -3.379476,0.63428 -4.578015,1.45985 -0.644776,0.4441 -0.933897,0.72678 -0.642855,0.62787 1.550116,-0.52679 3.496974,-0.91617 5.422925,-1.08417 1.98624,-0.17326 2.12491,-0.22224 1.73219,-0.61495 -0.32374,-0.32375 -1.050783,-0.43971 -1.934245,-0.3886 z m -9.718786,-11.107842 c -1.608395,0.008 -2.531068,0.170996 -3.8426596,0.676956 -1.426478,0.55027 -4.491714,2.207396 -4.491714,2.428266 0,0.0333 1.160858,-0.10553 2.579686,-0.308496 2.954887,-0.4227 7.4118296,-0.28448 9.4588536,0.292996 0.727604,0.20527 1.358085,0.38756 1.401465,0.40566 0.04338,0.0181 -0.26171,-0.592 -0.677995,-1.355986 -0.975301,-1.78992 -1.727236,-2.153596 -4.427636,-2.139396 z M 5.6952714,81.43878 l 0.531751,0.746724 c 0.857049,1.20362 3.353449,3.3035 4.9707556,4.18114 2.017053,1.09455 2.269375,1.0743 2.064473,-0.16536 -0.0902,-0.5457 -0.165315,-1.36024 -0.166915,-1.81023 -0.0029,-0.80934 -0.02518,-0.82266 -2.066023,-1.22473 C 9.8946214,82.942769 8.2304324,82.462565 7.3308304,82.099205 Z" : "m 78.089815,108.32187 c -0.56727,0.0322 -0.99881,0.15367 -1.18907,0.38292 -0.22939,0.27639 0.24805,0.40462 2.41484,0.64906 1.48551,0.16758 3.17738,0.4803 3.75946,0.69505 1.45344,0.53624 1.70445,0.50786 0.92604,-0.10439 -1.28695,-1.01221 -4.20946,-1.71913 -5.91127,-1.62264 z m 10.53011,-11.215842 c -0.68708,-0.006 -1.3456,0.062 -1.96422,0.20722 -1.36915,0.321346 -1.49128,0.419566 -2.2903,1.840706 -0.78144,1.389866 -0.80154,1.485606 -0.27337,1.287256 2.15505,-0.809316 8.2828,-0.969376 11.74192,-0.30644 1.39178,0.26673 1.25367,0.0187 -0.57102,-1.025256 -2.26388,-1.29527 -4.58176,-1.984806 -6.64301,-2.003486 z m 6.57996,-15.380961 c -0.17137,0.0016 -0.47933,0.09822 -0.78962,0.256315 -0.95432,0.48626 -3.30294,1.140622 -4.87773,1.359092 l -1.21543,0.16898 -0.0568,1.7601 c -0.0313,0.96818 -0.12052,1.86279 -0.19792,1.98799 -0.24354,0.39407 1.70584,-0.52911 3.15123,-1.49241 1.55528,-1.03655 4.35081,-3.764984 4.10724,-4.008544 -0.0218,-0.02178 -0.0638,-0.03206 -0.12092,-0.03152 z"
            }
        }
    }

    // Fire1 (big, with a lit core) or Fire3 from the drawing, anchored at the base of the flame
    component Flame: Shape {
        id: flame

        property bool big

        width: 0
        height: 0
        preferredRendererType: Shape.CurveRenderer
        transformOrigin: Item.TopLeft
        transform: Translate {
            x: flame.big ? -182.9 : -175.4
            y: flame.big ? -132.3 : -116.4
        }

        ShapePath {
            fillColor: root.crimson
            strokeColor: flame.big ? "transparent" : "black"
            strokeWidth: flame.big ? -1 : 0.4

            PathSvg {
                path: flame.big ? "m 181.02741,131.80481 c -2.5099,-1.13946 -3.58173,-3.44851 -2.86524,-6.1726 0.22125,-0.84118 0.65313,-2.02114 0.95973,-2.62212 0.5821,-1.14101 0.1685,-2.58245 -0.003,-3.53639 -0.0673,-0.37515 -0.26126,-0.38185 -0.0791,-0.38185 0.35699,0 1.55898,1.4338 1.77648,2.11908 0.21873,0.68916 0.54245,0.47285 1.18902,-0.79454 0.84552,-1.65734 0.59331,-3.5383 0.2968,-5.15168 -0.28416,-1.54622 -0.39249,-1.52788 -0.30517,-1.46453 0.45294,0.32861 2.15659,1.71163 2.67901,2.87131 0.46987,1.043 0.5258,1.51096 0.36834,3.08182 -0.2444,2.43814 -0.20828,3.28829 0.15845,3.73019 0.42521,0.51234 0.77216,0.2096 0.77216,-0.67379 0,-0.41185 0.2206,-1.02126 0.49023,-1.35423 l 0.49023,-0.60541 -0.12268,0.83586 c -0.0877,0.5974 0.12048,1.30308 0.72968,2.47362 0.68691,1.31986 0.82775,1.85612 0.72556,2.76276 -0.16489,1.4629 -1.40243,3.45657 -2.8174,4.53881 -1.33549,1.02145 -2.7155,1.12819 -4.44351,0.34369 z" : "m 174.8481,115.75322 c -1.44364,-1.31352 -2.19976,-2.53512 -2.1973,-3.55 0.003,-1.15529 0.55914,-2.61024 1.33675,-3.49588 1.28778,-1.46671 1.26005,-2.62636 1.29311,-4.04352 0.0107,-0.45682 -0.057,-1.01507 -0.19469,-1.28243 -0.14394,-0.27952 1.52553,0.95088 1.93427,1.74131 0.43963,0.85015 0.511,2.61961 0.15564,3.85869 -0.32981,1.14996 0.59456,2.13522 1.05342,1.32884 0.40282,-0.7079 0.13368,-0.85632 0.65126,0.7806 0.26828,0.84846 -6.7e-4,1.34942 -0.94445,3.14977 -1.5825,3.01881 -1.48506,2.97108 -3.08801,1.51262 z"
            }
        }

        ShapePath {
            fillColor: flame.big ? root.scarlet : "transparent"
            strokeWidth: -1

            PathSvg {
                path: flame.big ? "m 183.08392,124.11904 c -0.47397,0 -1.82171,1.92009 -2.13631,3.04374 -0.1749,0.62467 -0.23979,1.4904 -0.14469,1.9234 0.41009,1.86715 2.89069,2.83968 4.03334,1.5813 0.77565,-0.85422 0.9483,-1.89099 0.49558,-2.9745 -0.39536,-0.94622 -0.81126,-1.19177 -1.01131,-0.59738 -0.0868,0.25784 -0.20844,0.25055 -0.55139,-0.0326 -0.30038,-0.24797 -0.43976,-0.77241 -0.43976,-1.65365 0,-0.70979 -0.11053,-1.29036 -0.24546,-1.29036 z" : ""
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

    // He vanishes into a burst of flame (Grimm's teleport)
    component Vanish: SequentialAnimation {
        To {
            property: "flames"
            to: 1
            duration: 250
        }
        To {
            property: "vanish"
            to: 1
            duration: 320
            easing.type: Easing.InQuad
        }
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
