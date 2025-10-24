pragma Singleton

import QtQuick

/**
 * Utility functions for AI service
 */
QtObject {
    id: root

    // From StringUtils - escape single quotes for shell
    function shellSingleQuoteEscape(str) {
        return String(str).replace(/'/g, "'\\''");
    }

    // From FileUtils - remove file:// protocol
    function trimFileProtocol(str) {
        if (typeof str !== "string") return "";
        return String(str).replace(/^file:\/\//, "");
    }

    // From ObjectUtils - convert Qt object to plain JS object
    function toPlainObject(qtObj) {
        if (qtObj === null || typeof qtObj !== "object") return qtObj;

        if (Array.isArray(qtObj)) {
            var result = [];
            for (var i = 0; i < qtObj.length; i++) {
                result.push(toPlainObject(qtObj[i]));
            }
            return result;
        }

        var obj = {};
        for (var key in qtObj) {
            if (qtObj.hasOwnProperty(key) && typeof qtObj[key] !== "function") {
                obj[key] = toPlainObject(qtObj[key]);
            }
        }
        return obj;
    }
}
