#include "objectnode.hpp"

#include <qjsonarray.h>
#include <qjsonobject.h>

namespace caelestia::settings {

Q_LOGGING_CATEGORY(lcSettingsObj, "caelestia.settings.objectnode", QtInfoMsg)

ObjectNode::ObjectNode(QObject* parent)
    : Node(parent) {
    const auto* meta = metaObject();
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        m_notifyToProp.insert(prop.notifySignalIndex(), prop.name());
    }

    connectNotifiers();
}

QJsonValue ObjectNode::toJson() const {
    return m_json;
}

SyncResult ObjectNode::syncJson(const QJsonValue& json) {
    const SaveSuppressor suppressor(this); // Prevent property writes from saving to file

    m_json = json.toObject();
    const auto* meta = metaObject();
    SyncResult result;
    QSet<QString> known;

    qCDebug(lcSettingsObj) << "Loading JSON into" << meta->className() << "with" << m_json.keys().size()
                           << "keys:" << m_json.keys();

    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        known << key;

        if (!m_json.contains(key))
            continue;

        const auto jsonVal = m_json.value(key);

        // Recurse into child nodes
        if (auto* const node = prop.read(this).value<Node*>()) {
            qCDebug(lcSettingsObj) << "  Recursing into" << key;
            const auto res = node->syncJson(jsonVal);

            for (const auto& rejected : res.rejected)
                result.rejected << RejectedOption{ key + "." + rejected.key, rejected.value, rejected.reason };
            for (const auto& unknown : res.unknown)
                result.unknown << key + "." + unknown;

            continue;
        }

        // Skip read-only properties
        if (!prop.isWritable())
            continue;

        // Handle QStringList explicitly
        if (prop.metaType().id() == QMetaType::QStringList) {
            QStringList list;
            const auto jsonArr = jsonVal.toArray();
            for (const auto& v : jsonArr)
                list << v.toString();

            prop.write(this, QVariant::fromValue(list));
            qCDebug(lcSettingsObj) << "  Loaded" << key << "=" << list;

            continue;
        }

        // Generic types
        prop.write(this, jsonVal.toVariant());
        qCDebug(lcSettingsObj) << "  Loaded" << key << "=" << jsonVal.toVariant();
    }

    // Check for unknown keys
    for (auto it = m_json.constBegin(); it != m_json.constEnd(); ++it) {
        if (!known.contains(it.key())) {
            result.unknown << it.key();
            qCDebug(lcSettingsObj) << "  Unknown key:" << it.key();
        }
    }

    return result;
}

void ObjectNode::connectNotifiers() const {
    const auto* meta = metaObject();
    const auto notifySlot = meta->method(meta->indexOfSlot("onPropChanged()"));

    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);

        // Connect nested child nodes
        if (auto* const node = prop.read(this).value<Node*>()) {
            QObject::connect(node, &Node::needsSave, this, &ObjectNode::onPropChanged);
            continue;
        }

        // Skip properties without a notify signal
        if (!prop.hasNotifySignal())
            continue;

        QObject::connect(this, prop.notifySignal(), this, notifySlot);
    }
}

void ObjectNode::onPropChanged() {
    if (saveSuppressed())
        return;

    const auto* prop = m_notifyToProp.value(senderSignalIndex());
    const auto propVal = property(prop);

    if (const auto* node = propVal.value<Node*>())
        m_json.insert(prop, node->toJson());
    else
        m_json.insert(prop, propVal.toJsonValue());

    emit needsSave();
}

} // namespace caelestia::settings
