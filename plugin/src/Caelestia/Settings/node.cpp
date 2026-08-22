#include "node.hpp"

namespace caelestia::settings {

Node::Node(Node* fallback, QObject* parent, bool globalOnly)
    : QObject(parent)
    , m_rootNode(parentNode() ? parentNode()->rootNode() : this)
    , m_fallbackNode(fallback)
    , m_globalOnly(globalOnly || (parentNode() && parentNode()->m_globalOnly))
    , m_writeOrigin(WriteOrigin::Qml)
    , m_batcher(m_rootNode == this ? new ChangeBatcher(this) : nullptr) {
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
    return p.isEmpty() ? key : p + QLatin1Char('.') + key;
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

void Node::detachFallback() {
    if (m_fallbackNode) {
        QObject::disconnect(m_fallbackNode, nullptr, this, nullptr);
        m_fallbackNode = nullptr;
    }

    const auto childNodes = findChildren<Node*>(Qt::FindDirectChildrenOnly);
    for (auto* const child : childNodes)
        child->detachFallback();
}

bool Node::isGlobalOnly() const {
    return m_globalOnly;
}

bool Node::isOverride(const QString& key) const {
    return m_overrides.contains(key);
}

const QSet<QString>& Node::overrides() const {
    return m_overrides;
}

bool Node::hasContent() const {
    return !m_overrides.isEmpty() || m_quarantine ||
           std::ranges::any_of(findChildren<Node*>(Qt::FindDirectChildrenOnly), &Node::hasContent);
}

QVariant Node::value(const QString& key) const {
    const auto* desc = schema().get(key);
    if (!desc) {
        qCCritical(
            lcSettings, "Attempted to read an unknown key %s, something is wrong.", qUtf8Printable(pathFor(key)));
        return QVariant();
    }

    return metaObject()->property(desc->metaIndex).read(this);
}

bool Node::setValue(const QString& key, const QVariant& value) {
    const auto* desc = schema().get(key);
    if (!desc) {
        qCCritical(lcSettings, "Attempted to set an unknown key %s, something is wrong.", qUtf8Printable(pathFor(key)));
        return false;
    }

    if (desc->isNode) {
        qCCritical(lcSettings, "Attempted to set node %s directly, something is wrong.", qUtf8Printable(pathFor(key)));
        return false;
    }

    // Type mismatch, conversion should happen before this function is called
    if (desc->type != value.metaType()) {
        qCWarning(lcSettings, "Type mismatch for %s, expected %s got %s", qUtf8Printable(pathFor(key)),
            desc->type.name(), value.metaType().name());
        return false;
    }

    return metaObject()->property(desc->metaIndex).write(this, value);
}

void Node::resetToDefaults() {
    // Don't reset global only nodes on overlays, the whole subtree belongs to the global layer
    if (m_globalOnly && m_fallbackNode)
        return;

    m_quarantine.reset(); // Reset quarantine as well

    // No write scope, callers should create the scope
    for (const auto& desc : schema().descriptors()) {
        if (desc.isNode)
            value(desc.key).value<Node*>()->resetToDefaults();
        else if (!desc.globalOnly() || !m_fallbackNode) // Skip resetting global options on overlays
            setValue(desc.key, m_fallbackNode ? m_fallbackNode->value(desc.key) : desc.defaultValue(this));
    }
}

const Quarantine* Node::quarantine() const {
    return m_quarantine.get();
}

bool Node::forwardGlobalWrite(const QString& key, const QVariant& value) {
    const auto* desc = schema().get(key);
    if (!desc) {
        qCCritical(lcSettings, "Attempted to forward a write for an unknown key %s, something is seriously wrong...",
            qUtf8Printable(pathFor(key)));
        return false;
    }

    const auto origin = m_rootNode->m_writeOrigin;
    const auto fromUser = origin == WriteOrigin::Qml || origin == WriteOrigin::QmlReset;

    if ((!m_globalOnly && !desc->globalOnly()) || !fromUser || !m_fallbackNode)
        return false;

    if (origin == WriteOrigin::QmlReset) {
        qCWarning(lcSettings,
            "Attempted to reset global property %s, ignoring. "
            "This should not be used, reset global properties from the global layer instead.",
            qUtf8Printable(pathFor(key)));
        return true;
    }

    qCWarning(lcSettings,
        "Forwarding write of global property %s to the global layer. "
        "This should not be used, write global properties from the global layer instead.",
        qUtf8Printable(pathFor(key)));

    const WriteScope scope(m_fallbackNode, origin);
    m_fallbackNode->setValue(key, value);

    return true;
}

bool Node::recordWrite(const QString& key, bool changed) {
    const auto* desc = schema().get(key);
    if (!desc) {
        qCCritical(lcSettings, "Attempted to record a write for an unknown key %s, something is seriously wrong...",
            qUtf8Printable(pathFor(key)));
        return false;
    }

    const auto origin = m_rootNode->m_writeOrigin;
    const auto fromUser = origin == WriteOrigin::Qml || origin == WriteOrigin::QmlReset;

    bool dirty = changed;
    switch (origin) {
    // Init does not notify or write to file
    case WriteOrigin::Init:
        return false;

    // File and qml both count as overrides
    case WriteOrigin::File:
    case WriteOrigin::Qml:
        dirty |= !m_overrides.contains(key);
        m_overrides << key;
        break;

    // Layer is not an override, it is a sync with the fallback value
    case WriteOrigin::Layer:
        break;

    // Both resets clear the override
    case WriteOrigin::FileReset:
    case WriteOrigin::QmlReset:
        dirty |= m_overrides.remove(key);
        break;
    }

    // User writes/reset override quarantine
    if (fromUser)
        dirty |= removeQuarantined(key);

    // Both qml and reset write to the file (only write if dirty)
    if (fromUser && dirty)
        m_rootNode->m_batcher->dirty();

    if (changed)
        emit optionChanged(key);

    return changed;
}

bool Node::removeQuarantined(const QString& key) {
    if (!m_quarantine)
        return false;

    const auto removed = m_quarantine->remove(key);
    if (m_quarantine->isEmpty())
        m_quarantine.reset();

    return removed;
}

ChangeBatcher* Node::batcher() const {
    return m_rootNode->m_batcher;
}

QString Node::keyOf(const Node* child) const {
    for (const auto& desc : schema().descriptors()) {
        if (desc.isNode && child == value(desc.key).value<Node*>())
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
