#include "common.hpp"

#include "util/i18n.hpp"
#include "node.hpp"

using Qt::StringLiterals::operator""_s;
using util::i18n::mark;
using util::i18n::markCtx;

namespace caelestia::settings {

Q_LOGGING_CATEGORY(lcSettings, "caelestia.settings", QtInfoMsg)

WriteScope::WriteScope(Node* node, WriteOrigin origin)
    : m_root(node->rootNode())
    , m_previous(m_root->m_writeOrigin) {
    m_root->m_writeOrigin = origin;
}

WriteScope::~WriteScope() {
    m_root->m_writeOrigin = m_previous;
}

InternalRead::InternalRead(Node* node)
    : m_root(node->rootNode())
    , m_previous(m_root->m_internalRead) {
    m_root->m_internalRead = true;
}

InternalRead::~InternalRead() {
    m_root->m_internalRead = m_previous;
}

QString DiagnosticType::toString(Type t) {
    switch (t) {
    case UnknownOption:
        return u"UnknownOption"_s;
    case GlobalOption:
        return u"GlobalOption"_s;
    case TypeMismatch:
        return u"TypeMismatch"_s;
    case InvalidValue:
        return u"InvalidValue"_s;
    }

    Q_UNREACHABLE_RETURN(QString());
}

namespace {

QString expectedStr(ExpectedType expected) {
    switch (expected) {
    case ExpectedType::Bool:
        return markCtx(u"a boolean"_s, u"expected type"_s);
    case ExpectedType::Int:
        return markCtx(u"an integer"_s, u"expected type"_s);
    case ExpectedType::Real:
        return markCtx(u"a number"_s, u"expected type"_s);
    case ExpectedType::String:
        return markCtx(u"a string"_s, u"expected type"_s);
    case ExpectedType::Array:
        return markCtx(u"an array"_s, u"expected type"_s);
    case ExpectedType::Object:
        return markCtx(u"an object"_s, u"expected type"_s);
    }

    Q_UNREACHABLE_RETURN(QString());
}

QString receivedStr(const QJsonValue& value) {
    switch (value.type()) {
    case QJsonValue::Null:
        return markCtx(u"null"_s, u"received type"_s);
    case QJsonValue::Bool:
        return markCtx(u"a boolean"_s, u"received type"_s);
    case QJsonValue::Double:
        return markCtx(u"a number"_s, u"received type"_s);
    case QJsonValue::String:
        return markCtx(u"a string"_s, u"received type"_s);
    case QJsonValue::Array:
        return markCtx(u"an array"_s, u"received type"_s);
    case QJsonValue::Object:
        return markCtx(u"an object"_s, u"received type"_s);
    default:
        return markCtx(u"nothing"_s, u"received type"_s);
    }
}

QString mismatchStr(const QList<ExpectedType>& expected, const QJsonValue& value) {
    QStringList args;
    args.reserve(expected.size() + 1);
    for (const auto type : expected)
        args << expectedStr(type);
    args << receivedStr(value);

    switch (expected.size()) {
    case 2:
        // TRANSLATORS: %1/%2 = the allowed types, %3 = the type that was found; all nouns such as "a string"
        return mark(u"Expected %1 or %2, got %3"_s, args);
    case 3:
        // TRANSLATORS: %1-%3 = the allowed types, %4 = the type that was found; all nouns such as "a string"
        return mark(u"Expected %1, %2 or %3, got %4"_s, args);
    case 4:
        // TRANSLATORS: %1-%4 = the allowed types, %5 = the type that was found; all nouns such as "a string"
        return mark(u"Expected one of: %1, %2, %3, %4; got %5"_s, args);
    default:
        // The bounds are checked in macros.hpp `unionType<...T>`
        Q_UNREACHABLE_RETURN(QString());
    }
}

} // namespace

Diagnostic Diagnostic::mismatch(ExpectedType expected, const QJsonValue& value, const QString& option) {
    return {
        .type = DiagnosticType::TypeMismatch,
        .option = option,
        // TRANSLATORS: %1 = the expected type, %2 = the type that was found; both nouns such as "a string"
        .message = mark(u"Expected %1, got %2"_s, { expectedStr(expected), receivedStr(value) }),
    };
}

Diagnostic Diagnostic::mismatch(const QList<ExpectedType>& expected, const QJsonValue& value, const QString& option) {
    return {
        .type = DiagnosticType::TypeMismatch,
        .option = option,
        .message = mismatchStr(expected, value),
    };
}

} // namespace caelestia::settings
