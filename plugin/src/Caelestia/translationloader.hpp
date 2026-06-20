#pragma once

#include <qobject.h>
#include <qqmlengine.h>
#include <qtranslator.h>

namespace caelestia {

// Loads compiled Qt translations (.qm) into the QML engine at startup.
//
// QuickShell drives the shell with a bare QQmlEngine and never installs a
// QTranslator, so qsTr() strings always render as their English source. This
// plugin hooks initializeEngine() (called by Qt when the Caelestia.Internal
// module is loaded) to install a translator for the current system locale.
class TranslationLoader : public QObject {
    Q_OBJECT

public:
    explicit TranslationLoader(QObject* parent = nullptr);

    // Locates a <prefix>_<locale>.qm for the system UI language and installs it.
    // Searches a list of candidate directories; the first match wins.
    void load(QQmlEngine* engine);

private:
    QTranslator m_translator;
};

} // namespace caelestia
