// Pure helpers for parsing JSONC menu definitions and merging user overrides
// over the bundled default tree. Kept dependency-free so the logic can be
// tested outside Quickshell as well.

function parseJsonc(text) {
    let out = "";
    let inString = false;
    let escaped = false;

    for (let i = 0; i < text.length; i++) {
        const ch = text[i];
        const next = i + 1 < text.length ? text[i + 1] : "";

        if (inString) {
            out += ch;
            if (escaped) {
                escaped = false;
            } else if (ch === "\\") {
                escaped = true;
            } else if (ch === "\"") {
                inString = false;
            }
            continue;
        }

        if (ch === "\"") {
            inString = true;
            out += ch;
        } else if (ch === "/" && next === "/") {
            i += 2;
            while (i < text.length && text[i] !== "\n")
                i++;
            if (i < text.length)
                out += "\n";
        } else if (ch === "/" && next === "*") {
            i += 2;
            while (i + 1 < text.length && !(text[i] === "*" && text[i + 1] === "/"))
                i++;
            i++;
        } else {
            out += ch;
        }
    }

    return JSON.parse(out.replace(/,(\s*[}\]])/g, "$1"));
}

// Merge user entries on top of the bundled defaults. Existing keys are
// shallow-merged so a user can tweak a single field (for example setting
// `enabled: false` or overriding `action`) without copying the full entry.
// New keys from the user file are appended in declaration order.
function mergeTrees(baseTree, userTree) {
    const merged = {};
    if (baseTree && typeof baseTree === "object") {
        for (const key of Object.keys(baseTree)) {
            const entry = baseTree[key];
            if (entry && typeof entry === "object")
                merged[key] = Object.assign({}, entry);
        }
    }

    if (userTree && typeof userTree === "object") {
        for (const key of Object.keys(userTree)) {
            const entry = userTree[key];
            if (!entry || typeof entry !== "object")
                continue;
            if (merged[key])
                merged[key] = Object.assign({}, merged[key], entry);
            else
                merged[key] = Object.assign({}, entry);
        }
    }

    return merged;
}

function shellQuote(value) {
    return `'${String(value ?? "").replace(/'/g, "'\\''")}'`;
}

if (typeof module !== "undefined") {
    module.exports = {
        parseJsonc: parseJsonc,
        mergeTrees: mergeTrees,
        shellQuote: shellQuote
    };
}
