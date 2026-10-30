#pragma once

#include <qstring.h>
#include <qstringlist.h>

namespace util::i18n {

inline constexpr QChar k_markChar = u'\x01';
inline constexpr QChar k_argSep = u'\x02';
inline constexpr QChar k_pluralSep = u'\x03';
inline constexpr QChar k_contextSep = u'\x04';

// A marked string split back into its parts
struct MarkedString {
    QString text;
    QString plural;
    QString context;
    QStringList args;
    int n = -1; // Negative when the string has no plural forms
};

// Marks a string for later translation. Args can be marked, however they must not carry args themselves.
QString mark(const QString& text, const QStringList& args = {});
QString markCtx(const QString& text, const QString& context, const QStringList& args = {});
QString markN(const QString& text, const QString& plural, int n, const QStringList& args = {});
QString markCtxN(
    const QString& text, const QString& plural, int n, const QString& context, const QStringList& args = {});

MarkedString parseMarked(const QString& text);
bool isMarked(const QString& text);
QString unmark(const QString& text);

} // namespace util::i18n
