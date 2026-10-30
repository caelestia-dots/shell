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

namespace detail {

// Marks a string with the given plural forms, context and args.
// Args can be marked, however they must not carry args themselves.
// The marked format is `markChar {<arg> argSep} [<context> contextSep] <text> [pluralSep <plural> pluralSep <n>]`
inline QString doMark(
    const QString& text, const QString& plural, int n, const QString& context, const QStringList& args) {
    auto len = 1 + text.size();
    if (n >= 0)
        len += plural.size() + 2 + 11; // Two separators + the widest int
    if (!context.isEmpty())
        len += context.size() + 1;
    for (const auto& arg : args)
        len += arg.size() + 1;

    QString result;
    result.reserve(len);
    result += k_markChar;

    for (const auto& arg : args) {
        result += arg;
        result += k_argSep;
    }

    if (!context.isEmpty()) {
        result += context;
        result += k_contextSep;
    }

    result += text;

    if (n >= 0) {
        result += k_pluralSep;
        result += plural;
        result += k_pluralSep;
        result += QString::number(n);
    }

    return result;
}

} // namespace detail

inline QString mark(const QString& text, const QStringList& args = {}) {
    return detail::doMark(text, {}, -1, {}, args);
}

inline QString markCtx(const QString& text, const QString& context, const QStringList& args = {}) {
    return detail::doMark(text, {}, -1, context, args);
}

inline QString markN(const QString& text, const QString& plural, int n, const QStringList& args = {}) {
    return detail::doMark(text, plural, n, {}, args);
}

inline QString markCtxN(
    const QString& text, const QString& plural, int n, const QString& context, const QStringList& args = {}) {
    return detail::doMark(text, plural, n, context, args);
}

inline MarkedString parseMarked(const QString& text) {
    MarkedString marked;
    auto body = text.sliced(1);

    const auto argEnd = body.lastIndexOf(k_argSep);
    if (argEnd >= 0) {
        marked.args = body.first(argEnd).split(k_argSep);
        body = body.sliced(argEnd + 1);
    }

    const auto ctxEnd = body.indexOf(k_contextSep);
    if (ctxEnd >= 0) {
        marked.context = body.first(ctxEnd);
        body = body.sliced(ctxEnd + 1);
    }

    const auto parts = body.split(k_pluralSep);
    marked.text = parts.first();
    if (parts.size() == 3) {
        marked.plural = parts.at(1);
        marked.n = parts.at(2).toInt();
    }

    return marked;
}

inline bool isMarked(const QString& text) {
    return text.startsWith(k_markChar);
}

inline QString unmark(const QString& text) {
    if (!isMarked(text))
        return text;

    const auto marked = parseMarked(text);
    // Convert plural using default English rules since we are converting to English
    auto result = marked.n == 1 || marked.plural.isEmpty() ? marked.text : marked.plural;
    for (const auto& arg : marked.args)
        result = result.arg(unmark(arg));
    return result;
}

} // namespace util::i18n
