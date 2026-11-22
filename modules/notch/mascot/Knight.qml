pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.components
import qs.components.hallownest
import qs.services

Item {
    id: root

    property bool dozing
    property bool running
    property bool music
    property bool tracking
    property real targetX
    property real targetY
    property real size: 40
    property color boneColour: Hallownest.isMono ? "#e4e5e8" : "#daebeb"
    property real voidness
    property real soulness
    readonly property color headColour: Qt.tint(Qt.tint(boneColour, Qt.rgba(1, 1, 1, soulness * 0.7)), Qt.rgba(0.03, 0.03, 0.045, voidness))
    readonly property color eyeColour: Qt.tint(Qt.tint("black", Qt.rgba(0.66, 0.74, 0.84, soulness)), Qt.rgba(0.95, 0.97, 0.98, voidness))
    readonly property color rimColour: Qt.tint(Qt.tint("#4d4d4d", Qt.rgba(0.8, 0.86, 0.92, soulness)), Qt.rgba(0.08, 0.08, 0.1, voidness))
    readonly property color lidColour: "#8c919b"

    readonly property real originX: 100
    readonly property real originY: 32
    readonly property real canvasWidth: 90
    readonly property real canvasHeight: 74
    readonly property real ratio: size / canvasHeight
    readonly property bool reacting: celebrateAnim.running || vibeAnim.running || sadAnim.running || cryAnim.running || infectAnim.running || angryAnim.running || shockedAnim.running || soulAnim.running || voidAnim.running || bossAnim.running || rageAnim.running
    readonly property bool busy: wakeAnim.running || leaveAnim.running || actionAnim.running || reacting

    readonly property var reactionNames: ["happy", "vibe", "sad", "cry", "infected", "angry", "shocked", "soul", "void", "boss"]
    readonly property var actionNames: ["look", "tilt", "hop", "confused", "sigh", "stare"]

    property string expression: "open"
    property real breath
    property real nod
    property real sway
    property real tilt
    property real hop
    property real squash
    property real blink: 1
    property real lid: dozing && !reacting ? 0.1 : 1
    readonly property bool closed: lid < 0.5
    property real widen: 1
    property real spin
    property real zProgress
    property bool scanning
    property real scanX
    property real scanY
    property real droop
    property real sadTilt
    property real tears
    property real stream
    property real drip
    property real glow
    property real shake
    property real lidShade
    property real anger
    property real angerBeat
    property real shock
    property real boss
    // Set for the whole transformation so the notch can grow before the bigger head appears
    property bool bossShown
    property real bossInfection

    property real idleX: 0.7
    property real idleY: -0.2
    readonly property real lookX: scanning ? scanX : tracking ? targetX : idleX
    readonly property real lookY: scanning ? scanY : tracking ? targetY : idleY
    property real smoothLookX: lookX
    property real smoothLookY: lookY

    signal woke

    function resetFace(): void {
        for (const anim of [celebrateAnim, vibeAnim, sadAnim, cryAnim, infectAnim, angryAnim, shockedAnim, soulAnim, voidAnim, stareAnim, sighAnim, bossAnim, rageAnim])
            anim.stop();
        expression = "open";
        scanning = false;
        scanY = 0;
        droop = 0;
        sadTilt = 0;
        tears = 0;
        stream = 0;
        drip = 0;
        glow = 0;
        shake = 0;
        lidShade = 0;
        anger = 0;
        angerBeat = 0;
        shock = 0;
        soulness = 0;
        voidness = 0;
        boss = 0;
        bossInfection = 0;
        bossShown = false;
        tilt = 0;
        hop = 0;
        squash = 0;
    }

    function wake(): void {
        // Disturbing the Hollow Knight infects it before it turns back and leaves
        if (bossAnim.running || rageAnim.running) {
            if (bossAnim.running) {
                bossAnim.stop();
                rageAnim.restart();
            }
            return;
        }
        if (wakeAnim.running || leaveAnim.running)
            return;
        const startle = closed;
        actionAnim.stop();
        resetFace();
        wakeAnim.startle = startle;
        wakeAnim.restart();
    }

    function leave(): void {
        if (wakeAnim.running || leaveAnim.running)
            return;
        actionAnim.stop();
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
        if (!anims[name] || wakeAnim.running || leaveAnim.running || bossAnim.running || rageAnim.running)
            return;
        actionAnim.stop();
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
        const actions = ["blink2", "look", "tilt", "tilt", "happy", "hop", "confused", "sigh", "stare", "stare", "void"];
        const action = actions[Math.floor(Math.random() * actions.length)];
        actionAnim.action = action;
        actionAnim.restart();
    }

    function surprise(): void {
        const all = reactionNames.concat(actionNames);
        play(all[Math.floor(Math.random() * all.length)]);
    }

    function play(name: string): void {
        if (reactionNames.includes(name)) {
            react(name);
        } else if (actionNames.includes(name) && !wakeAnim.running && !leaveAnim.running && !bossAnim.running && !rageAnim.running) {
            resetFace();
            actionAnim.action = name;
            actionAnim.restart();
        }
    }

    implicitWidth: canvasWidth * ratio
    implicitHeight: size

    onDozingChanged: {
        if (dozing && running && !boss) {
            actionAnim.action = "yawn";
            actionAnim.restart();
        }
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

        NumberAnimation {
            target: root
            property: "breath"
            to: 1
            duration: root.dozing ? 2800 : 1900
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "breath"
            to: 0
            duration: root.dozing ? 2800 : 1900
            easing.type: Easing.InOutSine
        }
    }

    SequentialAnimation {
        running: root.running && root.dozing && !root.busy
        loops: Animation.Infinite

        onRunningChanged: {
            if (!running)
                root.nod = 0;
        }

        NumberAnimation {
            target: root
            property: "nod"
            to: 1
            duration: 2800
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "nod"
            to: -0.3
            duration: 2800
            easing.type: Easing.InOutSine
        }
    }

    SequentialAnimation {
        running: root.running && root.music && !root.dozing && !groove.locked
        loops: Animation.Infinite

        onRunningChanged: {
            if (!running)
                root.sway = 0;
        }

        NumberAnimation {
            target: root
            property: "sway"
            to: 1
            duration: 650
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "sway"
            to: -1
            duration: 1300
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "sway"
            to: 0
            duration: 650
            easing.type: Easing.InOutSine
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
        property: "spin"
        running: root.running && root.expression === "dizzy"
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: 900
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

        NumberAnimation {
            target: root
            property: "blink"
            to: 0.06
            duration: 70
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: root
            property: "blink"
            to: 1
            duration: 130
            easing.type: Easing.OutQuad
        }
    }

    SequentialAnimation {
        id: actionAnim

        property string action

        ScriptAction {
            script: {
                switch (actionAnim.action) {
                case "blink2":
                    blink2.start();
                    break;
                case "look":
                    look.start();
                    break;
                case "tilt":
                    tiltAnim.start();
                    break;
                case "happy":
                    happyAnim.start();
                    break;
                case "hop":
                    hopAnim.start();
                    break;
                case "confused":
                    confusedAnim.start();
                    break;
                case "yawn":
                    yawnAnim.start();
                    break;
                case "sigh":
                    sighAnim.start();
                    break;
                case "stare":
                    stareAnim.start();
                    break;
                case "void":
                    voidAnim.start();
                    break;
                }
            }
        }
        PauseAnimation {
            duration: 2600
        }
    }

    SequentialAnimation {
        id: blink2

        ScriptAction {
            script: blinkAnim.restart()
        }
        PauseAnimation {
            duration: 260
        }
        ScriptAction {
            script: blinkAnim.restart()
        }
    }

    SequentialAnimation {
        id: look

        ScriptAction {
            script: {
                root.scanX = root.smoothLookX;
                root.scanning = true;
            }
        }
        NumberAnimation {
            target: root
            property: "scanX"
            to: -1
            duration: 450
            easing.type: Easing.InOutSine
        }
        PauseAnimation {
            duration: 500
        }
        NumberAnimation {
            target: root
            property: "scanX"
            to: 1
            duration: 650
            easing.type: Easing.InOutSine
        }
        PauseAnimation {
            duration: 500
        }
        ScriptAction {
            script: root.scanning = false
        }
    }

    SequentialAnimation {
        id: tiltAnim

        NumberAnimation {
            target: root
            property: "tilt"
            to: Math.random() > 0.5 ? 9 : -9
            duration: 450
            easing.type: Easing.OutBack
        }
        PauseAnimation {
            duration: 900
        }
        NumberAnimation {
            target: root
            property: "tilt"
            to: 0
            duration: 500
            easing.type: Easing.InOutSine
        }
    }

    SequentialAnimation {
        id: happyAnim

        ScriptAction {
            script: root.expression = "happy"
        }
        ParallelAnimation {
            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "hop"
                    to: 1
                    duration: 160
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: root
                    property: "hop"
                    to: 0
                    duration: 260
                    easing.type: Easing.OutBounce
                }
            }
        }
        PauseAnimation {
            duration: 1300
        }
        ScriptAction {
            script: root.expression = "open"
        }
    }

    SequentialAnimation {
        id: hopAnim

        NumberAnimation {
            target: root
            property: "squash"
            to: 1
            duration: 120
            easing.type: Easing.OutQuad
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "squash"
                to: -0.8
                duration: 160
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "hop"
                to: 1.4
                duration: 200
                easing.type: Easing.OutQuad
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "squash"
                to: 0
                duration: 200
            }
            NumberAnimation {
                target: root
                property: "hop"
                to: 0
                duration: 220
                easing.type: Easing.InQuad
            }
        }
        NumberAnimation {
            target: root
            property: "squash"
            to: 0.7
            duration: 80
        }
        NumberAnimation {
            target: root
            property: "squash"
            to: 0
            duration: 260
            easing.type: Easing.OutBack
        }
    }

    SequentialAnimation {
        id: confusedAnim

        ScriptAction {
            script: root.expression = "dizzy"
        }
        NumberAnimation {
            target: root
            property: "tilt"
            to: -7
            duration: 300
            easing.type: Easing.OutQuad
        }
        PauseAnimation {
            duration: 1200
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "tilt"
                to: 0
                duration: 400
                easing.type: Easing.InOutSine
            }
            ScriptAction {
                script: root.expression = "open"
            }
        }
    }

    SequentialAnimation {
        id: yawnAnim

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "squash"
                to: -0.6
                duration: 900
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "widen"
                to: 0.45
                duration: 900
                easing.type: Easing.InOutSine
            }
        }
        PauseAnimation {
            duration: 500
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "squash"
                to: 0
                duration: 700
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "widen"
                to: 1
                duration: 700
                easing.type: Easing.InOutSine
            }
        }
    }

    SequentialAnimation {
        id: sighAnim

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "droop"
                to: 0.55
                duration: 450
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "squash"
                to: 0.25
                duration: 600
                easing.type: Easing.InOutSine
            }
        }
        PauseAnimation {
            duration: 900
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "droop"
                to: 0
                duration: 500
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "squash"
                to: 0
                duration: 500
                easing.type: Easing.OutBack
            }
        }
    }

    SequentialAnimation {
        id: stareAnim

        ScriptAction {
            script: {
                root.scanX = root.smoothLookX;
                root.scanY = root.smoothLookY;
                root.lidShade = 1;
                root.scanning = true;
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "scanX"
                to: 0
                duration: 300
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "scanY"
                to: 0.1
                duration: 300
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "droop"
                to: 0.9
                duration: 350
                easing.type: Easing.OutQuad
            }
        }
        PauseAnimation {
            duration: 1500
        }
        NumberAnimation {
            target: root
            property: "droop"
            to: 0
            duration: 300
            easing.type: Easing.OutQuad
        }
        ScriptAction {
            script: {
                root.scanY = 0;
                root.lidShade = 0;
                root.scanning = false;
            }
        }
    }

    SequentialAnimation {
        id: celebrateAnim

        ScriptAction {
            script: root.expression = "happy"
        }
        Bounce {
            height: 1.3
            lean: -6
        }
        Bounce {
            height: 1.1
            lean: 6
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "squash"
                to: 0
                duration: 260
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: root
                property: "tilt"
                to: 0
                duration: 300
                easing.type: Easing.InOutSine
            }
        }
        PauseAnimation {
            duration: 700
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
        Bounce {
            height: 0.6
            lean: -9
        }
        Bounce {
            height: 0.6
            lean: 9
        }
        Bounce {
            height: 0.6
            lean: -9
        }
        Bounce {
            height: 1
            lean: 4
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "squash"
                to: 0
                duration: 260
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: root
                property: "tilt"
                to: 0
                duration: 300
                easing.type: Easing.InOutSine
            }
        }
        PauseAnimation {
            duration: 400
        }
        ScriptAction {
            script: root.expression = "open"
        }
    }

    SequentialAnimation {
        id: sadAnim

        ScriptAction {
            script: {
                root.scanX = root.smoothLookX;
                root.scanY = root.smoothLookY;
                root.scanning = true;
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "droop"
                to: 0.9
                duration: 700
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "scanX"
                to: 0
                duration: 700
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "scanY"
                to: 0.9
                duration: 700
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "squash"
                to: 0.35
                duration: 1000
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "tilt"
                to: 4
                duration: 1000
                easing.type: Easing.InOutSine
            }
        }
        PauseAnimation {
            duration: 1900
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "droop"
                to: 0
                duration: 600
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "scanY"
                to: 0
                duration: 600
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "squash"
                to: 0
                duration: 600
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "tilt"
                to: 0
                duration: 600
                easing.type: Easing.InOutSine
            }
        }
        ScriptAction {
            script: root.scanning = false
        }
    }

    SequentialAnimation {
        id: cryAnim

        ScriptAction {
            script: {
                root.scanX = root.smoothLookX;
                root.scanY = root.smoothLookY;
                root.scanning = true;
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "droop"
                to: 0.7
                duration: 500
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "sadTilt"
                to: 1
                duration: 500
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: root
                property: "tears"
                to: 1
                duration: 600
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "scanX"
                to: 0
                duration: 500
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "scanY"
                to: 0.4
                duration: 500
                easing.type: Easing.OutQuad
            }
        }
        NumberAnimation {
            target: root
            property: "stream"
            to: 1
            duration: 900
            easing.type: Easing.OutQuad
        }
        SequentialAnimation {
            loops: 4

            ParallelAnimation {
                NumberAnimation {
                    target: root
                    property: "drip"
                    from: 0
                    to: 1
                    duration: 650
                    easing.type: Easing.InQuad
                }
                SequentialAnimation {
                    NumberAnimation {
                        target: root
                        property: "squash"
                        to: 0.2
                        duration: 160
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: root
                        property: "squash"
                        to: 0
                        duration: 260
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "stream"
                to: 0
                duration: 500
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: root
                property: "tears"
                to: 0
                duration: 700
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "droop"
                to: 0
                duration: 700
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "sadTilt"
                to: 0
                duration: 700
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "scanY"
                to: 0
                duration: 700
                easing.type: Easing.InOutSine
            }
        }
        ScriptAction {
            script: {
                root.drip = 0;
                root.scanning = false;
            }
        }
    }

    SequentialAnimation {
        id: infectAnim

        ScriptAction {
            script: root.expression = "infected"
        }
        ParallelAnimation {
            SequentialAnimation {
                loops: 3

                NumberAnimation {
                    target: root
                    property: "glow"
                    to: 1
                    duration: 450
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: root
                    property: "glow"
                    to: 0
                    duration: 450
                    easing.type: Easing.InOutSine
                }
            }
            SequentialAnimation {
                loops: 12

                NumberAnimation {
                    target: root
                    property: "shake"
                    to: 1.6
                    duration: 45
                }
                NumberAnimation {
                    target: root
                    property: "shake"
                    to: -1.6
                    duration: 45
                }
            }
            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "tilt"
                    to: -6
                    duration: 300
                    easing.type: Easing.OutQuad
                }
                PauseAnimation {
                    duration: 1900
                }
                NumberAnimation {
                    target: root
                    property: "tilt"
                    to: 0
                    duration: 450
                    easing.type: Easing.InOutSine
                }
            }
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: 0
            duration: 60
        }
        PauseAnimation {
            duration: 300
        }
        ScriptAction {
            script: {
                root.expression = "open";
                blinkAnim.restart();
            }
        }
    }

    SequentialAnimation {
        id: angryAnim

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "droop"
                to: 0.5
                duration: 250
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "sadTilt"
                to: -0.9
                duration: 300
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: root
                property: "anger"
                to: 1
                duration: 200
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "squash"
                to: 0.3
                duration: 200
                easing.type: Easing.OutQuad
            }
        }
        ParallelAnimation {
            SequentialAnimation {
                loops: 8

                NumberAnimation {
                    target: root
                    property: "shake"
                    to: 1.2
                    duration: 45
                }
                NumberAnimation {
                    target: root
                    property: "shake"
                    to: -1.2
                    duration: 45
                }
            }
            SequentialAnimation {
                loops: 3

                NumberAnimation {
                    target: root
                    property: "angerBeat"
                    to: 1
                    duration: 180
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: root
                    property: "angerBeat"
                    to: 0
                    duration: 220
                    easing.type: Easing.InQuad
                }
            }
        }
        PauseAnimation {
            duration: 500
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "droop"
                to: 0
                duration: 400
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "sadTilt"
                to: 0
                duration: 400
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "anger"
                to: 0
                duration: 300
            }
            NumberAnimation {
                target: root
                property: "squash"
                to: 0
                duration: 400
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: root
                property: "shake"
                to: 0
                duration: 60
            }
        }
    }

    SequentialAnimation {
        id: shockedAnim

        ScriptAction {
            script: root.expression = "shocked"
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "shock"
                to: 1
                duration: 120
            }
            NumberAnimation {
                target: root
                property: "hop"
                to: 0.9
                duration: 140
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "squash"
                to: -0.6
                duration: 140
                easing.type: Easing.OutQuad
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "hop"
                to: 0
                duration: 220
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: root
                property: "squash"
                to: 0
                duration: 220
            }
        }
        SequentialAnimation {
            loops: 10

            NumberAnimation {
                target: root
                property: "shake"
                to: 0.8
                duration: 40
            }
            NumberAnimation {
                target: root
                property: "shake"
                to: -0.8
                duration: 40
            }
        }
        PauseAnimation {
            duration: 700
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "shock"
                to: 0
                duration: 300
            }
            NumberAnimation {
                target: root
                property: "shake"
                to: 0
                duration: 60
            }
        }
        ScriptAction {
            script: {
                root.expression = "open";
                blinkAnim.restart();
            }
        }
    }

    SequentialAnimation {
        id: soulAnim

        ScriptAction {
            script: {
                root.scanX = 0;
                root.scanY = -0.5;
                root.scanning = true;
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "soulness"
                to: 1
                duration: 700
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "hop"
                to: 0.6
                duration: 900
                easing.type: Easing.InOutSine
            }
        }
        SequentialAnimation {
            loops: 2

            NumberAnimation {
                target: root
                property: "hop"
                to: 0.3
                duration: 700
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "hop"
                to: 0.6
                duration: 700
                easing.type: Easing.InOutSine
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "soulness"
                to: 0
                duration: 900
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "hop"
                to: 0
                duration: 700
                easing.type: Easing.InOutSine
            }
        }
        ScriptAction {
            script: {
                root.scanY = 0;
                root.scanning = false;
            }
        }
    }

    SequentialAnimation {
        id: voidAnim

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "voidness"
                to: 1
                duration: 600
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "squash"
                to: 0.2
                duration: 600
                easing.type: Easing.InOutSine
            }
        }
        PauseAnimation {
            duration: 2200
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "voidness"
                to: 0
                duration: 700
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "squash"
                to: 0
                duration: 700
                easing.type: Easing.OutBack
            }
        }
    }

    // Easter egg: the Knight turns into the Hollow Knight for a while
    SequentialAnimation {
        id: bossAnim

        ScriptAction {
            script: {
                root.expression = "open";
                root.bossShown = true;
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "voidness"
                to: 1
                duration: 700
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "squash"
                to: 0.5
                duration: 700
                easing.type: Easing.InOutSine
            }
            SequentialAnimation {
                loops: 9

                NumberAnimation {
                    target: root
                    property: "shake"
                    to: 0.9
                    duration: 40
                }
                NumberAnimation {
                    target: root
                    property: "shake"
                    to: -0.9
                    duration: 40
                }
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "boss"
                to: 1
                duration: 450
                easing.type: Easing.InOutSine
            }
            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "squash"
                    to: -0.9
                    duration: 200
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: root
                    property: "squash"
                    to: 0
                    duration: 380
                    easing.type: Easing.OutBack
                }
            }
            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "hop"
                    to: 0.8
                    duration: 200
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: root
                    property: "hop"
                    to: 0
                    duration: 300
                    easing.type: Easing.InQuad
                }
            }
            NumberAnimation {
                target: root
                property: "shake"
                to: 0
                duration: 60
            }
        }
        PauseAnimation {
            duration: 250
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "voidness"
                to: 0
                duration: 800
                easing.type: Easing.InOutSine
            }
        }
        PauseAnimation {
            duration: 7000
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "voidness"
                to: 1
                duration: 700
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "squash"
                to: 0.5
                duration: 700
                easing.type: Easing.InOutSine
            }
            SequentialAnimation {
                loops: 9

                NumberAnimation {
                    target: root
                    property: "shake"
                    to: 0.9
                    duration: 40
                }
                NumberAnimation {
                    target: root
                    property: "shake"
                    to: -0.9
                    duration: 40
                }
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "boss"
                to: 0
                duration: 450
                easing.type: Easing.InOutSine
            }
            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "squash"
                    to: -0.9
                    duration: 200
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: root
                    property: "squash"
                    to: 0
                    duration: 380
                    easing.type: Easing.OutBack
                }
            }
            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "hop"
                    to: 0.8
                    duration: 200
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: root
                    property: "hop"
                    to: 0
                    duration: 300
                    easing.type: Easing.InQuad
                }
            }
            NumberAnimation {
                target: root
                property: "shake"
                to: 0
                duration: 60
            }
        }
        PauseAnimation {
            duration: 250
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "voidness"
                to: 0
                duration: 800
                easing.type: Easing.InOutSine
            }
        }
        ScriptAction {
            script: root.bossShown = false
        }
    }

    SequentialAnimation {
        id: rageAnim

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "bossInfection"
                to: 1
                duration: 500
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "squash"
                to: 0.3
                duration: 300
                easing.type: Easing.OutQuad
            }
            SequentialAnimation {
                loops: 14

                NumberAnimation {
                    target: root
                    property: "shake"
                    to: 1.2
                    duration: 40
                }
                NumberAnimation {
                    target: root
                    property: "shake"
                    to: -1.2
                    duration: 40
                }
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "squash"
                to: 0
                duration: 300
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: root
                property: "shake"
                to: 0
                duration: 60
            }
        }
        PauseAnimation {
            duration: 900
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "voidness"
                to: 1
                duration: 700
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "squash"
                to: 0.5
                duration: 700
                easing.type: Easing.InOutSine
            }
            SequentialAnimation {
                loops: 9

                NumberAnimation {
                    target: root
                    property: "shake"
                    to: 0.9
                    duration: 40
                }
                NumberAnimation {
                    target: root
                    property: "shake"
                    to: -0.9
                    duration: 40
                }
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "boss"
                to: 0
                duration: 450
                easing.type: Easing.InOutSine
            }
            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "squash"
                    to: -0.9
                    duration: 200
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: root
                    property: "squash"
                    to: 0
                    duration: 380
                    easing.type: Easing.OutBack
                }
            }
            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "hop"
                    to: 0.8
                    duration: 200
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: root
                    property: "hop"
                    to: 0
                    duration: 300
                    easing.type: Easing.InQuad
                }
            }
            NumberAnimation {
                target: root
                property: "shake"
                to: 0
                duration: 60
            }
        }
        PauseAnimation {
            duration: 250
        }
        ScriptAction {
            script: root.bossInfection = 0
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "voidness"
                to: 0
                duration: 800
                easing.type: Easing.InOutSine
            }
        }
        ScriptAction {
            script: {
                root.bossShown = false;
                root.woke();
            }
        }
    }

    SequentialAnimation {
        id: wakeAnim

        property bool startle

        ScriptAction {
            script: {
                root.nod = 0;
                root.tilt = 0;
                root.expression = wakeAnim.startle ? "shocked" : "open";
                root.shock = wakeAnim.startle ? 1 : 0;
            }
        }
        NumberAnimation {
            target: root
            property: "squash"
            to: 0.8
            duration: 110
            easing.type: Easing.OutQuad
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "squash"
                to: -0.9
                duration: 150
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "hop"
                to: 1.6
                duration: 180
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "widen"
                to: 1.3
                duration: 150
                easing.type: Easing.OutQuad
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "squash"
                to: 0
                duration: 200
            }
            NumberAnimation {
                target: root
                property: "hop"
                to: 0
                duration: 240
                easing.type: Easing.InQuad
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "squash"
                to: 0.5
                duration: 80
            }
            NumberAnimation {
                target: root
                property: "widen"
                to: 1
                duration: 300
                easing.type: Easing.OutQuad
            }
        }
        NumberAnimation {
            target: root
            property: "squash"
            to: 0
            duration: 220
            easing.type: Easing.OutBack
        }
        ScriptAction {
            script: {
                root.expression = "open";
                root.shock = 0;
                root.woke();
            }
        }
    }

    SequentialAnimation {
        id: leaveAnim

        ScriptAction {
            script: root.expression = "happy"
        }
        PauseAnimation {
            duration: 350
        }
        ScriptAction {
            script: hopAnim.restart()
        }
        PauseAnimation {
            duration: 900
        }
        ScriptAction {
            script: {
                root.expression = "open";
                root.woke();
            }
        }
    }

    Item {
        width: root.canvasWidth
        height: root.canvasHeight
        scale: root.ratio
        transformOrigin: Item.TopLeft

        Item {
            id: body

            readonly property real pivotX: 144.39 - root.originX
            // The Hollow Knight's head rises above the canvas: the layer only draws inside the item
            readonly property real headroom: 45
            readonly property real pivotY: 101.6 - root.originY + headroom
            readonly property bool voidRim: root.voidness > root.soulness
            readonly property bool tightRim: voidRim || (Hallownest.light && root.soulness < 0.05)

            anchors.fill: parent
            anchors.topMargin: -headroom
            layer.enabled: Hallownest.light || root.soulness > 0.01 || root.voidness > 0.01
            // Soul = wide glow; Void / light mode = tight rim so the body doesn't vanish into the notch
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Hallownest.soul
                shadowOpacity: Math.max(Hallownest.light ? 0.55 : 0, root.soulness, root.voidness)
                shadowBlur: body.tightRim ? 0.18 : 1
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
                blurMax: body.tightRim ? 5 : 24
            }

            transform: [
                Scale {
                    origin.x: body.pivotX
                    origin.y: body.pivotY
                    xScale: 1 + root.squash * 0.12 - root.breath * 0.012
                    yScale: 1 - root.squash * 0.14 + root.breath * 0.02
                },
                Rotation {
                    origin.x: body.pivotX
                    origin.y: body.pivotY
                    angle: root.tilt + root.nod * 7 + root.sway * 5
                },
                Translate {
                    x: root.shake
                    y: -root.hop * 9 + (root.dozing ? 2 : 0)
                }
            ]

            Item {
                x: -root.originX
                y: -root.originY + body.headroom

                Shape {
                    preferredRendererType: Shape.CurveRenderer
                    opacity: 1 - root.boss

                    ShapePath {
                        fillColor: root.headColour
                        strokeWidth: -1

                        PathSvg {
                            path: "M 116.73,80.86 C 107.51,75.66 105.00,61.82 108.35,53.16 C 110.86,46.24 115.89,40.18 120.42,36.37 L 121.59,40.70 L 126.95,41.39 C 119.24,44.51 113.38,49.70 112.87,56.62 C 112.54,60.95 115.05,63.55 119.24,65.28 Z"
                        }
                    }

                    ShapePath {
                        fillColor: root.headColour
                        strokeWidth: -1

                        PathSvg {
                            path: "M 172.04,80.86 C 181.25,75.66 183.77,61.82 180.42,53.16 C 177.90,46.24 172.87,40.18 168.35,36.37 L 167.18,40.70 L 161.81,41.39 C 169.52,44.51 175.39,49.70 175.89,56.62 C 176.23,60.95 173.71,63.55 169.52,65.28 Z"
                        }
                    }
                }

                Rectangle {
                    x: 115.89199
                    y: 59.220367
                    width: 56.991302
                    height: 42.401421
                    radius: 12.796824
                    color: root.headColour
                    opacity: 1 - root.boss
                }

                Eye {
                    x: 130.3 + root.smoothLookX * 5
                    y: 77 + root.smoothLookY * 3.5
                    isLeft: true
                    opacity: 1 - root.boss
                }

                Eye {
                    x: 158.5 + root.smoothLookX * 5
                    y: 77 + root.smoothLookY * 3.5
                    isLeft: false
                    opacity: 1 - root.boss
                }

                // Hollow Knight head (HK.svg, page coordinates), scaled onto the Knight's base
                Item {
                    opacity: root.boss
                    visible: opacity > 0
                    transform: [
                        Translate {
                            x: -165.47
                            y: -105.15
                        },
                        Scale {
                            xScale: 0.95
                            yScale: 0.95
                        },
                        Translate {
                            x: 144.39
                            y: 101.6
                        }
                    ]

                    Shape {
                        preferredRendererType: Shape.CurveRenderer
                        transform: Matrix4x4 {
                            matrix: Qt.matrix4x4(1.7237558, 0, 0, -91.080165, 0, 1.5595504, 0, -174.2474, 0, 0, 1, 0, 0, 0, 0, 1)
                        }

                        ShapePath {
                            fillColor: root.headColour
                            strokeColor: root.headColour
                            strokeWidth: 0.4

                            PathSvg {
                                path: "m 143.06465,113.63647 c -0.49088,0.14127 -0.9819,0.28299 -1.47278,0.42427 -5.2763,2.61716 -8.95798,7.60134 -11.3223,12.87001 -3.75006,8.47435 -4.61984,18.07537 -3.1502,27.18077 1.18976,6.9552 3.83913,13.88012 8.69456,19.11408 3.22906,3.49281 7.78496,6.03877 12.64006,5.92522 0.15444,-0.001 0.30834,-0.005 0.46198,-0.0109 V 159.3572 c -0.64516,0.0514 -1.29531,0.0505 -1.93476,0.0191 -2.52817,-0.37181 -4.10647,-2.70146 -5.08238,-4.85965 -1.29291,-2.85106 -1.82778,-5.94349 -2.27428,-9.03976 -0.14379,-0.58936 -0.28719,-1.17848 -0.43098,-1.76785 -0.3249,1.03899 -0.71569,2.06441 -0.69711,3.16931 -0.13605,1.38951 -0.36744,2.82561 -1.09399,4.04162 -0.44392,-2.99627 -0.26054,-6.0474 -0.17312,-9.06457 0.14876,-2.88198 0.29242,-5.84341 0.8847,-8.69352 -0.10159,-0.39983 0.15138,-1.85675 -0.38551,-0.95757 -0.95144,0.92949 -1.16903,2.29988 -1.75596,3.45096 -0.36568,0.8552 -0.7408,1.70743 -1.156,2.53989 -0.25497,-4.50339 0.78468,-8.98936 2.11615,-13.20901 1.13848,-3.32448 2.43428,-6.7007 4.67465,-9.45369 0.58167,-0.55571 1.01824,-1.22492 1.45727,-1.89601 z"
                            }
                        }

                        ShapePath {
                            fillColor: root.headColour
                            strokeColor: root.headColour
                            strokeWidth: 0.4

                            PathSvg {
                                path: "m 154.59799,113.60147 c 0.49088,0.14127 0.9819,0.28299 1.47278,0.42427 5.2763,2.61716 8.95798,7.60134 11.3223,12.87001 3.75006,8.47435 4.61984,18.07537 3.1502,27.18077 -1.18976,6.9552 -3.83913,13.88012 -8.69456,19.11408 -3.22906,3.49281 -7.78496,6.03877 -12.64006,5.92522 -0.15444,-0.001 -0.30834,-0.005 -0.46198,-0.0109 l 6e-4,-19.76019 c 0.64516,0.0514 1.29471,0.028 1.93416,-0.003 2.52817,-0.37181 4.10647,-2.70146 5.08238,-4.85965 1.29291,-2.85106 1.82778,-5.94349 2.27428,-9.03976 0.14379,-0.58936 0.28719,-1.17848 0.43098,-1.76785 0.3249,1.03899 0.71569,2.06441 0.69711,3.16931 0.13605,1.38951 0.36744,2.82561 1.09399,4.04162 0.44392,-2.99627 0.26054,-6.0474 0.17312,-9.06457 -0.14876,-2.88198 -0.29242,-5.84341 -0.8847,-8.69352 0.10159,-0.39983 -0.15138,-1.85675 0.38551,-0.95757 0.95144,0.92949 1.16903,2.29988 1.75596,3.45096 0.36568,0.8552 0.7408,1.70743 1.156,2.53989 0.25497,-4.50339 -0.78468,-8.98936 -2.11615,-13.20901 -1.13848,-3.32448 -2.43428,-6.7007 -4.67465,-9.45369 -0.58167,-0.55571 -1.01824,-1.22492 -1.45727,-1.89601 z"
                            }
                        }

                        // Fills the antialiasing seam where both halves meet
                        ShapePath {
                            fillColor: root.headColour
                            strokeWidth: -1

                            PathSvg {
                                path: "M 148.3,159.2 H 149.4 V 178.9 H 148.3 Z"
                            }
                        }
                    }

                    Shape {
                        preferredRendererType: Shape.CurveRenderer
                        opacity: root.bossInfection
                        visible: opacity > 0
                        transform: Translate {
                            x: 109.06
                            y: -190.84
                        }

                        ShapePath {
                            fillColor: "black"
                            strokeWidth: -1

                            PathSvg {
                                path: "m 72.443439,291.48136 3.924092,-9.69485 -2.295859,-10.27094 -2.175026,-1.32919 2.900035,1.57086 2.537529,10.75428 -1.28646,6.36822 z M 54.053947,265.14673 c 6.65936,3.0133 7.674328,4.31243 7.571752,4.67715 -1.385679,2.26476 -3.315364,3.90182 -5.437563,5.31675 l -8.337595,1.57083 -10.64204,7.25804 -0.147011,5.40091 0.943431,-4.66857 10.208125,-6.90286 7.97509,-0.72501 c 2.962743,-2.51153 5.65347,-5.24067 8.337595,-7.9751 l -3.745876,-2.17501 4.599676,-4.96281 c -1.34971,1.06746 -2.601011,2.35959 -4.166389,2.88788 l -1.520799,1.71242 z"
                            }
                        }
                    }

                    HollowEye {
                        cx: 201.75719
                        cy: 8.269906
                        matrix: Qt.matrix4x4(0.90768296, -0.55016429, 0, 0, 0.41965658, 0.83505644, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                    }

                    HollowEye {
                        cx: -77.935188
                        cy: 148.5948
                        matrix: Qt.matrix4x4(-0.90768296, 0.55016429, 0, 0, 0.41965658, 0.83505644, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                    }
                }

                Repeater {
                    model: 3

                    StyledText {
                        required property int index
                        readonly property real t: (root.zProgress + index / 3) % 1

                        x: 178 + t * 9
                        y: 52 - t * 20
                        visible: root.dozing && root.running
                        opacity: Math.min(1, t * 4, (1 - t) * 2)
                        text: "z"
                        color: Hallownest.steel
                        font.family: Hallownest.serif
                        font.pointSize: 7 + t * 6
                        font.bold: true
                    }
                }

                Shape {
                    preferredRendererType: Shape.CurveRenderer
                    opacity: root.anger
                    visible: opacity > 0

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Hallownest.grimm
                        strokeWidth: 1.3
                        capStyle: ShapePath.RoundCap

                        PathSvg {
                            path: root.angerPath(184, 50, 1 + root.angerBeat * 0.35) + " " + root.angerPath(109, 96, 0.75 + root.angerBeat * 0.25)
                        }
                    }
                }

                Shape {
                    preferredRendererType: Shape.CurveRenderer
                    opacity: root.shock
                    visible: opacity > 0

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Hallownest.crystal
                        strokeWidth: 1
                        joinStyle: ShapePath.RoundJoin

                        PathSvg {
                            path: "M 177 60 Q 180.5 66 178.5 68.5 Q 177 69.5 175.5 68.5 Q 173.5 66 177 60 Z M 183 67 Q 185.5 71.5 184 73.5 Q 183 74.3 182 73.5 Q 180.5 71.5 183 67 Z"
                        }
                    }

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Hallownest.soul
                        strokeWidth: 1.2
                        capStyle: ShapePath.RoundCap

                        PathSvg {
                            path: "M 112 80 L 104 78 M 111.5 86 L 103 87 M 112.5 92 L 106 97 M 177 80 L 185 78 M 177.5 86 L 186 87 M 176.5 92 L 183 97"
                        }
                    }
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

    component Eye: Item {
        id: eye

        required property bool isLeft
        readonly property real angle: (isLeft ? -27 : 22) * root.sadTilt
        readonly property real holeX: 0.69 * (1 - Math.abs(root.smoothLookX)) + root.smoothLookX * 2.6
        readonly property real holeY: -0.41 * (1 - Math.abs(root.smoothLookY)) + root.smoothLookY * 2
        readonly property real cut: root.droop * 11.2
        readonly property real streamLength: root.stream * 13

        width: 0
        height: 0

        Item {
            opacity: root.expression === "open" && !root.closed ? 1 : 0
            rotation: eye.angle

            transform: Scale {
                yScale: Math.max(0.05, root.lid * root.blink * root.widen)
                xScale: 1 + (root.widen - 1) * 0.35
            }

            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }

            Item {
                x: -12
                y: -13 + eye.cut
                width: 24
                height: 26 - eye.cut
                clip: true

                Item {
                    x: 12
                    y: 13 - eye.cut

                    Oval {
                        rx: 8.5404215
                        ry: 10.924521
                        fill: root.rimColour
                    }

                    Item {
                        x: eye.holeX
                        y: eye.holeY

                        Oval {
                            rx: 7.8389201
                            ry: 10.399279
                            fill: root.eyeColour
                        }

                        Shape {
                            opacity: root.tears
                            visible: opacity > 0
                            preferredRendererType: Shape.CurveRenderer

                            ShapePath {
                                fillColor: Hallownest.isMono ? Hallownest.lifeblood : "#00c3e2"
                                strokeWidth: -1

                                PathSvg {
                                    path: "M -7.1 0.4 A 7.1 9.6 0 0 0 7.1 0.4 A 7.1 7 0 0 1 -7.1 0.4 Z"
                                }
                            }
                        }
                    }

                    Shape {
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            fillColor: root.headColour
                            fillRule: ShapePath.OddEvenFill
                            strokeWidth: -1

                            PathSvg {
                                path: "M 10.5 0 A 10.5 12.5 0 1 0 -10.5 0 A 10.5 12.5 0 1 0 10.5 0 Z M 8.3 0 A 8.3 10.7 0 1 0 -8.3 0 A 8.3 10.7 0 1 0 8.3 0 Z"
                            }
                        }
                    }
                }
            }

            Item {
                x: -12
                y: -13
                width: 24
                height: eye.cut
                clip: true
                opacity: root.lidShade
                visible: opacity > 0 && height > 0

                Item {
                    x: 12
                    y: 13

                    Oval {
                        rx: 8.5404215
                        ry: 10.924521
                        fill: root.lidColour
                    }

                    Shape {
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            fillColor: root.headColour
                            fillRule: ShapePath.OddEvenFill
                            strokeWidth: -1

                            PathSvg {
                                path: "M 10.5 0 A 10.5 12.5 0 1 0 -10.5 0 A 10.5 12.5 0 1 0 10.5 0 Z M 8.3 0 A 8.3 10.7 0 1 0 -8.3 0 A 8.3 10.7 0 1 0 8.3 0 Z"
                            }
                        }
                    }
                }
            }

            Rectangle {
                readonly property real cy: eye.cut - 13
                readonly property real hw: 8.54 * Math.sqrt(Math.max(0, 1 - Math.pow(cy / 10.92, 2)))

                x: -hw
                y: cy - 0.7
                width: hw * 2
                height: 1.4
                radius: 0.7
                color: "#25282e"
                opacity: root.lidShade
                visible: opacity > 0 && eye.cut > 0
            }

            Item {
                x: eye.holeX
                y: eye.holeY
                opacity: root.voidness
                visible: opacity > 0.01

                Oval {
                    rx: 10.5
                    ry: 13.2
                    fill: Qt.alpha(Hallownest.soul, 0.08)
                }

                Oval {
                    rx: 9
                    ry: 11.6
                    fill: Qt.alpha(Hallownest.soul, 0.16)
                }
            }
        }

        Shape {
            opacity: root.expression === "open" && root.closed ? 1 : 0
            visible: opacity > 0
            preferredRendererType: Shape.CurveRenderer

            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: root.eyeColour
                strokeWidth: 1.6
                capStyle: ShapePath.RoundCap

                PathSvg {
                    path: "M -7.5 1 Q 0 6.5 7.5 1"
                }
            }
        }

        Item {
            opacity: root.expression === "shocked" ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }

            Oval {
                x: root.smoothLookX * 4.5 + root.shake * 0.4
                y: root.smoothLookY * 3.5
                rx: 2.8
                ry: 4
                fill: root.eyeColour
            }
        }

        Item {
            readonly property real px: eye.holeX
            readonly property real py: eye.holeY + 6.5
            readonly property real rad: eye.angle * Math.PI / 180

            x: px * Math.cos(rad) - py * Math.sin(rad)
            y: px * Math.sin(rad) + py * Math.cos(rad)
            opacity: root.expression === "open" ? 1 : 0
            visible: root.stream > 0

            Shape {
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: Hallownest.isMono ? Hallownest.lifeblood : "#6bd1f9"
                    strokeWidth: -1

                    PathSvg {
                        path: `M -3 0 Q 0 1.6 3 0 L 3 ${eye.streamLength} A 3 3 0 0 1 -3 ${eye.streamLength} Z`
                    }
                }
            }

            Oval {
                y: eye.streamLength + 2 + root.drip * 10
                visible: root.drip > 0 && root.drip < 1
                opacity: 1 - root.drip
                rx: 1.5
                ry: 2
                fill: Hallownest.isMono ? Hallownest.lifeblood : "#6bd1f9"
            }
        }

        Item {
            opacity: root.expression === "infected" ? 1 : 0
            visible: opacity > 0

            transform: Scale {
                yScale: Math.max(0.05, root.blink * root.widen)
            }

            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }

            Item {
                x: root.smoothLookX * 3.3
                y: root.smoothLookY * 2.4

                Oval {
                    rx: 7.8389201
                    ry: 10.399279
                    fill: root.eyeColour
                }

                Oval {
                    y: 0.06
                    rx: 7.1683073
                    ry: 9.9771566
                    fill: Hallownest.isMono ? Hallownest.faint : "#d54501"
                }

                Oval {
                    y: 0.28
                    rx: 6.776 * (0.9 + root.glow * 0.1)
                    ry: 8.65 * (0.9 + root.glow * 0.1)
                    fill: Hallownest.isMono ? Qt.tint(Hallownest.infection, Qt.rgba(1, 1, 1, root.glow * 0.35)) : Qt.tint("#d88f01", Qt.rgba(1, 0.8, 0.3, root.glow * 0.35))
                }
            }
        }

        Item {
            opacity: root.expression === "happy" ? 1 : 0

            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }

            Shape {
                x: eye.isLeft ? -45.33 : -71.71
                y: -92
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: root.rimColour
                    strokeWidth: -1

                    PathSvg {
                        path: eye.isLeft ? "m 35.964431,104.03363 c 1.410768,-8.322624 0.12665,-19.445859 9.462213,-19.765788 6.99279,0.337512 9.105628,8.703275 9.268286,19.868148 -2.390705,-2.10934 -1.870224,-5.259131 -9.194983,-5.62951 -6.689966,0.04808 -6.622973,3.77495 -9.535516,5.52715 z" : "M 81.079752,103.77901 C 79.668973,95.456385 80.953103,84.333148 71.61754,84.013219 c -6.992791,0.337512 -9.105629,8.703277 -9.268287,19.868151 2.390705,-2.10934 1.870224,-5.259132 9.194984,-5.629513 6.689954,0.04808 6.622961,3.774953 9.535515,5.527153 z"
                    }
                }

                ShapePath {
                    fillColor: root.eyeColour
                    strokeWidth: -1

                    PathSvg {
                        path: eye.isLeft ? "m 36.718656,102.47211 c 1.351972,-8.011467 0.121472,-18.71884 9.067921,-19.026809 6.701454,0.324875 8.726246,8.377889 8.882134,19.125339 -2.291088,-2.03048 -1.792321,-5.062501 -8.81185,-5.419036 -6.411249,0.04629 -6.347028,3.633816 -9.138205,5.320506 z" : "m 80.27599,102.19872 c -1.351972,-8.011475 -0.121472,-18.718848 -9.067909,-19.026817 -6.701454,0.324877 -8.726257,8.377891 -8.882134,19.125347 2.291077,-2.03048 1.792309,-5.062509 8.811838,-5.419044 6.41125,0.04629 6.347029,3.633814 9.138205,5.320514 z"
                    }
                }
            }
        }

        Item {
            width: 0
            height: 0
            opacity: root.expression === "dizzy" ? 1 : 0
            rotation: eye.isLeft ? root.spin : -root.spin

            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }

            Item {
                x: eye.isLeft ? -44.66 : -76.72
                y: eye.isLeft ? -36.38 : -34.93

                Shape {
                    preferredRendererType: Shape.CurveRenderer

                    transform: Matrix4x4 {
                        matrix: eye.isLeft ? Qt.matrix4x4(4.7080603, 0, 0, -461.22894, 0, 4.4810439, 0, -72.108229, 0, 0, 1, 0, 0, 0, 0, 1) : Qt.matrix4x4(0, -4.8811484, 0, 194.89254, 4.3313421, 0, 0, -430.47786, 0, 0, 1, 0, 0, 0, 0, 1)
                    }

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: root.eyeColour
                        strokeWidth: 0.6
                        capStyle: ShapePath.RoundCap

                        PathSvg {
                            path: "m 107.45364,24.210104 c 0.11327,0.09189 -0.068,0.198016 -0.15273,0.188253 -0.22965,-0.02646 -0.29568,-0.3102 -0.22377,-0.493721 0.12862,-0.328277 0.5431,-0.408339 0.83471,-0.259292 0.42794,0.218732 0.52393,0.779011 0.29481,1.175696 -0.30538,0.528718 -1.01598,0.640749 -1.51669,0.330331 -0.63009,-0.390629 -0.75819,-1.253433 -0.36585,-1.857671 0.47519,-0.731814 1.49117,-0.876006 2.19866,-0.40137 0.83375,0.559343 0.99405,1.72908 0.43689,2.539646 -0.64326,0.93583 -1.96711,1.112234 -2.88063,0.472408 -1.03801,-0.727011 -1.23053,-2.205213 -0.50793,-3.22162 0.81065,-1.140255 2.44338,-1.348905 3.56261,-0.543447 1.24255,0.894211 1.46734,2.681592 0.57896,3.903595"
                        }
                    }
                }
            }
        }
    }

    component HollowEye: Item {
        id: hollowEye

        required property real cx
        required property real cy
        required property matrix4x4 matrix

        transform: [
            Scale {
                origin.x: hollowEye.cx
                origin.y: hollowEye.cy
                yScale: root.blink
            },
            Matrix4x4 {
                matrix: hollowEye.matrix
            },
            Translate {
                x: root.smoothLookX * 4.5
                y: root.smoothLookY * 3
            }
        ]

        Oval {
            x: hollowEye.cx
            y: hollowEye.cy
            rx: 6.085526
            ry: 9.8280611
            fill: Qt.tint(Qt.tint("#1a1a1a", Hallownest.isMono ? Qt.rgba(0.55, 0.56, 0.6, root.bossInfection) : Qt.rgba(0.835, 0.1, 0.1, root.bossInfection)), Qt.rgba(0.95, 0.97, 0.98, root.voidness))
        }

        Oval {
            x: hollowEye.cx
            y: hollowEye.cy
            rx: 5.35
            ry: 8.92
            fill: Hallownest.isMono ? Hallownest.infection : "#d88f01"
            opacity: root.bossInfection * (1 - root.voidness)
            visible: opacity > 0
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

    component Bounce: SequentialAnimation {
        id: bounce

        property real height: 1
        property real lean

        NumberAnimation {
            target: root
            property: "squash"
            to: 0.6
            duration: 100
            easing.type: Easing.OutQuad
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "squash"
                to: -0.7
                duration: 150
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "hop"
                to: bounce.height
                duration: 190
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "tilt"
                to: bounce.lean
                duration: 190
                easing.type: Easing.OutQuad
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "squash"
                to: 0
                duration: 180
            }
            NumberAnimation {
                target: root
                property: "hop"
                to: 0
                duration: 220
                easing.type: Easing.InQuad
            }
        }
        NumberAnimation {
            target: root
            property: "squash"
            to: 0.45
            duration: 80
        }
    }
}
