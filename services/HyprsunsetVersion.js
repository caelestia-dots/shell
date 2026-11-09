.pragma library

// Prior to 0.4.0, "identity get" is interpreted as "identity" (a write).
function parseVersion(output) {
    const version = /\bhyprsunset v?(\d+)\.(\d+)\.(\d+)(?:\s|$)/.exec(output);
    return version ? [Number(version[1]), Number(version[2]), Number(version[3])] : null;
}

function supportsIdentityQuery(output) {
    const version = parseVersion(output);
    return version !== null && (version[0] > 0 || version[1] >= 4);
}
