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

    function trMarked(text: string): string {
        __trsChanged;
        return _tr(text, "", true);
    }
}
