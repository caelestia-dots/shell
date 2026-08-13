#include "common.hpp"

#include "node.hpp"

namespace caelestia::settings {

WriteScope::WriteScope(Node* node, WriteOrigin origin)
    : m_root(node->rootNode()) {
    m_previous = m_root->m_writeOrigin;
    m_root->m_writeOrigin = origin;
}

WriteScope::~WriteScope() {
    m_root->m_writeOrigin = m_previous;
}

} // namespace caelestia::settings
