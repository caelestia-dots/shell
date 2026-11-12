pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell.Widgets
import qs.components.hallownest
import qs.services

// Animated Hallownest biome banner for the current weather:
// sun = Greenpath, night = Dirtmouth, cloud = Crossroads / Howling Cliffs,
// fog = Fog Canyon, rain/storm = City of Tears, snow = Crystal Peak
ClippingRectangle {
    id: root

    property string kind
    property bool night
    property bool running: visible
    property real t

    readonly property string shownKind: Weather.previewScene === "night" ? "sun" : Weather.previewScene || kind
    readonly property bool shownNight: Weather.previewScene ? Weather.previewScene === "night" : night
    readonly property string scene: {
        if (shownKind === "rain" || shownKind === "storm")
            return "tears";
        if (shownKind === "snow")
            return "crystal";
        if (shownKind === "fog")
            return "fog";
        if (shownNight)
            return "night";
        if (shownKind === "sun" || shownKind === "twilight" || shownKind === "partly")
            return "greenpath";
        return "cloud";
    }
    readonly property var colours: {
        if (Hallownest.isMono) {
            return ({
                greenpath: ["#26282f", "#0f1014", "#e4e5ea", "#b0b2ba", "#17181d", "#1e2026"],
                night: ["#1e2026", "#0b0c0f", "#f0f1f5", "#a8aab2", "#131418", "#191b20"],
                cloud: ["#282a32", "#101115", "#d4d6de", "#989aa4", "#18191f", "#202229"],
                fog: ["#2b2d35", "#0e0f13", "#e6e7ec", "#b8bac2", "#191a20", "#22242b"],
                tears: ["#22242b", "#0c0d11", "#dcdee6", "#a4a6b0", "#14161b", "#1c1e24"],
                crystal: ["#292b33", "#0e0f13", "#ededf2", "#c4c6ce", "#181a20", "#484a54"]
            })[scene];
        }
        if (Hallownest.light) {
            return ({
                greenpath: ["#dfe8df", "#ecefe9", "#276e40", "#4d8a5e", "#cddbc9", "#bdd1b8"],
                night: ["#dce0ea", "#eaecef", "#8a6818", "#4f6280", "#cbd2e0", "#bcc5d6"],
                cloud: ["#e2e4ea", "#eeeef2", "#4a5668", "#6c7a8e", "#d2d6e0", "#c4c9d6"],
                fog: ["#e8dfec", "#f2ecf5", "#8a2e78", "#226e8c", "#d9cbe0", "#cbbad4"],
                tears: ["#dbe4ee", "#eaf0f5", "#0c6399", "#2b7fb3", "#c8d6e6", "#b8cade"],
                crystal: ["#eae0ee", "#f3ecf5", "#8a2878", "#6e2260", "#dbcbe2", "#9e5c94"]
            })[scene];
        }
        return ({
            greenpath: ["#1c4028", "#07120b", "#d2f082", "#62d487", "#0e2417", "#13301e"],
            night: ["#0d172b", "#05070c", "#e8f58c", "#9ab8db", "#09101f", "#111c30"],
            cloud: ["#1b2536", "#080a10", "#b8cce0", "#6e849e", "#101724", "#151f2e"],
            fog: ["#341740", "#0b0510", "#f5a6e6", "#9be8ff", "#1e0d28", "#251030"],
            tears: ["#0e253d", "#050911", "#6cc9ff", "#bfe8ff", "#091a2e", "#112944"],
            crystal: ["#2d1338", "#09050e", "#f7a8e8", "#ffe6fa", "#1a0a24", "#963b88"]
        })[scene];
    }
    readonly property color accent: colours[2]
    readonly property color secondary: colours[3]
    readonly property color farColour: colours[4]
    readonly property color midColour: colours[5]
    readonly property real flash: shownKind === "storm" && ((t * 9) % 1 < 0.028 || ((t * 9) % 1 > 0.055 && (t * 9) % 1 < 0.075)) ? 1 : 0

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
        // Glowing eye sockets on the Ancient Horned Shell
        return "M 226 74 A 3.5 5 0 1 0 226 84 A 3.5 5 0 1 0 226 74 Z "
            + "M 252 74 A 3.5 5 0 1 0 252 84 A 3.5 5 0 1 0 252 74 Z";
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
    radius: 16
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
        color: Qt.alpha(root.accent, root.scene === "fog" || root.scene === "crystal" ? 0.16 : 0.1)
        layer.enabled: root.visible
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1
            blurMax: 56
        }
    }

    // Greenpath: volumetric sunbeams slanting from cavern openings
    Repeater {
        model: root.scene === "greenpath" ? 5 : 0

        Rectangle {
            required property int index

            x: root.width * (0.12 + index * 0.18)
            y: -root.height * 0.35
            width: 22 + (index % 3) * 10
            height: root.height * 1.75
            rotation: 22
            opacity: 0.07 + 0.05 * Math.sin((root.t * 18 + index * 0.31) * Math.PI * 2)
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: root.accent
                }
                GradientStop {
                    position: 0.75
                    color: Qt.alpha(root.secondary, 0.25)
                }
                GradientStop {
                    position: 1
                    color: "transparent"
                }
            }
        }
    }

    // Night: twinkling 4-pointed stars in the upper sky
    Repeater {
        model: root.scene === "night" ? 18 : 0

        Shape {
            id: nightStar

            required property int index
            readonly property real sx: root.rand(index + 400) * root.width
            readonly property real sy: (0.08 + root.rand(index + 430) * 0.45) * root.height
            readonly property real sr: 2 + root.rand(index + 460) * 2.8

            opacity: 0.25 + 0.7 * Math.abs(Math.sin((root.t * (7 + index % 5) + root.rand(index + 490)) * Math.PI * 2))
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: index % 3 === 0 ? root.accent : Hallownest.soul
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
            strokeColor: Qt.alpha(root.secondary, 0.18)
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
                    case "crystal":
                        return root.crystalFar();
                    default:
                        return "";
                    }
                }
            }
        }
    }

    // Dirtmouth: soft blurred lantern halos rendered in front of nightFar so they glow full circle
    Item {
        anchors.fill: parent
        visible: root.scene === "night"
        layer.enabled: visible
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1
            blurMax: 40
        }

        Repeater {
            model: 2

            Rectangle {
                required property int index
                readonly property real lx: (index === 0 ? 282 : 452) / 600 * root.width
                readonly property real ly: (index === 0 ? 37 : 50) / 120 * root.height
                readonly property real r: (index === 0 ? 26 : 18) * (root.height / 120)

                x: lx - r
                y: ly - r
                width: r * 2
                height: r * 2
                radius: r
                color: Qt.alpha(root.accent, (index === 0 ? 0.45 : 0.32) + 0.08 * Math.sin(root.t * Math.PI * 24))
            }
        }
    }

    // City of Tears: forked storm lightning bolt in the sky BEHIND midground towers
    Shape {
        width: 600
        height: 120
        visible: root.scene === "tears" && root.flash > 0
        opacity: root.flash * 0.9
        preferredRendererType: Shape.CurveRenderer
        transform: Scale {
            xScale: root.width / 600
            yScale: root.height / 120
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Hallownest.soul
            strokeWidth: 1.8
            capStyle: ShapePath.RoundCap

            PathSvg {
                path: "M 292 0 L 280 22 L 290 26 L 272 52 L 282 56 L 266 86 M 280 22 L 302 38 L 296 60"
            }
        }
    }

    // Soft drifting mist bands (cloud, fog, tears)
    Item {
        anchors.fill: parent
        visible: root.scene === "cloud" || root.scene === "fog" || root.scene === "tears"
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
                readonly property real p: root.phase(root.rand(index + 200), 2 + index * 0.8)

                x: -width + p * (root.width + width * 2)
                y: root.height * (0.18 + index * 0.15)
                width: root.width * (0.36 + root.rand(index + 210) * 0.28)
                height: 16 + root.rand(index + 220) * 16
                radius: height / 2
                color: Qt.alpha(root.accent, root.scene === "fog" ? 0.22 : root.scene === "cloud" ? 0.18 : 0.1)
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
            strokeColor: Qt.alpha(root.accent, root.scene === "crystal" ? 0.68 : 0.32 + root.flash * 0.45)
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
                    case "crystal":
                        return root.crystalBase();
                    default:
                        return "";
                    }
                }
            }
        }

        // Lit details: Lore Tablet runes, Dirtmouth lamps/windows, Crossroads shell eyes, Fog Canyon bulbs, City of Tears windows, Crystal facets
        ShapePath {
            fillColor: {
                if (root.scene === "greenpath")
                    return Qt.alpha(root.accent, 0.62 + 0.25 * Math.sin(root.t * Math.PI * 16));
                if (root.scene === "cloud")
                    return Qt.alpha(root.accent, 0.22);
                if (root.scene === "fog")
                    return Qt.alpha(root.accent, 0.38 + 0.18 * Math.sin(root.t * Math.PI * 14));
                if (root.scene === "tears")
                    return Qt.alpha(root.secondary, 0.52 + 0.2 * Math.sin(root.t * Math.PI * 12));
                if (root.scene === "crystal")
                    return Qt.alpha(root.secondary, 0.44);
                if (root.scene === "night")
                    return Qt.alpha(root.accent, 0.85);
                return "transparent";
            }
            strokeColor: root.scene === "fog" ? Qt.alpha(root.accent, 0.75) : "transparent"
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
                strokeColor: Hallownest.isMono || Hallownest.light ? Qt.alpha(root.secondary, index % 2 === 0 ? 0.65 : 0.48) : (index % 2 === 0 ? "#2d6640" : "#1f4a2e")
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
                fillColor: Qt.alpha(ooma.large ? (Hallownest.isMono || Hallownest.light ? root.accent : "#ffb8e6") : root.secondary, 0.8)
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
        model: root.scene === "night" || root.scene === "greenpath" || root.scene === "cloud" ? 9 : 0

        Rectangle {
            required property int index
            readonly property real seed: root.rand(index + 500)

            x: root.width * (0.08 + seed * 0.84) + Math.sin((root.t * 5 + seed) * Math.PI * 2) * 32
            y: root.height * (0.22 + root.rand(index + 520) * 0.62) + Math.cos((root.t * 7 + seed) * Math.PI * 2) * 12
            width: 3
            height: 3
            radius: 1.5
            color: root.accent
            opacity: (root.scene === "night" ? 0.55 : 0.35) + 0.4 * Math.sin((root.t * 26 + seed) * Math.PI * 2)

            Rectangle {
                anchors.centerIn: parent
                width: 11
                height: 11
                radius: 5.5
                color: Qt.alpha(root.accent, 0.2)
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
            opacity: 0.8
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Qt.alpha(leaf.seed > 0.6 ? (Hallownest.isMono || Hallownest.light ? root.accent : "#d8e67a") : (Hallownest.isMono || Hallownest.light ? root.secondary : "#6fcf7c"), 0.82)
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

            x: seed * (root.width + 40) - 20 - p * 20
            y: -16 + p * (root.height + 22)
            width: index % 3 === 0 ? 1.3 : 0.9
            height: 10 + seed * 8
            rotation: 12
            color: Qt.alpha(index % 4 === 0 ? root.secondary : Hallownest.lifeblood, 0.3 + seed * 0.35)
        }
    }

    Repeater {
        model: root.scene === "tears" ? 10 : 0

        Rectangle {
            required property int index
            readonly property real seed: root.rand(index + 860)
            readonly property real p: root.phase(seed, 18 + seed * 10)

            x: (0.08 + seed * 0.84) * root.width - width / 2
            y: root.height - 10 - (index % 3) * 2
            width: 4 + p * 14
            height: (4 + p * 14) * 0.3
            radius: height / 2
            color: "transparent"
            border.width: 0.8
            border.color: Qt.alpha(root.secondary, (1 - p) * 0.55)
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

            opacity: 0.35 + 0.65 * Math.abs(Math.sin((root.t * (10 + index * 2) + index * 0.3) * Math.PI * 2))
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
            strokeColor: Qt.alpha(root.accent, 0.22)
            strokeWidth: 0.6

            PathSvg {
                path: {
                    if (root.scene === "greenpath")
                        return root.greenpathFrame();
                    if (root.scene === "tears")
                        return root.tearsStalactites();
                    return root.crystalFrame();
                }
            }
        }
    }

    // Storm sky flash
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
