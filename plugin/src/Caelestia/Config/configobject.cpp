#include "configobject.hpp"

#include <qjsonarray.h>
#include <qmetaobject.h>
#include <qstringlist.h>
#include <qvariant.h>

namespace caelestia::config {

ConfigObject::ConfigObject(QObject* parent)
    : ConfigNode(parent) {}

void ConfigObject::loadFromJson(const QJsonValue& json) {
    const auto obj = json.toObject();
    const auto* meta = metaObject();

    qCDebug(lcConfig) << "Loading JSON into" << meta->className() << "with" << obj.keys().size()
                      << "keys:" << obj.keys();

    QSet<QString> known;

    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        known.insert(key);

        if (!obj.contains(key))
            continue;

        if (isGlobalOnly(key))
            qCWarning(lcConfig, "Option '%s' is global-only and will be ignored in per-monitor config",
                qUtf8Printable(propertyPath(key)));

        const auto jsonVal = obj.value(key);

        // Recurse into child nodes (sub-objects and lists)
        if (auto* const node = prop.read(this).value<ConfigNode*>()) {
            qCDebug(lcConfig) << "  Recursing into" << key;
            node->loadFromJson(jsonVal);
            continue;
        }

        // Skip read-only properties
        if (!prop.isWritable())
            continue;

        // Handle QStringList explicitly (QJsonArray → QStringList needs manual conversion)
        if (prop.metaType().id() == QMetaType::QStringList) {
            QStringList list;
            const auto jsonArr = jsonVal.toArray();
            for (const auto& v : jsonArr)
                list.append(v.toString());
            prop.write(this, QVariant::fromValue(list));
            m_loadedKeys.insert(key);
            qCDebug(lcConfig) << "  Loaded" << key << "=" << list;
            continue;
        }

        // For all other types, let Qt's variant conversion handle it
        prop.write(this, jsonVal.toVariant());
        m_loadedKeys.insert(key);
        qCDebug(lcConfig) << "  Loaded" << key << "=" << jsonVal.toVariant();
    }

    m_extras = {};
    for (auto it = obj.begin(); it != obj.end(); ++it) {
        if (!known.contains(it.key())) {
            m_extras.insert(it.key(), it.value());
            qCDebug(lcConfig) << "  Keeping unknown key" << it.key();
        }
    }
}

QJsonValue ConfigObject::toJson() const {
    QJsonObject obj;
    const auto* meta = metaObject();

    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        const auto prop = meta->property(i);

        if (!prop.isReadable())
            continue;

        const auto key = QString::fromUtf8(prop.name());

        if (isGlobalOnly(key))
            continue;

        const auto value = prop.read(this);

        // Recurse into child nodes, they decide if they hold anything worth writing
        if (auto* const node = value.value<ConfigNode*>()) {
            const auto childJson = node->toJson();
            if (!childJson.isUndefined())
                obj.insert(key, childJson);
            continue;
        }

        // Only include properties that were explicitly loaded
        if (!m_loadedKeys.contains(key))
            continue;

        if (!prop.isWritable())
            continue;

        if (prop.metaType().id() == QMetaType::QStringList) {
            QJsonArray arr;
            const auto strList = value.toStringList();
            for (const auto& s : strList)
                arr.append(s);
            obj.insert(key, arr);
            continue;
        }

        if (prop.metaType().id() == QMetaType::QVariantList) {
            obj.insert(key, QJsonArray::fromVariantList(value.toList()));
            continue;
        }

        obj.insert(key, QJsonValue::fromVariant(value));
    }

    for (auto it = m_extras.begin(); it != m_extras.end(); ++it)
        obj.insert(it.key(), it.value());

    if (obj.isEmpty())
        return QJsonValue::Undefined;

    return obj;
}

void ConfigObject::clearLoadedKeys() {
    m_loadedKeys.clear();
    m_extras = {};

    const auto* meta = metaObject();
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        if (isGlobalOnly(QString::fromUtf8(prop.name())))
            continue;

        if (auto* const node = prop.read(this).value<ConfigNode*>())
            node->clearLoadedKeys();
    }
}

QStringList ConfigObject::identityKeys() const {
    return {};
}

QStringList ConfigObject::unknownKeys() const {
    auto keys = m_extras.keys();

    const auto* meta = metaObject();
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        const auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        // Never a node, and reading one on an overlay warns
        if (isGlobalOnly(key))
            continue;

        auto* const node = prop.read(this).value<ConfigNode*>();
        if (!node)
            continue;

        const auto childKeys = node->unknownKeys();
        for (const auto& childKey : childKeys)
            keys.append(joinPath(key, childKey));
    }

    return keys;
}

QList<ConfigNode*> ConfigObject::childNodes() const {
    QList<ConfigNode*> nodes;

    const auto* meta = metaObject();
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        const auto prop = meta->property(i);

        // Never a node, and reading one on an overlay warns
        if (isGlobalOnly(QString::fromUtf8(prop.name())))
            continue;

        if (auto* const node = prop.read(this).value<ConfigNode*>())
            nodes.append(node);
    }

    return nodes;
}

void ConfigObject::syncValuesFromGlobal() {
    const auto* meta = metaObject();
    qCDebug(lcConfig) << "  Loaded keys:" << m_loadedKeys;

    // Copy all non-loaded property values from global
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        if (isGlobalOnly(key))
            continue;

        if (auto* const node = prop.read(this).value<ConfigNode*>()) {
            if (auto* const globalNode = prop.read(m_global).value<ConfigNode*>())
                node->syncFromGlobal(globalNode);
            continue;
        }

        if (!prop.isWritable())
            continue;

        if (!m_loadedKeys.contains(key)) {
            auto val = prop.read(m_global);
            prop.write(this, val);
            m_loadedKeys.remove(key); // setter added it — remove since this is a synced value
            qCDebug(lcConfig) << "  Synced" << key << "=" << val << "from global";
        } else {
            qCDebug(lcConfig) << "  Keeping loaded" << key << "=" << prop.read(this);
        }
    }
}

void ConfigObject::resyncFromGlobal() {
    if (!m_global)
        return;

    const auto* meta = metaObject();
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        if (isGlobalOnly(key))
            continue;

        if (auto* const node = prop.read(this).value<ConfigNode*>()) {
            node->resyncFromGlobal();
            continue;
        }

        if (!prop.isWritable())
            continue;

        if (!m_loadedKeys.contains(key)) {
            prop.write(this, prop.read(m_global));
            m_loadedKeys.remove(key); // setter added it — remove since this is a synced value
        }
    }
}

bool ConfigObject::isPropertyLoaded(const QString& name) const {
    return m_loadedKeys.contains(name);
}

bool ConfigObject::isGlobalOnly(const QString& name) const {
    return isOverlay() && m_globalOnlyKeys.contains(name);
}

QStringList ConfigObject::globalOnlyKeys() const {
    return { m_globalOnlyKeys.begin(), m_globalOnlyKeys.end() };
}

void ConfigObject::resetOption(const QString& name) {
    m_loadedKeys.remove(name);

    const int idx = metaObject()->indexOfProperty(name.toUtf8().constData());
    if (idx < 0)
        return;

    const auto prop = metaObject()->property(idx);

    if (auto* const node = prop.read(this).value<ConfigNode*>()) {
        node->clearLoadedKeys();
        node->resyncFromGlobal();
        return;
    }

    // If synced from global, re-copy the global value
    if (m_global && prop.isWritable())
        prop.write(this, prop.read(m_global));
}

void ConfigObject::onGlobalPropertiesChanged(const QMap<QString, QVariant>& changed) {
    for (auto it = changed.begin(); it != changed.end(); ++it) {
        if (m_loadedKeys.contains(it.key()) || isGlobalOnly(it.key()))
            continue;

        int idx = metaObject()->indexOfProperty(it.key().toUtf8().constData());
        if (idx >= 0) {
            metaObject()->property(idx).write(this, it.value());
            m_loadedKeys.remove(it.key()); // setter added it — remove since this is a synced value
            qCDebug(lcConfig) << metaObject()->className() << "synced" << it.key() << "=" << it.value()
                              << "from global change";
        }
    }
}

QString ConfigObject::childPath(const ConfigNode* child) const {
    const auto* meta = metaObject();
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        const auto prop = meta->property(i);

        // Never a node, and reading one on an overlay warns, which would recurse back here
        if (isGlobalOnly(QString::fromUtf8(prop.name())))
            continue;

        if (prop.read(this).value<ConfigNode*>() == child)
            return QString::fromUtf8(prop.name());
    }

    return {};
}

void ConfigObject::markPropertyLoaded(const QString& name) {
    m_loadedKeys.insert(name);
}

void ConfigObject::markGlobalOnly(const QString& name) {
    m_globalOnlyKeys.insert(name);
}

} // namespace caelestia::config
