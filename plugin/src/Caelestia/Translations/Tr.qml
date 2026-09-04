pragma Singleton

import Caelestia.Translations

TranslatorInternal {
    function tr(text: string, context = ""): string {
        __trsChanged;
        return _tr(text, context);
    }
}
