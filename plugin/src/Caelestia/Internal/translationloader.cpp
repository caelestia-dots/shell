#include "translationloader.hpp"

#include <qcoreapplication.h>
#include <qdir.h>
#include <qlocale.h>
#include <qloggingcategory.h>
#include <qstandardpaths.h>

namespace caelestia::internal {

namespace {

Q_LOGGING_CATEGORY(lcI18n, "caelestia.internal.i18n", QtInfoMsg)

// Candidate directories to search for compiled translations, in priority order.
// User overrides win over the system-installed location.
QStringList translationDirs() {
    QStringList dirs;

    // Per-user override: ~/.local/share/caelestia/translations
    const auto dataHome = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
    if (!dataHome.isEmpty()) {
        dirs << QDir(dataHome).filePath(QStringLiteral("caelestia/translations"));
    }

    // System install location (set by CMake via CAELESTIA_TRANSLATIONS_DIR).
#ifdef CAELESTIA_TRANSLATIONS_DIR
    dirs << QStringLiteral(CAELESTIA_TRANSLATIONS_DIR);
#endif

    return dirs;
}

} // namespace

TranslationLoader::TranslationLoader(QObject* parent)
    : QObject(parent) {}

void TranslationLoader::load(QQmlEngine* engine) {
    const QLocale locale = QLocale::system();
    const QStringList dirs = translationDirs();

    for (const QString& dir : dirs) {
        // QTranslator::load picks the best match across locale.uiLanguages().
        if (m_translator.load(locale, QStringLiteral("caelestia"), QStringLiteral("_"), dir)) {
            if (QCoreApplication::installTranslator(&m_translator)) {
                qCInfo(lcI18n) << "Loaded translation" << m_translator.filePath();
                if (engine) {
                    engine->retranslate();
                }
                return;
            }
        }
    }

    qCDebug(lcI18n) << "No translation found for locale" << locale.name() << "- using source strings";
}

} // namespace caelestia::internal
