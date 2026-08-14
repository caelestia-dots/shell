#include "node.hpp"

namespace caelestia::settings {

Node::Node(Node* fallback, QObject* parent)
    : QObject(parent)
    , m_rootNode(parentNode() ? parentNode()->rootNode() : this)
    , m_fallbackNode(fallback)
    , m_writeOrigin(WriteOrigin::Qml) {
    if (fallback)
        QObject::connect(fallback, &Node::optionChanged, this, &Node::onFallbackNotify);
}

QString Node::key() const {
    return parentNode() ? parentNode()->keyOf(this) : QString();
}

QString Node::path() const {
    return parentNode() ? parentNode()->pathFor(key()) : key();
}

QString Node::pathFor(const QString& key) const {
    const auto p = path();
    return p.isEmpty() ? key : p + "." + key;
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
    return !m_overrides.isEmpty() ||
           std::ranges::any_of(findChildren<Node*>(Qt::FindDirectChildrenOnly), &Node::hasOverrides);
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
        qCWarning(lcSettings, "Type mismatch for %s, expected %s got %s", qUtf8Printable(pathFor(key)),
            desc->type.name(), value.metaType().name());
        return false;
    }

    return metaObject()->property(desc->metaIndex).write(this, value);
}

void Node::resetToDefaults() {
    const WriteScope scope(this, WriteOrigin::FileReset);
    for (const auto& desc : schema().descriptors()) {
        if (desc.isNode)
            value(desc.key).value<Node*>()->resetToDefaults();
        else
            setValue(desc.key, m_fallbackNode ? m_fallbackNode->value(desc.key) : desc.defaultValue);
    }
}

bool Node::recordWrite(const QString& key, const QVariant& value, bool changed) {
    const auto* desc = schema().get(key);
    if (!desc) {
        qCCritical(lcSettings, "Attempted to record a write for an unknown key %s, something is seriously wrong...",
            qUtf8Printable(pathFor(key)));
        return false;
    }

    const auto origin = m_rootNode->m_writeOrigin;
    const auto fromUser = origin == WriteOrigin::Qml || origin == WriteOrigin::QmlReset;

    // Forward to fallback node if global property. This should not be relied upon however, global properties
    // should be written to explicitly from the global tree, not overlay trees, for the sake of clarity.
    if (desc->globalOnly && fromUser && m_fallbackNode) {
        qCWarning(lcSettings,
            "Forwarding write of global property %s to the global layer. "
            "This should not be used, write global properties from the global layer instead.",
            qUtf8Printable(pathFor(key)));

        {
            const WriteScope scope(m_fallbackNode, origin);
            m_fallbackNode->setValue(key, value);
        }

        onFallbackNotify(key); // Keep fallback in sync, will notify if needed
        return false;
    }

    bool overridesChanged = false;
    switch (origin) {
    // Init does not notify or write to file
    case WriteOrigin::Init:
        return false;

    // File and qml both count as overrides
    case WriteOrigin::File:
    case WriteOrigin::Qml:
        overridesChanged = !m_overrides.contains(key);
        m_overrides << key;
        break;

    // Layer is not an override, it is a sync with the fallback value
    case WriteOrigin::Layer:
        break;

    // Both resets clear the override
    case WriteOrigin::FileReset:
    case WriteOrigin::QmlReset:
        overridesChanged = m_overrides.remove(key);
        break;
    }

    // Both qml and reset write to the file (only write if dirty)
    if (fromUser && (overridesChanged || changed)) {
        // TODO: write to file
    }

    if (changed)
        emit optionChanged(key);

    return changed;
}

QString Node::keyOf(const Node* child) const {
    for (const auto& desc : schema().descriptors()) {
        if (child == value(desc.key).value<Node*>())
            return desc.key;
    }

    return QString();
}

void Node::onFallbackNotify(const QString& key) {
    if (m_overrides.contains(key))
        return;

    const WriteScope scope(this, WriteOrigin::Layer);
    setValue(key, m_fallbackNode->value(key));
}

} // namespace caelestia::settings
