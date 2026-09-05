#pragma once

#include <qstring.h>

namespace util::i18n {

constexpr char k_markChar = '\x01';
constexpr char k_contextSep = '\x04';

inline QString mark(const QString& text, const QString& context = {}) {
    if (context.isEmpty())
        return QChar::fromLatin1(k_markChar) + text;
    return QChar::fromLatin1(k_markChar) + context + QChar::fromLatin1(k_contextSep) + text;
}

inline bool isMarked(const QString& text) {
    return text.startsWith(QChar::fromLatin1(k_markChar));
}

} // namespace util::i18n
