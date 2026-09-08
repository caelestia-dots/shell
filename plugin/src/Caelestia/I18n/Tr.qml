pragma Singleton

import Caelestia.I18n

TranslatorInternal {
    function tr(text: string): string {
        __trsChanged;
        return _tr(text, "", false);
    }

    function trCtx(text: string, context: string): string {
        __trsChanged;
        return _tr(text, context, false);
    }

    function trN(text: string, plural: string, n: int): string {
        __trsChanged;
        return _trN(text, plural, n, "");
    }

    function trCtxN(text: string, plural: string, n: int, context: string): string {
        __trsChanged;
        return _trN(text, plural, n, context);
    }

    function trMarked(text: string): string {
        __trsChanged;
        return _tr(text, "", true);
    }
}
