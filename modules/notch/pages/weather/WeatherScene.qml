pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell.Widgets
import qs.components.hallownest
import qs.services

// Animated Hallownest biome banner for the current weather (with day & night variants):
// sun = Greenpath, clear night = Dirtmouth, cloud = Crossroads / Howling Cliffs,
// fog = Fog Canyon, rain = City of Tears, storm = Kingdom's Edge, snow = Crystal Peak
ClippingRectangle {
    id: root

    property string kind
    property bool night
    property bool running: visible
    property real t

    readonly property bool previewIsNight: Weather.previewScene === "night" || Weather.previewScene.endsWith("-night")
    readonly property string previewBase: Weather.previewScene.endsWith("-night") ? Weather.previewScene.slice(0, -6) : Weather.previewScene
    readonly property string shownKind: {
        if (!Weather.previewScene)
            return kind;
        if (Weather.previewScene === "night")
            return "moon";
        return previewBase;
    }
    readonly property bool shownNight: Weather.previewScene ? previewIsNight : night
    readonly property string scene: {
        if (shownKind === "storm")
            return "edge";
        if (shownKind === "rain")
            return "tears";
        if (shownKind === "snow")
            return "crystal";
        if (shownKind === "fog")
            return "fog";
        if (shownKind === "moon")
            return "night";
        if (shownKind === "sun" || shownKind === "twilight" || shownKind === "partly")
            return "greenpath";
        return "cloud";
    }
    readonly property var colours: {
        if (Hallownest.isMono) {
            const monoDay = {
                greenpath: ["#26282f", "#0f1014", "#e4e5ea", "#b0b2ba", "#17181d", "#1e2026"],
                night: ["#1a1c22", "#090a0d", "#f2f3f7", "#a8aab4", "#111216", "#181a1f"],
                cloud: ["#282a32", "#101115", "#d4d6de", "#989aa4", "#18191f", "#202229"],
                fog: ["#2b2d35", "#0e0f13", "#e6e7ec", "#b8bac2", "#191a20", "#22242b"],
                tears: ["#22242b", "#0c0d11", "#dcdee6", "#a4a6b0", "#14161b", "#1c1e24"],
                edge: ["#262830", "#0e0f13", "#e2e4ec", "#b4b6c0", "#17181e", "#1f2128"],
                crystal: ["#292b33", "#0e0f13", "#ededf2", "#c4c6ce", "#181a20", "#484a54"]
            };
            const monoNight = {
                greenpath: ["#191b22", "#090a0d", "#eef0f6", "#9fa2ac", "#111217", "#17191f"],
                night: ["#1a1c22", "#090a0d", "#f2f3f7", "#a8aab4", "#111216", "#181a1f"],
                cloud: ["#1a1c22", "#090a0d", "#eceef4", "#8e919c", "#111217", "#181a20"],
                fog: ["#1b1d24", "#090a0d", "#f0f1f6", "#a8abb4", "#121318", "#191b22"],
                tears: ["#171920", "#08090c", "#d8dae4", "#f2f3f7", "#0f1015", "#15171d"],
                edge: ["#191b22", "#08090c", "#eef0f6", "#c6c8d2", "#101217", "#171920"],
                crystal: ["#1a1c22", "#08090c", "#f2f3f8", "#d0d2da", "#111218", "#343640"]
            };
            return (shownNight ? monoNight : monoDay)[scene];
        }
        if (Hallownest.light) {
            const lightDay = {
                greenpath: ["#dfe8df", "#ecefe9", "#276e40", "#4d8a5e", "#cddbc9", "#bdd1b8"],
                night: ["#ced6e6", "#e2e6ef", "#8a6818", "#43587a", "#bec7da", "#aeb9cf"],
                cloud: ["#e2e4ea", "#eeeef2", "#4a5668", "#6c7a8e", "#d2d6e0", "#c4c9d6"],
                fog: ["#e8dfec", "#f2ecf5", "#8a2e78", "#226e8c", "#d9cbe0", "#cbbad4"],
                tears: ["#dbe4ee", "#eaf0f5", "#0c6399", "#2b7fb3", "#c8d6e6", "#b8cade"],
                edge: ["#dde1e8", "#eceff4", "#465164", "#9e5a1e", "#cbd1dc", "#bcc4d2"],
                crystal: ["#eae0ee", "#f3ecf5", "#8a2878", "#6e2260", "#dbcbe2", "#9e5c94"]
            };
            const lightNight = {
                greenpath: ["#cddce0", "#e2eaec", "#1b6b60", "#3a7a78", "#b9cfd4", "#a8c2c8"],
                night: ["#ced6e6", "#e2e6ef", "#8a6818", "#43587a", "#bec7da", "#aeb9cf"],
                cloud: ["#cfd5e2", "#e2e5ee", "#7a5e22", "#4c5f7d", "#bfc6d6", "#aeb7ca"],
                fog: ["#d5cbe2", "#e6dff0", "#7c2276", "#186484", "#c4b6d6", "#b5a4ca"],
                tears: ["#c8d4e4", "#dde5f0", "#0a4f82", "#9e6f1e", "#b5c5d8", "#a4b6ce"],
                edge: ["#c9d0de", "#dfe4ee", "#37435a", "#9c4d14", "#b8c0d2", "#a8b2c6"],
                crystal: ["#d7cae2", "#e8dff0", "#7c2070", "#581852", "#c5b4d6", "#874882"]
            };
            return (shownNight ? lightNight : lightDay)[scene];
        }
        const darkDay = {
            greenpath: ["#1c4028", "#07120b", "#d2f082", "#62d487", "#0e2417", "#13301e"],
            night: ["#0b1428", "#04060c", "#f0e888", "#9cbce0", "#080f1e", "#101b2e"],
            cloud: ["#1b2536", "#080a10", "#b8cce0", "#6e849e", "#101724", "#151f2e"],
            fog: ["#341740", "#0b0510", "#f5a6e6", "#9be8ff", "#1e0d28", "#251030"],
            tears: ["#0e253d", "#050911", "#6cc9ff", "#bfe8ff", "#091a2e", "#112944"],
            edge: ["#2a313d", "#0c0f15", "#d8e0ec", "#e8a868", "#181d26", "#202632"],
            crystal: ["#2d1338", "#09050e", "#f7a8e8", "#ffe6fa", "#1a0a24", "#963b88"]
        };
        const darkNight = {
            greenpath: ["#081b20", "#03090b", "#8cf5d4", "#47a896", "#051215", "#091c1e"],
            night: ["#0b1428", "#04060c", "#f0e888", "#9cbce0", "#080f1e", "#101b2e"],
            cloud: ["#0a1020", "#03050a", "#e8d88a", "#7892b8", "#070c18", "#0d1424"],
            fog: ["#140926", "#05020a", "#ff8ee8", "#74e8ff", "#0d061a", "#140924"],
            tears: ["#061022", "#02040a", "#5cb4f5", "#f5d48a", "#040b18", "#091528"],
            edge: ["#090d18", "#030408", "#c8d6f0", "#ff9d4a", "#060912", "#0d121f"],
            crystal: ["#12061e", "#040208", "#ff8ee6", "#ffd8fb", "#0b0414", "#6e2268"]
        };
        return (shownNight ? darkNight : darkDay)[scene];
    }
    readonly property string biomeName: ({
        greenpath: "Greenpath",
        night: "Dirtmouth",
        cloud: "Crossroads",
        fog: "Fog Canyon",
        tears: "City of Tears",
        edge: "Kingdom's Edge",
        crystal: "Crystal Peak"
    })[scene] ?? ""
    readonly property color accent: colours[2]
    readonly property color secondary: colours[3]
    readonly property color farColour: colours[4]
    readonly property color midColour: colours[5]
    readonly property int boltIndex: Math.floor(t * 9) % 2
    readonly property real flash: scene === "edge" && ((t * 9) % 1 < 0.028 || ((t * 9) % 1 > 0.055 && (t * 9) % 1 < 0.075)) ? 1 : 0
    readonly property int starCount: {
        if (!shownNight)
            return 0;
        if (scene === "night")
            return 18;
        if (scene === "greenpath" || scene === "cloud" || scene === "crystal")
            return 12;
        return 8;
    }
    readonly property var glowHalos: {
        if (scene === "night")
            return [
                [282, 37, 26, "accent", 0.45],
                [452, 50, 18, "accent", 0.32],
                [176, 24, 22, "secondary", 0.24]
            ];
        if (scene === "edge")
            return shownNight ? [
                [330, 68, 30, "secondary", 0.46],
                [266, 64, 15, "secondary", 0.36],
                [394, 64, 15, "secondary", 0.36]
            ] : [
                [330, 70, 22, "secondary", 0.22]
            ];
        if (!shownNight)
            return [];
        if (scene === "greenpath")
            return [
                [306, 48, 22, "accent", 0.36],
                [204, 53, 14, "accent", 0.24],
                [442, 24, 20, "secondary", 0.22]
            ];
        if (scene === "cloud")
            return [
                [239, 78, 18, "accent", 0.34],
                [404, 49, 22, "accent", 0.42]
            ];
        if (scene === "fog")
            return [
                [308, 56, 28, "accent", 0.34],
                [86, 66, 16, "accent", 0.28],
                [526, 62, 16, "accent", 0.28]
            ];
        if (scene === "tears")
            return [
                [112, 54, 20, "secondary", 0.28],
                [254, 58, 18, "secondary", 0.24],
                [328, 48, 24, "secondary", 0.32],
                [476, 54, 20, "secondary", 0.28]
            ];
        if (scene === "crystal")
            return [
                [232, 72, 24, "accent", 0.34],
                [374, 72, 24, "accent", 0.34],
                [516, 72, 24, "accent", 0.32]
            ];
        return [];
    }

    // Deterministic pseudo-random in [0, 1)
    function rand(i: int): real {
        const x = Math.sin(i * 12.9898 + 78.233) * 43758.5453;
        return x - Math.floor(x);
    }

    function phase(seed: real, speed: real): real {
        return (t * speed + seed) % 1;
    }

    function star4(cx: real, cy: real, r: real): string {
        const ir = r * 0.26;
        return `M ${cx} ${cy - r} L ${cx + ir} ${cy - ir} L ${cx + r} ${cy} L ${cx + ir} ${cy + ir} L ${cx} ${cy + r} L ${cx - ir} ${cy + ir} L ${cx - r} ${cy} L ${cx - ir} ${cy - ir} Z `;
    }

    // Greenpath: organic mossy cavern arches, layered foliage & carved Lore Tablet (600x120)
    function greenpathFar(): string {
        return "M 0 120 L 0 38 Q 42 26 78 52 Q 112 40 142 68 Q 175 56 208 82 Q 252 68 295 88 "
            + "Q 345 70 392 84 Q 428 54 468 68 Q 505 38 545 50 Q 574 28 600 38 L 600 120 Z "
            + "M 155 0 L 178 0 Q 174 36 166 52 Q 159 36 155 0 Z "
            + "M 244 0 L 262 0 Q 259 30 253 42 Q 247 30 244 0 Z "
            + "M 382 0 L 404 0 Q 400 38 393 54 Q 386 38 382 0 Z "
            + "M 476 0 L 494 0 Q 491 28 485 40 Q 479 28 476 0 Z";
    }

    function greenpathMid(): string {
        // Multi-lobed Greenpath moss bushes + ornate horned Lore Tablet (x=306) + mossy waystone (x=204)
        return "M 0 120 L 0 84 Q 20 66 44 80 Q 68 60 98 78 Q 124 66 148 86 Q 170 76 192 94 "
            // Waystone pillar at x=204
            + "L 198 66 Q 204 54 210 66 L 214 94 "
            + "Q 236 78 262 88 Q 278 76 292 88 "
            // Iconic Hollow Knight Lore Tablet at x=306 (flared base, oval body, horned crown)
            + "L 295 62 Q 291 44 298 32 L 294 24 L 301 28 Q 306 24 311 28 L 318 24 L 314 32 Q 321 44 317 62 L 320 88 "
            + "Q 338 74 362 86 Q 388 66 418 82 Q 446 70 472 90 "
            + "Q 498 68 532 82 Q 566 62 600 78 L 600 120 Z";
    }

    function greenpathRunes(): string {
        // Glowing concentric runes on Lore Tablet + waystone orb + luminous moss buds
        return "M 306 37 A 5.5 8.5 0 1 0 306 54 A 5.5 8.5 0 1 0 306 37 Z "
            + "M 306 41 A 2.5 4.5 0 1 1 306 50 A 2.5 4.5 0 1 1 306 41 Z "
            + "M 306 60 A 4 6 0 1 0 306 72 A 4 6 0 1 0 306 60 Z "
            + "M 204 49 A 4.2 4.2 0 1 0 204 57.4 A 4.2 4.2 0 1 0 204 49 Z "
            + "M 82 67 A 2.8 2.8 0 1 0 82 72.6 A 2.8 2.8 0 1 0 82 67 Z "
            + "M 398 70 A 3 3 0 1 0 398 76 A 3 3 0 1 0 398 70 Z "
            + "M 518 72 A 2.6 2.6 0 1 0 518 77.2 A 2.6 2.6 0 1 0 518 72 Z";
    }

    function greenpathFrame(): string {
        return "M 0 0 L 600 0 L 600 22 Q 555 10 518 18 Q 470 5 410 13 Q 340 3 260 11 Q 180 3 110 15 Q 55 7 0 24 Z "
            + "M 0 120 L 0 102 Q 28 90 56 104 Q 88 92 122 108 Q 162 96 202 108 Q 252 96 298 108 "
            + "Q 345 96 396 108 Q 445 94 492 106 Q 545 92 600 102 L 600 120 Z";
    }

    // Dirtmouth (night): King's Pass crags, crooked shell-houses, open town well, ornate bench & streetlamps
    function nightFar(): string {
        return "M 0 120 L 0 56 Q 32 46 58 68 L 84 72 "
            // Left Dirtmouth shell-house with horned roof
            + "Q 86 42 112 38 L 108 28 L 116 36 Q 124 36 132 28 L 128 38 Q 154 42 156 72 "
            + "L 182 76 Q 188 52 210 50 Q 232 52 238 78 L 462 78 "
            // Right Dirtmouth shell-house
            + "Q 466 44 492 40 L 488 30 L 496 38 L 504 30 L 500 40 Q 526 44 530 70 "
            + "Q 562 50 600 44 L 600 120 Z";
    }

    function nightMid(): string {
        return "M 0 120 L 0 98 Q 140 94 250 100 Q 310 98 370 102 Q 480 96 600 98 L 600 120 Z "
            // Main Lumafly streetlamp at x=260
            + "M 258 102 L 259 38 Q 260 22 273 22 Q 282 22 283 31 L 281 31 Q 280 25 273 25 Q 262 25 262 38 L 261 102 Z "
            + "M 276 31 L 288 31 L 285 43 L 279 43 Z "
            // Distant streetlamp at x=436
            + "M 435 100 L 436 52 Q 436 40 446 40 Q 452 40 453 46 L 451 46 Q 450 42 446 42 Q 438 42 438 52 L 437 100 Z "
            + "M 449 46 L 455 46 L 454 54 L 450 54 Z "
            // Dirtmouth ornate wrought-iron bench (x=286..334, y=76..101)
            + "M 285 91 L 335 91 L 335 94 L 285 94 Z "
            + "M 285 86 Q 281 86 281 90 L 285 92 Z M 335 86 Q 339 86 339 90 L 335 92 Z "
            + "M 290 94 L 288 102 L 291 102 L 293 94 Z M 330 94 L 332 102 L 329 102 L 327 94 Z "
            + "M 289 91 L 289 82 Q 310 73 331 82 L 331 91 L 328 91 L 328 84 Q 310 77 292 84 L 292 91 Z "
            + "M 299 81 L 299 91 L 301 91 L 301 81 Z M 319 81 L 319 91 L 321 91 L 321 81 Z "
            + "M 310 74 L 314 81 L 310 88 L 306 81 Z "
            // Dirtmouth Open Town Well (x=376..412): stone curb, two thin iron posts, peaked roof & chain
            + "M 378 94 L 410 94 L 410 100 L 378 100 Z "
            + "M 381 66 L 383 66 L 383 94 L 381 94 Z M 405 66 L 407 66 L 407 94 L 405 94 Z "
            + "M 374 66 L 394 52 L 394 47 L 394 52 L 414 66 L 409 66 L 394 56 L 379 66 Z "
            + "M 393.5 56 L 394.5 56 L 394.5 94 L 393.5 94 Z";
    }

    function nightLights(): string {
        // Glowing streetlamp bulbs + warm Dirtmouth house windows
        return "M 282 33 A 3.2 4.2 0 1 0 282 41.4 A 3.2 4.2 0 1 0 282 33 Z "
            + "M 452 47 A 2.2 3 0 1 0 452 53 A 2.2 3 0 1 0 452 47 Z "
            + "M 116 50 A 4 5 0 1 0 116 60 A 4 5 0 1 0 116 50 Z "
            + "M 206 58 A 3 4 0 1 0 206 66 A 3 4 0 1 0 206 58 Z "
            + "M 494 52 A 3.5 4.5 0 1 0 494 61 A 3.5 4.5 0 1 0 494 52 Z";
    }

    // Crossroads / Howling Cliffs (cloud): vaulted cavern pillars, single-contour horned shell & signpost
    function cloudFar(): string {
        return "M 0 0 L 600 0 L 600 20 Q 540 24 518 60 L 518 120 L 492 120 L 492 60 Q 470 22 410 22 "
            + "Q 350 22 332 58 L 332 120 L 308 120 L 308 58 Q 290 22 230 22 "
            + "Q 170 22 152 60 L 152 120 L 126 120 L 126 60 Q 104 24 0 20 Z";
    }

    function cloudMid(): string {
        // Single unified contour for the Ancient Horned Shell + Hallownest signpost + monoliths
        return "M 0 120 L 0 94 L 95 98 L 162 94 L 164 70 Q 170 62 176 70 L 178 95 L 204 96 "
            // Seamless Horned Ancestral Beast Shell (x=204..274)
            + "Q 206 80 214 70 Q 200 50 194 34 Q 208 46 223 64 Q 239 58 255 64 Q 270 46 284 34 Q 278 50 264 70 Q 272 80 274 96 "
            + "L 350 96 L 380 96 "
            // Crooked Hallownest iron signpost at x=382
            + "L 381 48 L 360 45 L 353 41 L 361 39 L 381 42 L 382 31 L 385 42 L 405 38 L 412 42 L 404 45 L 384 48 L 383 96 "
            + "L 442 94 L 445 64 Q 451 55 457 64 L 459 94 L 530 98 L 600 90 L 600 120 Z";
    }

    function cloudDetails(): string {
        // Glowing eye sockets on the Ancient Horned Shell (+ hanging signpost Lumafly lantern at night)
        let d = "M 226 74 A 3.5 5 0 1 0 226 84 A 3.5 5 0 1 0 226 74 Z "
            + "M 252 74 A 3.5 5 0 1 0 252 84 A 3.5 5 0 1 0 252 74 Z";
        if (shownNight)
            d += " M 404 44 L 404.8 44 L 404.8 47 L 404 47 Z "
                + "M 404.4 47 A 2.6 3.5 0 1 0 404.4 54 A 2.6 3.5 0 1 0 404.4 47 Z";
        return d;
    }

    // Fog Canyon (fog): Teacher's Archives ribbed dome, floor-to-ceiling specimen tubes & coral stalks
    function fogFar(): string {
        return "M 0 0 L 600 0 L 600 24 Q 545 14 516 44 L 516 120 L 496 120 L 496 0 L 474 0 L 474 120 "
            // Teacher's Archives dome & spires in center (x=250..366)
            + "L 378 120 L 378 58 L 374 42 L 370 58 L 362 58 A 54 46 0 0 0 254 58 L 246 58 L 242 42 L 238 58 L 238 120 "
            // Left specimen tube from ceiling to floor
            + "L 138 120 L 138 0 L 116 0 L 116 120 L 96 120 L 96 44 Q 65 14 0 24 Z";
    }

    function fogMid(): string {
        // Organic canyon floor + bubble-plant stems
        return "M 0 120 L 0 92 Q 42 82 84 96 L 84 72 L 89 72 L 89 96 "
            + "Q 142 86 196 98 L 196 76 L 201 76 L 201 98 "
            + "Q 255 90 308 100 Q 362 90 416 98 L 416 72 L 421 72 L 421 98 "
            + "Q 472 86 524 96 L 524 68 L 529 68 L 529 96 Q 565 84 600 90 L 600 120 Z";
    }

    function fogBulbs(): string {
        // Glowing round acid-pink bulbs atop the Fog Canyon stalks + Teacher's Archives arched windows
        return "M 86.5 58 A 8 8 0 1 0 86.5 74 A 8 8 0 1 0 86.5 58 Z "
            + "M 198.5 64 A 7 7 0 1 0 198.5 78 A 7 7 0 1 0 198.5 64 Z "
            + "M 418.5 59 A 7.5 7.5 0 1 0 418.5 74 A 7.5 7.5 0 1 0 418.5 59 Z "
            + "M 526.5 54 A 8.5 8.5 0 1 0 526.5 71 A 8.5 7.5 0 1 0 526.5 54 Z "
            // Teacher's Archives glowing tall arched windows
            + "M 303 68 L 303 44 A 5 7 0 0 1 313 44 L 313 68 Z "
            + "M 286 72 L 286 52 A 4 6 0 0 1 294 52 L 294 72 Z "
            + "M 322 72 L 322 52 A 4 6 0 0 1 330 52 L 330 72 Z";
    }

    // City of Tears (tears): slender multi-tiered Gothic skyscrapers, bridges, spires & windows
    function tearsFar(): string {
        const towers = [
            [24, 10, 74], [58, 12, 92], [96, 9, 68], [134, 14, 98], [174, 10, 78],
            [212, 13, 88], [252, 11, 72], [290, 15, 104], [332, 11, 82], [372, 14, 96],
            [412, 10, 74], [452, 13, 90], [494, 12, 84], [534, 14, 98], [574, 10, 76]
        ];
        let d = "M 0 120 ";
        for (let i = 0; i < towers.length; i++) {
            const cx = towers[i][0];
            const hw = towers[i][1];
            const top = 120 - towers[i][2];
            d += `L ${cx - hw} 120 L ${cx - hw} ${top + 14} L ${cx - hw * 0.5} ${top + 6} L ${cx} ${top - 12} L ${cx + hw * 0.5} ${top + 6} L ${cx + hw} ${top + 14} L ${cx + hw} 120 `;
        }
        return d + "L 600 120 Z";
    }

    function tearsMid(): string {
        // Slender tiered Gothic towers connected by high sky-bridges
        const towers = [
            [40, 14, 82], [112, 16, 94], [184, 13, 74], [254, 15, 88],
            [328, 18, 100], [404, 14, 78], [476, 17, 92], [548, 14, 80]
        ];
        let d = "M 0 120 L 0 98 ";
        for (let i = 0; i < towers.length; i++) {
            const cx = towers[i][0];
            const hw = towers[i][1];
            const top = 120 - towers[i][2];
            // Stepped Gothic tower with side pinnacles & tall central needle spire
            d += `L ${cx - hw - 3} 98 L ${cx - hw - 3} ${top + 34} L ${cx - hw} ${top + 30} `
                + `L ${cx - hw} ${top + 14} L ${cx - hw - 1} ${top + 6} L ${cx - hw + 3} ${top + 14} `
                + `L ${cx - hw * 0.45} ${top + 4} L ${cx} ${top - 18} L ${cx + hw * 0.45} ${top + 4} `
                + `L ${cx + hw - 3} ${top + 14} L ${cx + hw + 1} ${top + 6} L ${cx + hw} ${top + 14} `
                + `L ${cx + hw} ${top + 30} L ${cx + hw + 3} ${top + 34} L ${cx + hw + 3} 98 `;
            // High arched aqueduct bridge to next tower
            if (i < towers.length - 1) {
                const ncx = towers[i + 1][0];
                const nhw = towers[i + 1][1];
                d += `L ${cx + hw + 3} 78 Q ${(cx + ncx) / 2} 68 ${ncx - nhw - 3} 78 L ${ncx - nhw - 3} 98 `;
            }
        }
        return d + "L 600 98 L 600 120 Z";
    }

    function tearsWindows(): string {
        // Slender lancet stained-glass windows inside the 8 Gothic towers
        const towers = [
            [40, 82], [112, 94], [184, 74], [254, 88],
            [328, 100], [404, 78], [476, 92], [548, 80]
        ];
        let d = "";
        for (let i = 0; i < towers.length; i++) {
            const cx = towers[i][0];
            const top = 120 - towers[i][1] + 12;
            // Upper rose/lancet window
            d += `M ${cx - 2.2} ${top + 15} L ${cx - 2.2} ${top + 4} A 2.2 3.5 0 0 1 ${cx + 2.2} ${top + 4} L ${cx + 2.2} ${top + 15} Z `;
            // Twin tall lower lancets
            d += `M ${cx - 6} ${top + 38} L ${cx - 6} ${top + 21} A 1.8 3 0 0 1 ${cx - 2.4} ${top + 21} L ${cx - 2.4} ${top + 38} Z `;
            d += `M ${cx + 2.4} ${top + 38} L ${cx + 2.4} ${top + 21} A 1.8 3 0 0 1 ${cx + 6} ${top + 21} L ${cx + 6} ${top + 38} Z `;
        }
        return d;
    }

    function tearsStalactites(): string {
        let d = "M 0 0 L 600 0 L 600 14 ";
        for (let x = 580; x >= 10; x -= 24) {
            const i = Math.round(x / 24);
            const h = 10 + rand(i + 20) * 18;
            d += `L ${x + 8} 8 L ${x} ${h} L ${x - 8} 8 `;
        }
        d += "L 0 14 Z M 0 120 L 0 108 L 600 108 L 600 120 Z ";
        for (let x = 18; x < 590; x += 18)
            d += `M ${x} 108 L ${x} 99 L ${x + 1.5} 96 L ${x + 3} 99 L ${x + 3} 108 Z `;
        return d + "M 0 100 L 600 100 L 600 101.5 L 0 101.5 Z";
    }

    // Kingdom's Edge (edge): Wyrm's Cast-Off Shell ribs, Colosseum of Fools horned skull arena & Fool's pikes (600x120)
    function edgeFar(): string {
        return "M 0 120 L 0 26 L 24 34 L 40 24 L 54 44 L 78 38 L 96 58 L 130 52 L 156 72 "
            + "L 192 68 L 222 86 L 258 80 L 292 92 L 336 84 L 378 90 L 418 76 L 452 60 "
            + "L 478 66 L 506 42 L 534 48 L 562 28 L 584 34 L 600 22 L 600 120 Z "
            // Curved colossal Wyrm Cast-Off Shell carapace ribs arching from left & right cliffs
            + "M 12 46 Q 28 14 56 12 Q 36 24 26 52 Z "
            + "M 52 54 Q 68 24 94 22 Q 76 34 66 58 Z "
            + "M 498 54 Q 518 22 548 16 Q 528 30 516 58 Z "
            + "M 540 44 Q 560 14 588 10 Q 570 24 558 48 Z";
    }

    function edgeMid(): string {
        return "M 0 120 L 0 82 L 34 86 L 68 78 L 106 88 L 144 82 L 176 92 L 204 86 L 246 94 "
            // Left Colosseum brazier pillar (x=266)
            + "L 262 94 L 264 74 L 260 69 L 272 69 L 268 74 L 270 94 "
            // Colosseum of Fools stepped base & horned beetle-skull dome (x=278..382, cx=330)
            + "L 278 94 L 282 76 L 288 72 L 290 50 "
            + "Q 278 36 276 18 Q 282 12 288 16 Q 286 30 300 42 "
            + "Q 314 34 325 34 L 330 24 L 335 34 Q 346 34 360 42 "
            + "Q 374 30 372 16 Q 378 12 384 18 Q 382 36 370 50 "
            + "L 372 72 L 378 76 L 382 94 "
            // Right Colosseum brazier pillar (x=394)
            + "L 390 94 L 392 74 L 388 69 L 400 69 L 396 74 L 398 94 "
            + "L 422 92 L 456 84 L 494 90 L 534 80 L 568 86 L 600 76 L 600 120 Z "
            // Hanging iron Fool's cage gallows on left chasm ledge (x=218)
            + "M 216 90 L 217 42 Q 218 35 227 35 L 234 35 L 234 37 L 227 37 Q 220 37 220 43 L 219 90 Z "
            + "M 232 37 L 233 37 L 233 50 L 232 50 Z "
            + "M 227 50 L 238 50 L 236 63 L 229 63 Z "
            // Weathered Fool's battle pikes on right ridge (x=442, x=476)
            + "M 441 88 L 442 52 L 444 52 L 445 88 Z "
            + "M 437 60 L 443 56 L 449 60 L 443 58 Z "
            + "M 475 90 L 476 60 L 478 60 L 479 90 Z "
            + "M 472 67 L 477 63 L 482 67 L 477 65 Z";
    }

    function edgeDetails(): string {
        // Colosseum glowing beetle eye-sockets, grand arched arena entrance & twin brazier flames
        return "M 304 56 Q 311 49 319 54 Q 316 62 308 62 Q 303 60 304 56 Z "
            + "M 356 56 Q 349 49 341 54 Q 344 62 352 62 Q 357 60 356 56 Z "
            + "M 321 90 L 321 72 A 9 11 0 0 1 339 72 L 339 90 Z "
            + "M 263 68 Q 266 58 269 68 Q 266 71 263 68 Z "
            + "M 391 68 Q 394 58 397 68 Q 394 71 391 68 Z";
    }

    function edgeFrame(): string {
        return "M 0 0 L 600 0 L 600 20 L 552 12 L 496 22 L 434 10 L 372 16 L 306 8 L 242 16 L 184 10 L 122 22 L 62 12 L 0 22 Z "
            + "M 0 120 L 0 98 L 48 106 L 98 96 L 154 108 L 214 100 L 274 108 L 330 102 L 388 108 L 448 98 L 508 108 L 558 96 L 600 104 L 600 120 Z";
    }

    // Crystal Peak (crystal): multi-layered prism clusters & mining beams (600x120)
    function crystalFar(): string {
        // Distant background crystal spires & mining support beams
        return "M 0 0 L 600 0 L 600 16 L 540 10 L 470 18 L 390 8 L 310 14 L 220 8 L 130 16 L 50 10 L 0 18 Z "
            + "M 70 120 L 70 28 L 75 28 L 75 120 Z M 528 120 L 528 32 L 533 32 L 533 120 Z "
            + "M 140 120 L 152 54 L 166 120 Z M 204 120 L 196 62 L 218 120 Z "
            + "M 342 120 L 354 52 L 368 120 Z M 426 120 L 418 58 L 438 120 Z";
    }

    function crystalBase(): string {
        const bot = [
            [26, 22, 54, -8], [52, 16, 38, 6], [96, 28, 72, 10], [122, 18, 46, -6],
            [176, 24, 58, 8], [232, 32, 82, -10], [260, 20, 52, 9], [318, 22, 50, -5],
            [374, 30, 78, 9], [404, 20, 48, -8], [456, 26, 64, -7], [516, 32, 80, -9],
            [546, 20, 50, 8], [582, 22, 56, -6]
        ];
        let d = "";
        for (let i = 0; i < bot.length; i++) {
            const cx = bot[i][0];
            const hw = bot[i][1] / 2;
            const h = bot[i][2];
            const lean = bot[i][3];
            const tx = cx + lean;
            const ty = 120 - h;
            d += `M ${cx - hw} 120 L ${cx - hw * 0.75 + lean * 0.65} ${ty + h * 0.22} L ${tx} ${ty} L ${cx + hw * 0.75 + lean * 0.65} ${ty + h * 0.22} L ${cx + hw} 120 Z `;
        }
        const top = [
            [68, 18, 38, 5], [148, 22, 46, -6], [286, 24, 50, 6],
            [346, 16, 34, -4], [430, 22, 44, 5], [492, 18, 36, -5]
        ];
        for (let i = 0; i < top.length; i++) {
            const cx = top[i][0];
            const hw = top[i][1] / 2;
            const h = top[i][2];
            const lean = top[i][3];
            const tx = cx + lean;
            d += `M ${cx - hw} 0 L ${cx - hw * 0.7 + lean * 0.65} ${h * 0.78} L ${tx} ${h} L ${cx + hw * 0.7 + lean * 0.65} ${h * 0.78} L ${cx + hw} 0 Z `;
        }
        return d;
    }

    function crystalFacets(): string {
        // Lit prism facets on both bottom and top crystals
        const bot = [
            [26, 22, 54, -8], [52, 16, 38, 6], [96, 28, 72, 10], [122, 18, 46, -6],
            [176, 24, 58, 8], [232, 32, 82, -10], [260, 20, 52, 9], [318, 22, 50, -5],
            [374, 30, 78, 9], [404, 20, 48, -8], [456, 26, 64, -7], [516, 32, 80, -9],
            [546, 20, 50, 8], [582, 22, 56, -6]
        ];
        let d = "";
        for (let i = 0; i < bot.length; i++) {
            const cx = bot[i][0];
            const hw = bot[i][1] / 2;
            const h = bot[i][2];
            const lean = bot[i][3];
            const tx = cx + lean;
            const ty = 120 - h;
            d += `M ${cx - hw} 120 L ${cx - hw * 0.75 + lean * 0.65} ${ty + h * 0.22} L ${tx} ${ty} L ${cx + lean * 0.25} 120 Z `;
        }
        const top = [
            [68, 18, 38, 5], [148, 22, 46, -6], [286, 24, 50, 6],
            [346, 16, 34, -4], [430, 22, 44, 5], [492, 18, 36, -5]
        ];
        for (let i = 0; i < top.length; i++) {
            const cx = top[i][0];
            const hw = top[i][1] / 2;
            const h = top[i][2];
            const lean = top[i][3];
            const tx = cx + lean;
            d += `M ${cx - hw} 0 L ${cx - hw * 0.7 + lean * 0.65} ${h * 0.78} L ${tx} ${h} L ${cx + lean * 0.25} 0 Z `;
        }
        return d;
    }

    function crystalFrame(): string {
        return "M 0 0 L 600 0 L 600 16 L 540 10 L 470 18 L 390 8 L 310 14 L 220 8 L 130 16 L 50 10 L 0 18 Z "
            + "M 0 120 L 0 102 L 44 108 L 110 98 L 168 108 L 245 100 L 315 108 L 390 100 L 460 108 L 530 100 L 600 104 L 600 120 Z";
    }

    visible: NotchSettings.values.animWeather
    radius: 14
    color: colours[1]
    border.width: 1
    border.color: Hallownest.border

    NumberAnimation on t {
        running: root.running
        loops: Animation.Infinite
        from: 0
        to: 1
        duration: 60000
    }

    // Deep vertical cavern sky gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.colours[0]
            }
            GradientStop {
                position: 0.65
                color: Qt.tint(root.colours[1], Qt.alpha(root.colours[0], 0.45))
            }
            GradientStop {
                position: 1
                color: root.colours[1]
            }
        }
    }

    // Soft central atmospheric glow
    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.55
        height: parent.height * 0.9
        radius: height / 2
        color: Qt.alpha(root.scene === "edge" && root.shownNight ? root.secondary : root.accent, root.scene === "fog" || root.scene === "crystal" ? 0.16 : root.shownNight ? 0.12 : 0.1)
        layer.enabled: root.visible
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1
            blurMax: 56
        }
    }

    // Greenpath: volumetric sunbeams (day) or silvery moonbeams (night) slanting from cavern openings
    Item {
        anchors.fill: parent
        visible: root.scene === "greenpath"
        layer.enabled: visible
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 0.75
            blurMax: 24
        }

        Repeater {
            model: root.scene === "greenpath" ? 5 : 0

            Rectangle {
                required property int index

                x: root.width * (0.12 + index * 0.18)
                y: -root.height * 0.35
                width: 24 + (index % 3) * 10
                height: root.height * 1.75
                rotation: 22
                opacity: (root.shownNight ? 0.06 : 0.08) + (root.shownNight ? 0.035 : 0.05) * Math.sin((root.t * 18 + index * 0.31) * Math.PI * 2)
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: root.shownNight ? root.secondary : root.accent
                    }
                    GradientStop {
                        position: 0.75
                        color: Qt.alpha(root.accent, root.shownNight ? 0.18 : 0.25)
                    }
                    GradientStop {
                        position: 1
                        color: "transparent"
                    }
                }
            }
        }
    }

    // Crescent moon in clear & moonlit canopy night skies
    Shape {
        id: crescentMoon

        readonly property real mx: (root.scene === "night" ? 176 : 442)
        readonly property real my: 24

        width: 600
        height: 120
        visible: root.scene === "night" || (root.scene === "greenpath" && root.shownNight)
        opacity: root.scene === "night" ? 0.85 : 0.65
        preferredRendererType: Shape.CurveRenderer
        transform: Scale {
            xScale: root.width / 600
            yScale: root.height / 120
        }

        ShapePath {
            fillColor: Hallownest.light ? root.secondary : Hallownest.soul
            strokeWidth: -1

            PathSvg {
                path: `M ${crescentMoon.mx + 4} ${crescentMoon.my - 9} A 9.5 9.5 0 1 0 ${crescentMoon.mx + 10} ${crescentMoon.my + 7} A 7.6 7.6 0 1 1 ${crescentMoon.mx + 4} ${crescentMoon.my - 9} Z`
            }
        }
    }

    // Night skies: twinkling 4-pointed stars in the upper cavern / sky
    Repeater {
        model: root.starCount

        Shape {
            id: nightStar

            required property int index
            readonly property real sx: root.rand(index + 400) * root.width
            readonly property real sy: (0.08 + root.rand(index + 430) * (root.scene === "night" ? 0.45 : 0.34)) * root.height
            readonly property real sr: (root.scene === "night" ? 2 : 1.5) + root.rand(index + 460) * (root.scene === "night" ? 2.8 : 2)
            readonly property real baseOpacity: root.scene === "night" ? 0.25 : root.scene === "fog" || root.scene === "tears" || root.scene === "edge" ? 0.12 : 0.18
            readonly property real pulseOpacity: root.scene === "night" ? 0.7 : root.scene === "fog" || root.scene === "tears" || root.scene === "edge" ? 0.32 : 0.48

            opacity: baseOpacity + pulseOpacity * Math.abs(Math.sin((root.t * (7 + index % 5) + root.rand(index + 490)) * Math.PI * 2))
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: index % 3 === 0 ? root.accent : (Hallownest.light ? root.secondary : Hallownest.soul)
                strokeWidth: -1

                PathSvg {
                    path: root.star4(nightStar.sx, nightStar.sy, nightStar.sr)
                }
            }
        }
    }

    // Far parallax backdrop layer (600x120 scaled)
    Shape {
        width: 600
        height: 120
        preferredRendererType: Shape.CurveRenderer
        transform: Scale {
            xScale: root.width / 600
            yScale: root.height / 120
        }

        ShapePath {
            fillColor: root.farColour
            strokeColor: Qt.alpha(root.scene === "edge" ? root.accent : root.secondary, root.scene === "edge" ? 0.2 + root.flash * 0.38 : 0.18)
            strokeWidth: 0.7

            PathSvg {
                path: {
                    switch (root.scene) {
                    case "greenpath":
                        return root.greenpathFar();
                    case "night":
                        return root.nightFar();
                    case "cloud":
                        return root.cloudFar();
                    case "fog":
                        return root.fogFar();
                    case "tears":
                        return root.tearsFar();
                    case "edge":
                        return root.edgeFar();
                    case "crystal":
                        return root.crystalFar();
                    default:
                        return "";
                    }
                }
            }
        }
    }

    // Soft blurred biome glow halos (streetlamps, lunar aura, Colosseum braziers, night windows & bioluminescence)
    Item {
        anchors.fill: parent
        visible: root.glowHalos.length > 0
        layer.enabled: visible
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1
            blurMax: 40
        }

        Repeater {
            model: root.glowHalos

            Rectangle {
                required property int index
                required property var modelData
                readonly property real lx: modelData[0] / 600 * root.width
                readonly property real ly: modelData[1] / 120 * root.height
                readonly property real r: modelData[2] * (root.height / 120)
                readonly property color haloColour: modelData[3] === "secondary" ? root.secondary : root.accent

                x: lx - r
                y: ly - r
                width: r * 2
                height: r * 2
                radius: r
                color: Qt.alpha(haloColour, modelData[4] + 0.08 * Math.sin((root.t * 24 + index * 0.35) * Math.PI * 2))
            }
        }
    }

    // Kingdom's Edge: forked storm lightning bolts cracking behind the Colosseum of Fools
    Shape {
        width: 600
        height: 120
        visible: root.scene === "edge" && root.flash > 0
        opacity: root.flash * 0.92
        preferredRendererType: Shape.CurveRenderer
        transform: Scale {
            xScale: root.width / 600
            yScale: root.height / 120
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.alpha(root.accent, 0.45)
            strokeWidth: 4.4
            capStyle: ShapePath.RoundCap

            PathSvg {
                path: root.boltIndex === 0
                    ? "M 244 0 L 232 22 L 242 26 L 224 54 L 234 58 L 218 88 M 232 22 L 254 38 L 248 60"
                    : "M 418 0 L 408 24 L 420 28 L 404 56 L 414 60 L 398 86 M 408 24 L 432 42 L 426 62"
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Hallownest.soul
            strokeWidth: 1.8
            capStyle: ShapePath.RoundCap

            PathSvg {
                path: root.boltIndex === 0
                    ? "M 244 0 L 232 22 L 242 26 L 224 54 L 234 58 L 218 88 M 232 22 L 254 38 L 248 60"
                    : "M 418 0 L 408 24 L 420 28 L 404 56 L 414 60 L 398 86 M 408 24 L 432 42 L 426 62"
            }
        }
    }

    // Soft drifting mist / ash-storm cloud bands (cloud, fog, tears, edge)
    Item {
        anchors.fill: parent
        visible: root.scene === "cloud" || root.scene === "fog" || root.scene === "tears" || root.scene === "edge"
        layer.enabled: visible
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1
            blurMax: 44
        }

        Repeater {
            model: 5

            Rectangle {
                required property int index
                readonly property real p: root.phase(root.rand(index + 200), (root.scene === "edge" ? 6 : 2) + index * (root.scene === "edge" ? 1.5 : 0.8))

                x: -width + p * (root.width + width * 2)
                y: root.height * (0.18 + index * 0.15)
                width: root.width * (0.36 + root.rand(index + 210) * 0.28)
                height: 16 + root.rand(index + 220) * 16
                radius: height / 2
                color: Qt.alpha(root.accent, root.scene === "fog" ? 0.22 : root.scene === "cloud" ? 0.18 : root.scene === "edge" ? (root.shownNight ? 0.12 : 0.16) : 0.1)
            }
        }
    }

    // Midground biome architecture & landmarks (600x120 scaled)
    Shape {
        width: 600
        height: 120
        preferredRendererType: Shape.CurveRenderer
        transform: Scale {
            xScale: root.width / 600
            yScale: root.height / 120
        }

        // Main silhouette body
        ShapePath {
            fillColor: root.scene === "crystal" ? Qt.alpha(root.midColour, 0.55) : root.midColour
            strokeColor: Qt.alpha(root.accent, root.scene === "crystal" ? 0.68 : 0.32 + root.flash * 0.48)
            strokeWidth: root.scene === "crystal" ? 1 : 0.8

            PathSvg {
                path: {
                    switch (root.scene) {
                    case "greenpath":
                        return root.greenpathMid();
                    case "night":
                        return root.nightMid();
                    case "cloud":
                        return root.cloudMid();
                    case "fog":
                        return root.fogMid();
                    case "tears":
                        return root.tearsMid();
                    case "edge":
                        return root.edgeMid();
                    case "crystal":
                        return root.crystalBase();
                    default:
                        return "";
                    }
                }
            }
        }

        // Lit details: Lore Tablet runes, Dirtmouth lamps/windows, Crossroads shell eyes/lantern, Fog Canyon bulbs, City of Tears windows, Colosseum eyes/braziers, Crystal facets
        ShapePath {
            fillColor: {
                if (root.scene === "greenpath")
                    return Qt.alpha(root.accent, (root.shownNight ? 0.78 : 0.62) + 0.2 * Math.sin(root.t * Math.PI * 16));
                if (root.scene === "cloud")
                    return Qt.alpha(root.accent, root.shownNight ? 0.72 + 0.2 * Math.sin(root.t * Math.PI * 16) : 0.22);
                if (root.scene === "fog")
                    return Qt.alpha(root.accent, (root.shownNight ? 0.65 : 0.38) + 0.2 * Math.sin(root.t * Math.PI * 14));
                if (root.scene === "tears")
                    return Qt.alpha(root.secondary, (root.shownNight ? 0.78 : 0.52) + 0.16 * Math.sin(root.t * Math.PI * 12));
                if (root.scene === "edge")
                    return Qt.alpha(root.secondary, (root.shownNight ? 0.82 : 0.5) + 0.16 * Math.sin(root.t * Math.PI * 22));
                if (root.scene === "crystal")
                    return Qt.alpha(root.secondary, root.shownNight ? 0.56 : 0.44);
                if (root.scene === "night")
                    return Qt.alpha(root.accent, 0.85);
                return "transparent";
            }
            strokeColor: root.scene === "fog" ? Qt.alpha(root.accent, root.shownNight ? 0.88 : 0.75) : "transparent"
            strokeWidth: root.scene === "fog" ? 0.9 : -1

            PathSvg {
                path: {
                    if (root.scene === "greenpath")
                        return root.greenpathRunes();
                    if (root.scene === "cloud")
                        return root.cloudDetails();
                    if (root.scene === "fog")
                        return root.fogBulbs();
                    if (root.scene === "tears")
                        return root.tearsWindows();
                    if (root.scene === "edge")
                        return root.edgeDetails();
                    if (root.scene === "crystal")
                        return root.crystalFacets();
                    if (root.scene === "night")
                        return root.nightLights();
                    return "";
                }
            }
        }
    }

    // Greenpath: swaying hanging moss vines with leaf pairs along the stem
    Repeater {
        model: root.scene === "greenpath" ? 9 : 0

        Shape {
            id: vine

            required property int index
            readonly property real vx: (38 + index * 66 + root.rand(index + 50) * 18) * (root.width / 600)
            readonly property real vh: (28 + root.rand(index + 70) * 34) * (root.height / 120)
            readonly property real sway: Math.sin((root.t * 10 + index * 0.4) * Math.PI * 2) * 5

            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: Hallownest.isMono || Hallownest.light ? Qt.alpha(root.secondary, index % 2 === 0 ? 0.65 : 0.48) : Qt.tint(root.farColour, Qt.alpha(root.secondary, index % 2 === 0 ? 0.4 : 0.24))
                strokeWidth: 1.5
                capStyle: ShapePath.RoundCap

                PathSvg {
                    path: `M ${vine.vx} 0 Q ${vine.vx + vine.sway * 0.5} ${vine.vh * 0.5} ${vine.vx + vine.sway} ${vine.vh}`
                }
            }

            ShapePath {
                fillColor: Qt.alpha(root.secondary, 0.6)
                strokeWidth: -1

                PathSvg {
                    path: {
                        const mx = vine.vx + vine.sway * 0.5;
                        const my = vine.vh * 0.55;
                        const tx = vine.vx + vine.sway;
                        const ty = vine.vh;
                        return `M ${mx} ${my} Q ${mx + 5} ${my - 2} ${mx + 4} ${my + 3} Q ${mx} ${my + 2} ${mx} ${my} Z `
                            + `M ${mx} ${my + 3} Q ${mx - 5} ${my + 1} ${mx - 4} ${my + 6} Q ${mx} ${my + 5} ${mx} ${my + 3} Z `
                            + `M ${tx} ${ty} Q ${tx + 4} ${ty - 2} ${tx + 1} ${ty + 5} Q ${tx - 3} ${ty} ${tx} ${ty} Z`;
                    }
                }
            }
        }
    }

    // Cloud (Crossroads): hanging iron chains with link rings swaying in the draft
    Repeater {
        model: root.scene === "cloud" ? 5 : 0

        Shape {
            id: chain

            required property int index
            readonly property real cx: (92 + index * 104) * (root.width / 600)
            readonly property int links: 5 + (index % 3) * 2
            readonly property real sway: Math.sin((root.t * 8 + index * 0.5) * Math.PI * 2) * 3.5

            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha(root.secondary, 0.62)
                strokeWidth: 1.3
                capStyle: ShapePath.RoundCap

                PathSvg {
                    path: {
                        let d = "";
                        for (let i = 0; i < chain.links; i++) {
                            const frac = i / chain.links;
                            const lx = chain.cx + chain.sway * frac * frac;
                            const ly = 4 + i * 6.2;
                            d += `M ${lx} ${ly} A 1.8 2.8 0 1 0 ${lx} ${ly + 5.2} A 1.8 2.8 0 1 0 ${lx} ${ly} `;
                        }
                        return d;
                    }
                }
            }
        }
    }

    // Fog Canyon: authentic Ooma & Uoma jellyfish with undulating tentacles
    Repeater {
        model: root.scene === "fog" ? 6 : 0

        Shape {
            id: ooma

            required property int index
            readonly property real seed: root.rand(index + 300)
            readonly property bool large: index % 2 === 0
            readonly property real s: large ? 1 : 0.62
            readonly property real wave: Math.sin((root.t * 12 + seed) * Math.PI * 2)

            x: root.width * (0.1 + index * 0.16) + Math.sin((root.t * 5 + seed) * Math.PI * 2) * 8
            y: root.height * (0.22 + (index % 3) * 0.18) + wave * 7
            preferredRendererType: Shape.CurveRenderer

            // Translucent outer bell
            ShapePath {
                fillColor: Qt.alpha(root.accent, 0.2)
                strokeColor: Qt.alpha(root.accent, 0.78)
                strokeWidth: 1.2

                PathSvg {
                    path: {
                        const r = 10 * ooma.s;
                        return `M ${-r} 0 A ${r} ${r * 0.95} 0 1 1 ${r} 0 Q ${r * 0.5} ${2.5 * ooma.s} 0 0 Q ${-r * 0.5} ${2.5 * ooma.s} ${-r} 0 Z`;
                    }
                }
            }

            // Glowing orange-pink inner nucleus
            ShapePath {
                fillColor: Qt.alpha(ooma.large ? (Hallownest.isMono || Hallownest.light ? root.accent : Qt.tint(root.accent, Qt.alpha(Hallownest.soul, 0.3))) : root.secondary, 0.8)
                strokeWidth: -1

                PathSvg {
                    path: {
                        const r = 4.2 * ooma.s;
                        return `M ${-r} ${-2 * ooma.s} A ${r} ${r} 0 1 0 ${r} ${-2 * ooma.s} A ${r} ${r} 0 1 0 ${-r} ${-2 * ooma.s} Z`;
                    }
                }
            }

            // Trailing wavy tentacles
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha(root.accent, 0.58)
                strokeWidth: 1
                capStyle: ShapePath.RoundCap

                PathSvg {
                    path: {
                        const s = ooma.s;
                        const w = ooma.wave * 3 * s;
                        let d = "";
                        const count = ooma.large ? 4 : 2;
                        for (let i = 0; i < count; i++) {
                            const tx = (-4.5 + i * (9 / Math.max(1, count - 1))) * s;
                            const len = (13 + (i % 2) * 4) * s;
                            d += `M ${tx} ${1 * s} Q ${tx + w} ${len * 0.5} ${tx - w * 0.6} ${len} `;
                        }
                        return d;
                    }
                }
            }
        }
    }

    // Fog Canyon: rising luminescent bubbles
    Repeater {
        model: root.scene === "fog" ? 12 : 0

        Rectangle {
            required property int index
            readonly property real seed: root.rand(index + 350)
            readonly property real p: root.phase(seed, 5 + seed * 4)
            readonly property real d: 3.5 + seed * 5

            x: root.width * (0.06 + seed * 0.88) + Math.sin((p * 3 + seed) * Math.PI * 2) * 6
            y: root.height * (1.05 - p * 1.1)
            width: d
            height: d
            radius: d / 2
            color: Qt.alpha(root.accent, 0.1)
            border.width: 0.8
            border.color: Qt.alpha(root.accent, 0.55 * Math.sin(p * Math.PI))
        }
    }

    // Wandering lumaflies / glowing spores (night, greenpath, cloud)
    Repeater {
        model: root.scene === "night" || root.scene === "greenpath" || root.scene === "cloud" ? (root.shownNight ? 12 : 9) : 0

        Rectangle {
            required property int index
            readonly property real seed: root.rand(index + 500)

            x: root.width * (0.08 + seed * 0.84) + Math.sin((root.t * 5 + seed) * Math.PI * 2) * 32
            y: root.height * (0.22 + root.rand(index + 520) * 0.62) + Math.cos((root.t * 7 + seed) * Math.PI * 2) * 12
            width: 3
            height: 3
            radius: 1.5
            color: root.accent
            opacity: (root.shownNight ? 0.55 : 0.35) + 0.4 * Math.sin((root.t * 26 + seed) * Math.PI * 2)

            Rectangle {
                anchors.centerIn: parent
                width: 11
                height: 11
                radius: 5.5
                color: Qt.alpha(root.accent, root.shownNight ? 0.28 : 0.2)
            }
        }
    }

    // Greenpath: tumbling pointed leaves
    Repeater {
        model: root.scene === "greenpath" ? 8 : 0

        Shape {
            id: leaf

            required property int index
            readonly property real seed: root.rand(index + 600)
            readonly property real p: root.phase(seed, 5 + seed * 4)

            x: -20 + p * (root.width + 40) + Math.sin((p * 3 + seed) * Math.PI * 2) * 14
            y: -12 + p * (root.height + 24)
            rotation: p * 540 * (seed > 0.5 ? 1 : -1)
            opacity: root.shownNight ? 0.62 : 0.8
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Qt.alpha(leaf.seed > 0.6 ? (Hallownest.isMono || Hallownest.light || root.shownNight ? root.accent : "#d8e67a") : (Hallownest.isMono || Hallownest.light || root.shownNight ? root.secondary : "#6fcf7c"), 0.82)
                strokeWidth: -1

                PathSvg {
                    path: "M 0 0 Q 5 -4.2 11 0 Q 5 4.2 0 0 Z"
                }
            }
        }
    }

    // City of Tears: slanted rain streaks & ground splash ripples
    Repeater {
        model: root.scene === "tears" ? 44 : 0

        Rectangle {
            required property int index
            readonly property real seed: root.rand(index + 800)
            readonly property real p: root.phase(seed, 68 + seed * 42)
            readonly property color rainColour: root.shownNight ? root.accent : root.secondary

            x: seed * (root.width + 40) - 20 - p * 20
            y: -16 + p * (root.height + 22)
            width: index % 3 === 0 ? 1.3 : 0.9
            height: 10 + seed * 8
            rotation: 12
            color: Qt.alpha(index % 4 === 0 ? rainColour : Hallownest.lifeblood, 0.3 + seed * 0.35)
        }
    }

    Repeater {
        model: root.scene === "tears" ? 10 : 0

        Rectangle {
            required property int index
            readonly property real seed: root.rand(index + 860)
            readonly property real p: root.phase(seed, 18 + seed * 10)
            readonly property color rippleColour: root.shownNight ? root.accent : root.secondary

            x: (0.08 + seed * 0.84) * root.width - width / 2
            y: root.height - 10 - (index % 3) * 2
            width: 4 + p * 14
            height: (4 + p * 14) * 0.3
            radius: height / 2
            color: "transparent"
            border.width: 0.8
            border.color: Qt.alpha(rippleColour, (1 - p) * 0.55)
        }
    }

    // Kingdom's Edge: tattered Fool's pennants whipping on the right ridge pikes
    Repeater {
        model: root.scene === "edge" ? 2 : 0

        Shape {
            id: pennant

            required property int index
            readonly property real px: (index === 0 ? 444 : 478) * (root.width / 600)
            readonly property real py: (index === 0 ? 55 : 62) * (root.height / 120)
            readonly property real whip: Math.sin((root.t * 36 + index * 0.4) * Math.PI * 2) * 3.5

            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Qt.alpha(root.secondary, root.shownNight ? 0.65 : 0.52)
                strokeWidth: -1

                PathSvg {
                    path: `M ${pennant.px} ${pennant.py} Q ${pennant.px + 9} ${pennant.py - 3 + pennant.whip} ${pennant.px + 18} ${pennant.py + 1 - pennant.whip * 0.7} L ${pennant.px + 13} ${pennant.py + 4 + pennant.whip * 0.4} Q ${pennant.px + 6} ${pennant.py + 5} ${pennant.px} ${pennant.py + 5} Z`
                }
            }
        }
    }

    // Kingdom's Edge: fast wind-gust streaks whipping across the stormy chasm
    Repeater {
        model: root.scene === "edge" ? 7 : 0

        Rectangle {
            required property int index
            readonly property real seed: root.rand(index + 720)
            readonly property real p: root.phase(seed, 34 + seed * 18)

            x: -width + p * (root.width + width * 2)
            y: root.height * (0.14 + seed * 0.68) + Math.sin((p * 2 + seed) * Math.PI * 2) * 4
            width: 34 + seed * 36
            height: 1.1
            radius: 0.55
            rotation: -7
            color: Qt.alpha(root.accent, (0.12 + 0.16 * Math.sin(p * Math.PI)) * (root.shownNight ? 0.9 : 1))
        }
    }

    // Kingdom's Edge: wind-whipped pale Wyrm ash flakes sweeping diagonally through the storm
    Repeater {
        model: root.scene === "edge" ? 36 : 0

        Rectangle {
            required property int index
            readonly property real seed: root.rand(index + 760)
            readonly property real p: root.phase(seed, 16 + seed * 14)

            x: -24 + ((seed + p * 0.72) % 1) * (root.width + 48)
            y: -10 + p * (root.height + 20) + Math.sin((p * 3 + seed) * Math.PI * 2) * 5
            width: 1.8 + seed * 2.4
            height: width * (0.55 + (index % 3) * 0.2)
            radius: height / 2
            rotation: p * 360 * (index % 2 === 0 ? 1 : -1)
            color: index % 5 === 0 ? (Hallownest.light ? root.accent : Hallownest.soul) : root.accent
            opacity: (0.42 + seed * 0.45) * (0.7 + 0.3 * root.flash)
        }
    }

    // Kingdom's Edge: rising amber ember sparks drifting up from the Colosseum & braziers
    Repeater {
        model: root.scene === "edge" ? 6 : 0

        Rectangle {
            required property int index
            readonly property real seed: root.rand(index + 790)
            readonly property real p: root.phase(seed, 12 + seed * 8)
            readonly property real baseX: (index % 3 === 0 ? 266 : index % 3 === 1 ? 330 : 394) / 600 * root.width

            x: baseX + p * 22 + Math.sin((p * 4 + seed) * Math.PI * 2) * 4
            y: (68 / 120) * root.height - p * (root.height * 0.45)
            width: 2.2
            height: 2.2
            radius: 1.1
            color: root.secondary
            opacity: Math.sin(p * Math.PI) * (root.shownNight ? 0.9 : 0.55)
        }
    }

    // Crystal Peak: 4-pointed star glints on crystal tips & falling crystal shards
    Repeater {
        model: root.scene === "crystal" ? 9 : 0

        Shape {
            id: glint

            required property int index
            readonly property var pts: [
                [18, 66], [106, 48], [184, 62], [222, 38], [292, 50],
                [383, 42], [449, 56], [507, 40], [576, 64]
            ]
            readonly property real gx: pts[index][0] * (root.width / 600)
            readonly property real gy: pts[index][1] * (root.height / 120)
            readonly property real gr: 3.5 + 2.5 * Math.abs(Math.sin((root.t * (10 + index * 2) + index * 0.3) * Math.PI * 2))

            opacity: (root.shownNight ? 0.48 : 0.35) + (root.shownNight ? 0.52 : 0.65) * Math.abs(Math.sin((root.t * (10 + index * 2) + index * 0.3) * Math.PI * 2))
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: root.secondary
                strokeWidth: -1

                PathSvg {
                    path: root.star4(glint.gx, glint.gy, glint.gr)
                }
            }
        }
    }

    Repeater {
        model: root.scene === "crystal" ? 26 : 0

        Rectangle {
            required property int index
            readonly property real seed: root.rand(index + 900)
            readonly property real p: root.phase(seed, 9 + seed * 8)

            x: seed * root.width + Math.sin((p * 2 + seed) * Math.PI * 2) * 10
            y: -6 + p * (root.height + 12)
            width: 2.5 + seed * 2.2
            height: width
            rotation: 45
            color: index % 3 === 0 ? root.accent : root.secondary
            opacity: 0.78
        }
    }

    // Foreground dark cavern ceiling & floor frame (600x120 scaled)
    Shape {
        width: 600
        height: 120
        preferredRendererType: Shape.CurveRenderer
        transform: Scale {
            xScale: root.width / 600
            yScale: root.height / 120
        }

        ShapePath {
            fillColor: root.colours[1]
            strokeColor: Qt.alpha(root.accent, 0.22 + root.flash * 0.25)
            strokeWidth: 0.6

            PathSvg {
                path: {
                    if (root.scene === "greenpath")
                        return root.greenpathFrame();
                    if (root.scene === "tears")
                        return root.tearsStalactites();
                    if (root.scene === "edge")
                        return root.edgeFrame();
                    return root.crystalFrame();
                }
            }
        }
    }

    // Kingdom's Edge storm sky flash
    Rectangle {
        anchors.fill: parent
        color: Hallownest.soul
        opacity: root.flash * 0.22
        visible: opacity > 0
    }

    // Keep the text & stats sides readable while showcasing the center artwork
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: Qt.alpha(Hallownest.void_, 0.62)
            }
            GradientStop {
                position: 0.38
                color: Qt.alpha(Hallownest.void_, 0.12)
            }
            GradientStop {
                position: 0.68
                color: Qt.alpha(Hallownest.void_, 0.12)
            }
            GradientStop {
                position: 1
                color: Qt.alpha(Hallownest.void_, 0.52)
            }
        }
    }

    // Subtle Hollow Knight corner filigree tinted to the biome
    Filigree {
        anchors.fill: parent
        radius: root.radius
        inset: 5
        colour: root.accent
        opacity: 0.3
    }
}
