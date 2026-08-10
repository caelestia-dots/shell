#include "node.hpp"

namespace caelestia::settings {

bool RejectedOption::operator==(const RejectedOption& other) const {
    return key == other.key && value == other.value && reason == other.reason;
}

bool RejectedOption::operator!=(const RejectedOption& other) const {
    return !(*this == other);
}

size_t qHash(const RejectedOption& option, size_t seed) noexcept {
    return qHashMulti(seed, option.key, option.reason);
}

SaveSuppressor::SaveSuppressor(Node* node)
    : m_node(node) {
    m_node->m_suppressSave = true;
}

SaveSuppressor::~SaveSuppressor() {
    m_node->m_suppressSave = false;
}

Node::Node(QObject* parent)
    : QObject(parent)
    , m_suppressSave(false) {}

bool Node::saveSuppressed() const {
    return m_suppressSave;
}

int Node::basePropertyOffset() {
    return Node::staticMetaObject.propertyOffset();
}

} // namespace caelestia::settings
