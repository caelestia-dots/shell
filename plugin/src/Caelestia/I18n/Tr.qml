pragma Singleton

import Caelestia.I18n

TranslatorInternal {
    function tr(text: string, context = ""): string {
        __trsChanged;
        return _tr(text, context);
    }
}
