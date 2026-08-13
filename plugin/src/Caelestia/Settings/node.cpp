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

bool Node::recordWrite(const QString& key, const QVariant& value) {
    const auto* desc = schema().get(key);
    if (!desc) {
        qCCritical(lcSettings, "Attempted to record a write for an unknown key %s.%s, something is seriously wrong...",
            qUtf8Printable(path()), qUtf8Printable(key));
        return false;
    }

    const auto origin = m_rootNode->m_writeOrigin;
    const auto fromUser = origin == WriteOrigin::Qml || origin == WriteOrigin::Reset;

    // Forward to fallback node if global property. This should not be relied upon however, global properties
    // should be written to explicitly from the global tree, not overlay trees, for the sake of clarity.
    if (desc->globalOnly && fromUser && m_fallbackNode) {
        qCWarning(lcSettings,
            "Forwarding write of global property %s.%s to the global layer. "
            "This should not be used, write global properties from the global layer instead.",
            qUtf8Printable(path()), qUtf8Printable(key));

        const WriteScope scope(m_fallbackNode, origin);
        m_fallbackNode->setValue(key, value);
        return true; // Notify regardless of fallback write, since the value did change
    }

    switch (origin) {
    // Init does not notify or write to file
    case WriteOrigin::Init:
        return false;

    // File and qml both count as overrides
    case WriteOrigin::File:
    case WriteOrigin::Qml:
        m_overrides << key;
        break;

    // Layer is not an override, it is a sync with the fallback value
    case WriteOrigin::Layer:
        break;

    // Reset clears the override
    case WriteOrigin::Reset:
        m_overrides.remove(key);
        break;
    }

    // Both qml and reset write to the file
    if (fromUser) {
        // TODO: write to file
    }

    emit optionChanged(key);
    return true;
}

template <typename T> T Node::fallbackValue(const QString& key, T defaultValue) const {
    return m_fallbackNode ? m_fallbackNode->value(key).value<T>() : defaultValue;
}

template <typename T> T* Node::fallbackChild(const QString& key) const {
    if (!m_fallbackNode)
        return nullptr;
    const auto* desc = m_fallbackNode->schema().get(key);
    if (!desc || !desc->isNode)
        return nullptr;
    return qobject_cast<T*>(m_fallbackNode->value(key).value<QObject*>());
}

void Node::onFallbackNotify(const QString& key) {
    if (m_overrides.contains(key))
        return;

    const WriteScope scope(this, WriteOrigin::Layer);
    setValue(key, m_fallbackNode->value(key));
}

} // namespace caelestia::settings
