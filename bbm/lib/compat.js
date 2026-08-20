'use strict';
// Context-agnostic shims for GNOME Shell-only APIs.
// When imported inside a running GNOME Shell extension the real implementations
// are loaded; when imported by the standalone GJS daemon the try/catch blocks
// catch the missing resource:// paths and fall back to no-op stubs so all
// device logic continues to work without modification.

// ── Gettext ──────────────────────────────────────────────────────────────────
let _gettext;
try {
    _gettext = (await import('resource:///org/gnome/shell/extensions/extension.js')).gettext;
} catch {
    _gettext = s => s;
}
export const gettext = _gettext;
export const _ = _gettext;

// ── MediaController ───────────────────────────────────────────────────────────
// Used by AirPods, Bose, Galaxy Buds, and Sennheiser devices for
// wear-detection / A2DP output routing. The stub disables those features
// silently when running as a daemon.
let _MediaController;
try {
    _MediaController = (await import('./mediaController.js')).MediaController;
} catch {
    _MediaController = class MediaController {
        constructor() {}
        get output_is_a2dp() { return false; }
        connect() { return 0; }
        disconnect() {}
        destroy() {}
    };
}
export { _MediaController as MediaController };

// ── Notifier ──────────────────────────────────────────────────────────────────
// Used by EnhancedDeviceSupportManager to show a notification when BlueZ
// profile registration fails. Returns null in daemon context so the caller
// can fall back to toggle.notifyCb.
let _Notifier;
try {
    _Notifier = (await import('./devices/notifier.js')).Notifier;
} catch {
    _Notifier = null;
}
export { _Notifier as Notifier };
