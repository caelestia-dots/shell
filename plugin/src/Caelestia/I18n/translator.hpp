#pragma once

#include <qobject.h>
#include <qqmlintegration.h>

#include "pluralrules.hpp"

namespace caelestia::i18n {

class Translator : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(TranslatorInternal)

    Q_PROPERTY(bool __trsChanged READ trsChangedFlag NOTIFY languageChanged)

    Q_PROPERTY(QStringList supportedLanguages READ supportedLanguages CONSTANT)
    Q_PROPERTY(QString language READ language WRITE setLanguageQml NOTIFY languageChanged)

public:
    explicit Translator(QObject* parent = nullptr);

    [[nodiscard]] static bool trsChangedFlag();

    [[nodiscard]] QStringList supportedLanguages() const;
    [[nodiscard]] QString language() const;
    static void setLanguageQml(const QString& language);

    // NOLINTBEGIN(readability-identifier-naming)
    Q_INVOKABLE [[nodiscard]] QString _tr(const QString& text, const QString& context, bool markedOnly) const;
    Q_INVOKABLE [[nodiscard]] QString _trN(
        const QString& text, const QString& plural, int n, const QString& context) const;
    // NOLINTEND(readability-identifier-naming)

    Q_INVOKABLE [[nodiscard]] static QString mark(const QString& text, const QStringList& args = {});
    Q_INVOKABLE [[nodiscard]] static QString markCtx(
        const QString& text, const QString& context, const QStringList& args = {});
    Q_INVOKABLE [[nodiscard]] static QString markN(
        const QString& text, const QString& plural, int n, const QStringList& args = {});
    Q_INVOKABLE [[nodiscard]] static QString markCtxN(
        const QString& text, const QString& plural, int n, const QString& context, const QStringList& args = {});

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
    PluralRules m_plurals;

    [[nodiscard]] static QStringList findSupportedLangs();
    void loadTranslations();
    [[nodiscard]] quint32 readU32(qsizetype offset) const;

    [[nodiscard]] static QByteArray catalogKey(const QString& text, const QString& context);
    [[nodiscard]] static QString segment(QByteArrayView blob, quint32 index);
    [[nodiscard]] QByteArrayView lookupRaw(QByteArrayView key) const;
    [[nodiscard]] QString lookup(QByteArrayView key, quint32 index = 0) const;

    [[nodiscard]] QString translate(const QString& text, const QString& context) const;
    [[nodiscard]] QString translatePlural(
        const QString& text, const QString& plural, int n, const QString& context) const;

    [[nodiscard]] QString langForLocale() const;
    [[nodiscard]] QString resolveLanguage(const QString& language) const;
    void setLanguage(const QString& language);
};

} // namespace caelestia::i18n
