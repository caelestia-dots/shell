pragma Singleton

import Caelestia
import Caelestia.I18n

TranslatorInternal {
    function tr(text: string): string {
        CUtils.dependency(__trsChanged);
        return _tr(text, "", false);
    }

    function trCtx(text: string, context: string): string {
        CUtils.dependency(__trsChanged);
        return _tr(text, context, false);
    }

    function trN(text: string, plural: string, n: int): string {
        CUtils.dependency(__trsChanged);
        return _trN(text, plural, n, "");
    }

    function trCtxN(text: string, plural: string, n: int, context: string): string {
        CUtils.dependency(__trsChanged);
        return _trN(text, plural, n, context);
    }

    function trMarked(text: string): string {
        CUtils.dependency(__trsChanged);
        return _tr(text, "", true);
    }
}
