#include "node.hpp"

namespace caelestia::settings {

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
