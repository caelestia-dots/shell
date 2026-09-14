#include "common.hpp"

#include "util/i18n.hpp"
#include "node.hpp"

using Qt::StringLiterals::operator""_s;
using util::i18n::mark;

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

namespace {

QString boolMismatch(const QJsonValue& value) {
    switch (value.type()) {
    case QJsonValue::Null:
        return mark(u"Expected a boolean, got null"_s);
    case QJsonValue::Bool:
        return mark(u"Value has the wrong type"_s);
    case QJsonValue::Double:
        return mark(u"Expected a boolean, got a number"_s);
    case QJsonValue::String:
        return mark(u"Expected a boolean, got a string"_s);
    case QJsonValue::Array:
        return mark(u"Expected a boolean, got an array"_s);
    case QJsonValue::Object:
        return mark(u"Expected a boolean, got an object"_s);
    default:
        return mark(u"Expected a boolean, got nothing"_s);
    }
}

QString intMismatch(const QJsonValue& value) {
    switch (value.type()) {
    case QJsonValue::Null:
        return mark(u"Expected an integer, got null"_s);
    case QJsonValue::Bool:
        return mark(u"Expected an integer, got a boolean"_s);
    case QJsonValue::Double:
        return mark(u"Expected an integer, got a number"_s);
    case QJsonValue::String:
        return mark(u"Expected an integer, got a string"_s);
    case QJsonValue::Array:
        return mark(u"Expected an integer, got an array"_s);
    case QJsonValue::Object:
        return mark(u"Expected an integer, got an object"_s);
    default:
        return mark(u"Expected an integer, got nothing"_s);
    }
}

QString realMismatch(const QJsonValue& value) {
    switch (value.type()) {
    case QJsonValue::Null:
        return mark(u"Expected a number, got null"_s);
    case QJsonValue::Bool:
        return mark(u"Expected a number, got a boolean"_s);
    case QJsonValue::Double:
        return mark(u"Value has the wrong type"_s);
    case QJsonValue::String:
        return mark(u"Expected a number, got a string"_s);
    case QJsonValue::Array:
        return mark(u"Expected a number, got an array"_s);
    case QJsonValue::Object:
        return mark(u"Expected a number, got an object"_s);
    default:
        return mark(u"Expected a number, got nothing"_s);
    }
}

QString stringMismatch(const QJsonValue& value) {
    switch (value.type()) {
    case QJsonValue::Null:
        return mark(u"Expected a string, got null"_s);
    case QJsonValue::Bool:
        return mark(u"Expected a string, got a boolean"_s);
    case QJsonValue::Double:
        return mark(u"Expected a string, got a number"_s);
    case QJsonValue::String:
        return mark(u"Value has the wrong type"_s);
    case QJsonValue::Array:
        return mark(u"Expected a string, got an array"_s);
    case QJsonValue::Object:
        return mark(u"Expected a string, got an object"_s);
    default:
        return mark(u"Expected a string, got nothing"_s);
    }
}

QString arrayMismatch(const QJsonValue& value) {
    switch (value.type()) {
    case QJsonValue::Null:
        return mark(u"Expected an array, got null"_s);
    case QJsonValue::Bool:
        return mark(u"Expected an array, got a boolean"_s);
    case QJsonValue::Double:
        return mark(u"Expected an array, got a number"_s);
    case QJsonValue::String:
        return mark(u"Expected an array, got a string"_s);
    case QJsonValue::Array:
        return mark(u"Value has the wrong type"_s);
    case QJsonValue::Object:
        return mark(u"Expected an array, got an object"_s);
    default:
        return mark(u"Expected an array, got nothing"_s);
    }
}

QString objectMismatch(const QJsonValue& value) {
    switch (value.type()) {
    case QJsonValue::Null:
        return mark(u"Expected an object, got null"_s);
    case QJsonValue::Bool:
        return mark(u"Expected an object, got a boolean"_s);
    case QJsonValue::Double:
        return mark(u"Expected an object, got a number"_s);
    case QJsonValue::String:
        return mark(u"Expected an object, got a string"_s);
    case QJsonValue::Array:
        return mark(u"Expected an object, got an array"_s);
    case QJsonValue::Object:
        return mark(u"Value has the wrong type"_s);
    default:
        return mark(u"Expected an object, got nothing"_s);
    }
}

QString mismatchMessage(ExpectedType expected, const QJsonValue& value) {
    switch (expected) {
    case ExpectedType::Bool:
        return boolMismatch(value);
    case ExpectedType::Int:
        return intMismatch(value);
    case ExpectedType::Real:
        return realMismatch(value);
    case ExpectedType::String:
        return stringMismatch(value);
    case ExpectedType::Array:
        return arrayMismatch(value);
    case ExpectedType::Object:
        return objectMismatch(value);
    }

    Q_UNREACHABLE_RETURN(QString());
}

} // namespace

Diagnostic Diagnostic::mismatch(ExpectedType expected, const QJsonValue& value, const QString& option) {
    return {
        .type = DiagnosticType::TypeMismatch,
        .option = option,
        .message = mismatchMessage(expected, value),
    };
}

} // namespace caelestia::settings
