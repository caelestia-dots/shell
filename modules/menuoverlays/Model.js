// Parses menu-network-qr output: a "meta\t<iface>\t<security>\t<ssid>"
// header, then a square 0/1 module matrix. The SSID sits last so it may
// contain tabs. A malformed matrix returns empty rather than rendering a
// code that cannot scan.
// Adapted from Omarchy (MIT License).
function parseQrOutput(raw) {
    const lines = String(raw || "").trim().split(/\r?\n/).filter(line => line !== "");
    const meta = {
        iface: "",
        security: "",
        ssid: ""
    };

    if (lines.length > 0 && lines[0].indexOf("meta\t") === 0) {
        const fields = lines.shift().split("\t");
        meta.iface = fields[1] || "";
        meta.security = fields[2] || "";
        meta.ssid = fields.slice(3).join("\t");
    }

    return {
        meta: meta,
        matrix: parseQrMatrix(lines)
    };
}

function parseQrMatrix(lines) {
    if (lines.length === 0)
        return {
            rows: [],
            size: 0
        };

    const size = lines[0].length;
    if (size !== lines.length)
        return {
            rows: [],
            size: 0
        };

    for (let i = 0; i < lines.length; i++) {
        if (lines[i].length !== size || !/^[01]+$/.test(lines[i]))
            return {
                rows: [],
                size: 0
            };
    }

    return {
        rows: lines,
        size: size
    };
}

if (typeof module !== "undefined") {
    module.exports = {
        parseQrOutput: parseQrOutput,
        parseQrMatrix: parseQrMatrix
    };
}
