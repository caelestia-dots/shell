#include "common.hpp"

#include "node.hpp"

using Qt::StringLiterals::operator""_s;

namespace {

QString jsonTypeName(const QJsonValue& value) {
    switch (value.type()) {
    case QJsonValue::Null:
        return u"null"_s;
    case QJsonValue::Bool:
        return u"a boolean"_s;
    case QJsonValue::Double:
        return u"a number"_s;
    case QJsonValue::String:
        return u"a string"_s;
    case QJsonValue::Array:
        return u"an array"_s;
    case QJsonValue::Object:
        return u"an object"_s;
    default:
        return u"nothing"_s;
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
        .message = u"Expected %1, got %2"_s.arg(expected, jsonTypeName(value)),
    };
}

} // namespace caelestia::settings
