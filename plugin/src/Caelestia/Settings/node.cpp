#include "node.hpp"

#include "common.hpp"

namespace caelestia::settings {

Node::Node(Node* fallback, QObject* parent)
    : QObject(parent)
    , m_rootNode(parentNode() ? parentNode()->rootNode() : this)
    , m_fallbackNode(fallback)
    , m_writeOrigin(WriteOrigin::Init) {
    if (fallback)
        QObject::connect(fallback, &Node::optionChanged, this, &Node::onFallbackNotify);
}

QString Node::key() const {
    return parentNode() ? parentNode()->keyOf(this) : QString();
}

QString Node::path() const {
    return parentNode() ? parentNode()->path() + "." + key() : key();
}

Node* Node::parentNode() const {
    return qobject_cast<Node*>(parent());
}

Node* Node::rootNode() const {
    return m_rootNode;
}

bool Node::isOverride(const QString& key) const {
    return m_overrides.contains(key);
}

const QSet<QString>& Node::overrides() const {
    return m_overrides;
}

bool Node::hasOverrides() const {
    return !m_overrides.isEmpty();
}

Node* Node::fallbackNode() const {
    return m_fallbackNode;
}

} // namespace caelestia::settings
