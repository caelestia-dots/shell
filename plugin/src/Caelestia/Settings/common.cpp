#include "common.hpp"

#include "node.hpp"

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
    case TypeMismatch:
        return QStringLiteral("TypeMismatch");
    case InvalidValue:
        return QStringLiteral("InvalidValue");
    }
}

} // namespace caelestia::settings
