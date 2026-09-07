#include "common.hpp"

#include "util/i18n.hpp"
#include "node.hpp"

using Qt::StringLiterals::operator""_s;
using util::i18n::mark;
using util::i18n::markCtx;

namespace {

// Type names are marked, not translated, they are folded into a message and rendered with it
QString jsonTypeName(const QJsonValue& value) {
    switch (value.type()) {
    case QJsonValue::Null:
        return markCtx(u"null"_s, u"json type"_s);
    case QJsonValue::Bool:
        return markCtx(u"a boolean"_s, u"json type"_s);
    case QJsonValue::Double:
        return markCtx(u"a number"_s, u"json type"_s);
    case QJsonValue::String:
        return markCtx(u"a string"_s, u"json type"_s);
    case QJsonValue::Array:
        return markCtx(u"an array"_s, u"json type"_s);
    case QJsonValue::Object:
        return markCtx(u"an object"_s, u"json type"_s);
    default:
        return markCtx(u"nothing"_s, u"json type"_s);
    }
}

} // namespace

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

Diagnostic Diagnostic::mismatch(const QString& expected, const QJsonValue& value, const QString& option) {
    return {
        .type = DiagnosticType::TypeMismatch,
        .option = option,
        .message = mark(u"Expected %1, got %2"_s, { expected, jsonTypeName(value) }),
    };
}

} // namespace caelestia::settings
