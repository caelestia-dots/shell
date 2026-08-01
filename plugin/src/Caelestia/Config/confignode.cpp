#include "confignode.hpp"

#include <qmetaobject.h>

namespace caelestia::config {

Q_LOGGING_CATEGORY(lcConfig, "caelestia.config", QtInfoMsg)

ConfigNode::ConfigNode(QObject* parent)
    : QObject(parent) {}

void ConfigNode::loadFromJsonQuietly(const QJsonValue& json) {
    setNotifySuppressed(true);
    loadFromJson(json);
    setNotifySuppressed(false);
}

void ConfigNode::setNotifySuppressed(bool suppressed) {
    // Whole subtree, a child loaded during a quiet load must stay quiet too
    m_suppressNotify = suppressed;

    const auto children = childNodes();
    for (auto* const child : children)
        child->setNotifySuppressed(suppressed);
}

QList<ConfigNode*> ConfigNode::childNodes() const {
    return {};
}

void ConfigNode::syncFromGlobal(ConfigNode* global) {
    m_global = global;

    qCDebug(lcConfig) << "Syncing" << metaObject()->className() << "from global";

    // Connect batched change signal (single connection per node pair)
    connect(global, &ConfigNode::propertiesChanged, this, &ConfigNode::onGlobalPropertiesChanged);

    syncValuesFromGlobal();
}

bool ConfigNode::isOverlay() const {
    return m_global != nullptr;
}

QString ConfigNode::propertyPath(const QString& name) const {
    auto path = name;

    // Each parent names its own children, so a list can report an index
    const auto* node = this;
    while (const auto* parent = qobject_cast<const ConfigNode*>(node->parent())) {
        const auto childName = parent->childPath(node);
        if (childName.isEmpty())
            break;

        path = path.isEmpty() ? childName : joinPath(childName, path);
        node = parent;
    }

    return path;
}

int ConfigNode::basePropertyOffset() {
    return ConfigNode::staticMetaObject.propertyCount();
}

void ConfigNode::notifyPropertyChanged(const QString& name, const QVariant& value) {
    if (m_suppressNotify)
        return;

    m_pendingChanges.insert(name, value);

    if (!m_batchTimer) {
        m_batchTimer = new QTimer(this);
        m_batchTimer->setSingleShot(true);
        m_batchTimer->setInterval(0);
        connect(m_batchTimer, &QTimer::timeout, this, &ConfigNode::emitBatchedChanges);
    }

    m_batchTimer->start();
}

QString ConfigNode::joinPath(const QString& parent, const QString& child) {
    // List elements are addressed as parent[i], everything else as parent.child
    if (child.startsWith(QLatin1Char('[')))
        return parent + child;

    return parent + QLatin1Char('.') + child;
}

void ConfigNode::emitBatchedChanges() {
    if (m_pendingChanges.isEmpty())
        return;

    auto changes = std::move(m_pendingChanges);
    m_pendingChanges.clear();
    emit propertiesChanged(changes);
}

} // namespace caelestia::config
