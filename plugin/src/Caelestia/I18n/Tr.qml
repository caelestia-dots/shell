pragma Singleton

import Caelestia.I18n

TranslatorInternal {
    // No-op so the flag var isn't optimised away
    function _unused(v: var): void {
    }

    function tr(text: string): string {
        _unused(__trsChanged);
        return _tr(text, "", false);
    }

    function trCtx(text: string, context: string): string {
        _unused(__trsChanged);
        return _tr(text, context, false);
    }

    function trN(text: string, plural: string, n: int): string {
        _unused(__trsChanged);
        return _trN(text, plural, n, "");
    }

    function trCtxN(text: string, plural: string, n: int, context: string): string {
        _unused(__trsChanged);
        return _trN(text, plural, n, context);
    }

    function trMarked(text: string): string {
        _unused(__trsChanged);
        return _tr(text, "", true);
    }
}
