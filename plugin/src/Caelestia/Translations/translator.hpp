#pragma once

#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia::tr {

class Translator : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(TranslatorInternal)

    Q_PROPERTY(bool __trsChanged READ trsChangedFlag NOTIFY languageChanged)

    Q_PROPERTY(QStringList supportedLanguages READ supportedLanguages)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)

public:
    explicit Translator(QObject* parent = nullptr);

    [[nodiscard]] static bool trsChangedFlag();

    [[nodiscard]] QStringList supportedLanguages() const;
    [[nodiscard]] QString language() const;
    void setLanguage(const QString& language);

    // NOLINTBEGIN(readability-identifier-naming)
    Q_INVOKABLE [[nodiscard]] QString _tr(const QString& text, const QString& context = {}) const;
    Q_INVOKABLE [[nodiscard]] QString _mark(const QString& text, const QString& context = {}) const;
    // NOLINTEND(readability-identifier-naming)

signals:
    void languageChanged();

private:
    const QStringList m_supportedLanguages;
    QString m_language;

    // Raw .mo catalog in binary format
    QByteArray m_catalog;
    bool m_littleEndian = false;
    quint32 m_count = 0;
    quint32 m_origs = 0;
    quint32 m_trans = 0;

    [[nodiscard]] static QStringList findSupportedLangs();
    void loadTranslations();
    [[nodiscard]] quint32 readU32(qsizetype offset) const;
    [[nodiscard]] QString lookup(QByteArrayView key) const;
};

} // namespace caelestia::tr
