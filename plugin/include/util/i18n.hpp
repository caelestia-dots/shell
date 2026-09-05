#pragma once

#include <qpair.h>
#include <qstring.h>
#include <qstringlist.h>

namespace util::i18n {

inline constexpr QChar k_markChar = u'\x01';
inline constexpr QChar k_argSep = u'\x02';
inline constexpr QChar k_contextSep = u'\x04';

// Marks a string with the given context and args.
// The marked format is `markChar {<arg> argSep} [<context> contextSep] <text>`
inline QString mark(const QString& text, const QString& context = {}, const QStringList& args = {}) {
    auto len = 1 + text.size();
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
    return result;
}

// Parses a marked string into <context + text, args>
inline QPair<QString, QStringList> parseMarked(const QString& text) {
    const auto unmarked = text.mid(1);
    const auto parts = unmarked.split(k_argSep);
    if (parts.size() == 1)
        return { unmarked, {} };

    QStringList args;
    args.reserve(parts.size() - 1);
    for (int i = 0; i < parts.size() - 1; ++i)
        args << parts.at(i);

    return { parts.back(), args };
}

inline bool isMarked(const QString& text) {
    return text.startsWith(k_markChar);
}

} // namespace util::i18n
