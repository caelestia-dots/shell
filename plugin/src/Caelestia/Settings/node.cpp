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

Node* Node::fallbackNode() const {
    return m_fallbackNode;
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

QVariant Node::value(const QString& key) const {
    const auto* desc = schema().get(key);
    if (!desc) // Unknown key
        return QVariant();

    return metaObject()->property(desc->metaIndex).read(this);
}

bool Node::setValue(const QString& key, const QVariant& value) {
    const auto* desc = schema().get(key);
    if (!desc) // Unknown key
        return false;

    if (desc->isNode) // Nodes can't be set
        return false;

    // Type mismatch, conversion should happen before this function is called
    if (desc->type != value.metaType()) {
        qCWarning(lcSettings, "Type mismatch for %s.%s, expected %s got %s", qUtf8Printable(path()),
            qUtf8Printable(key), desc->type.name(), value.metaType().name());
        return false;
    }

    return metaObject()->property(desc->metaIndex).write(this, value);
}

} // namespace caelestia::settings
