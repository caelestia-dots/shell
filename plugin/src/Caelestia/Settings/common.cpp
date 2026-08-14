#include "common.hpp"

#include "node.hpp"

namespace {

QString jsonTypeName(const QJsonValue& value) {
    switch (value.type()) {
    case QJsonValue::Null:
        return QStringLiteral("null");
    case QJsonValue::Bool:
        return QStringLiteral("a boolean");
    case QJsonValue::Double:
        return QStringLiteral("a number");
    case QJsonValue::String:
        return QStringLiteral("a string");
    case QJsonValue::Array:
        return QStringLiteral("an array");
    case QJsonValue::Object:
        return QStringLiteral("an object");
    default:
        return QStringLiteral("nothing");
    }
}

} // namespace

namespace caelestia::settings {

Q_LOGGING_CATEGORY(lcSettings, "caelestia.settings", QtInfoMsg)

WriteScope::WriteScope(Node* node, WriteOrigin origin)
    : m_root(node->rootNode()) {
    m_previous = m_root->m_writeOrigin;
    m_root->m_writeOrigin = origin;
}

WriteScope::~WriteScope() {
    m_root->m_writeOrigin = m_previous;
}

QString DiagnosticType::toString(Type t) {
    switch (t) {
    case UnknownOption:
        return QStringLiteral("UnknownOption");
    case GlobalOption:
        return QStringLiteral("GlobalOption");
    case TypeMismatch:
        return QStringLiteral("TypeMismatch");
    case InvalidValue:
        return QStringLiteral("InvalidValue");
    }
}

Diagnostic Diagnostic::mismatch(const QString& expected, const QJsonValue& value, const QString& option) {
    return { DiagnosticType::TypeMismatch, option,
        QStringLiteral("Expected %1, got %2").arg(expected, jsonTypeName(value)) };
}

} // namespace caelestia::settings
