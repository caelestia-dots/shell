#include "translator.hpp"

#include <qdirlisting.h>
#include <qendian.h>
#include <qfile.h>
#include <qloggingcategory.h>

#include <cstring>

#include "config/rootnodes.hpp"
#include "util/i18n.hpp"

namespace {

Q_LOGGING_CATEGORY(lcI18n, "caelestia.i18n", QtInfoMsg)

} // namespace

namespace caelestia::i18n {

using Qt::StringLiterals::operator""_s;

namespace {

constexpr quint32 k_magic = 0x950412de;
constexpr quint32 k_magicSwapped = 0xde120495;
constexpr qsizetype k_headerSize = 28;

// .mo header field offsets
constexpr qsizetype k_countOffset = 8;
constexpr qsizetype k_origsOffset = 12;
constexpr qsizetype k_transOffset = 16;

// Table entries are a uint32 length followed by a uint32 offset
constexpr qsizetype k_entrySize = 8;
constexpr qsizetype k_entryOffsetField = 4;

QString resourceDir() {
    static const QString k_s = u":/qt/qml/Caelestia/I18n/"_s;
    return k_s;
}

} // namespace

Translator::Translator(QObject* parent)
    : QObject(parent)
    , m_supportedLanguages(findSupportedLangs()) {
    auto* const general = config::ConfigSingleton::instance()->general();
    QObject::connect(general, &config::GeneralConfig::languageChanged, this, [this, general]() {
        setLanguage(resolveLanguage(general->language()));
    });

    m_language = resolveLanguage(general->language());
    loadTranslations();
}

bool Translator::trsChangedFlag() {
    return false;
}

QStringList Translator::supportedLanguages() const {
    return m_supportedLanguages;
}

QString Translator::language() const {
    return m_language;
}

QString Translator::_tr(const QString& text, const QString& context, bool markedOnly) const {
    if (m_count == 0 || text.isEmpty())
        return text;

    if (util::i18n::isMarked(text)) {
        if (!context.isEmpty())
            qCWarning(lcI18n) << "Attempted to translate a marked string with context. Ignoring context.";

        const auto& [msg, args] = util::i18n::parseMarked(text);
        const auto translated = lookup(msg.toUtf8());
        auto result = translated.isNull() ? msg : translated;
        for (const auto& arg : args)
            result = result.arg(arg);
        return result;
    }

    if (markedOnly)
        return text; // Don't translate unmarked strings when markedOnly

    const auto key =
        context.isEmpty() ? text.toUtf8() : context.toUtf8() + util::i18n::k_contextSep.toLatin1() + text.toUtf8();
    const auto translated = lookup(key);
    return translated.isNull() ? text : translated;
}

QString Translator::mark(const QString& text) {
    return util::i18n::mark(text);
}

QString Translator::markCtx(const QString& text, const QString& context) {
    return util::i18n::mark(text, context);
}

QStringList Translator::findSupportedLangs() {
    QStringList langs;
    const QDirListing listing(resourceDir(), { u"*.mo"_s }, QDirListing::IteratorFlag::FilesOnly);
    for (const auto& f : listing)
        langs << f.completeBaseName();
    return langs;
}

void Translator::loadTranslations() {
    m_catalog.clear();
    m_count = 0;

    if (m_language.isEmpty())
        return;

    QFile file(resourceDir() + m_language + u".mo"_s);
    if (!file.open(QIODevice::ReadOnly)) {
        qCWarning(lcI18n) << "Failed to open catalog for" << m_language;
        return;
    }

    auto data = file.readAll();
    if (data.size() < k_headerSize) {
        qCWarning(lcI18n) << "Truncated catalog for" << m_language;
        return;
    }

    // Magic read as big endian to find the file's real byte order
    const auto magic = qFromBigEndian<quint32>(data.constData());
    if (magic != k_magic && magic != k_magicSwapped) {
        qCWarning(lcI18n) << "Bad magic in catalog for" << m_language;
        return;
    }

    m_littleEndian = magic == k_magicSwapped;
    m_catalog = std::move(data);

    const auto count = readU32(k_countOffset);
    const auto origs = readU32(k_origsOffset);
    const auto trans = readU32(k_transOffset);

    // Validate tables
    const auto tableSize = k_entrySize * static_cast<qsizetype>(count);
    if (static_cast<qsizetype>(origs) + tableSize > m_catalog.size() ||
        static_cast<qsizetype>(trans) + tableSize > m_catalog.size()) {
        qCWarning(lcI18n) << "Corrupt string tables in catalog for" << m_language;
        m_catalog.clear();
        return;
    }

    m_count = count;
    m_origs = origs;
    m_trans = trans;

    qCDebug(lcI18n) << "Loaded" << m_count << "messages for" << m_language;
}

quint32 Translator::readU32(qsizetype offset) const {
    const auto* raw = m_catalog.constData();
    return m_littleEndian ? qFromLittleEndian<quint32>(raw + offset) : qFromBigEndian<quint32>(raw + offset);
}

QString Translator::lookup(QByteArrayView key) const {
    const auto* raw = m_catalog.constData();

    // Entries are sorted against msgid, so we can use a binary search
    quint32 lo = 0;
    quint32 hi = m_count;
    while (lo < hi) {
        const auto probe = lo + (hi - lo) / 2;
        const auto entry = static_cast<qsizetype>(m_origs) + k_entrySize * probe;
        const auto len = static_cast<qsizetype>(readU32(entry));
        const auto off = static_cast<qsizetype>(readU32(entry + k_entryOffsetField));
        if (off + len > m_catalog.size())
            return {};

        auto cmp = std::memcmp(key.constData(), raw + off, static_cast<size_t>(qMin(key.size(), len)));
        if (cmp == 0 && key.size() != len)
            cmp = key.size() < len ? -1 : 1;

        if (cmp == 0) {
            const auto hit = static_cast<qsizetype>(m_trans) + k_entrySize * probe;
            const auto tlen = static_cast<qsizetype>(readU32(hit));
            const auto toff = static_cast<qsizetype>(readU32(hit + k_entryOffsetField));
            if (toff + tlen > m_catalog.size())
                return {};
            return QString::fromUtf8(raw + toff, tlen);
        }

        if (cmp < 0)
            hi = probe;
        else
            lo = probe + 1;
    }

    return {};
}

QString Translator::langForLocale() const {
    const auto locale = QLocale::system();
    if (m_supportedLanguages.contains(locale.name()))
        return locale.name();
    return {};
}

QString Translator::resolveLanguage(const QString& language) const {
    if (language.isEmpty())
        return langForLocale();

    if (!m_supportedLanguages.contains(language)) {
        qCWarning(lcI18n) << "Unsupported language" << language << "- falling back to the system locale";
        return langForLocale();
    }

    return language;
}

void Translator::setLanguage(const QString& language) {
    if (m_language == language)
        return;

    m_language = language;
    loadTranslations(); // Load before emitting cause trsChangedFlag reuses the signal
    emit languageChanged();
}

} // namespace caelestia::i18n
