#include "configobject.hpp"

#include <qjsonarray.h>
#include <qjsonvalue.h>
#include <qloggingcategory.h>
#include <qmetaobject.h>
#include <qstringlist.h>
#include <qvariant.h>

namespace caelestia::config {

Q_LOGGING_CATEGORY(lcConfig, "caelestia.config", QtInfoMsg)

// ConfigObject

ConfigObject::ConfigObject(QObject* parent)
    : QObject(parent) {}

void ConfigObject::loadFromJson(const QJsonObject& obj) {
    const auto* meta = metaObject();

    qCDebug(lcConfig) << "Loading JSON into" << meta->className() << "with" << obj.keys().size()
                      << "keys:" << obj.keys();

    for (int i = meta->propertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        if (!obj.contains(key))
            continue;

        if (isGlobalOnly(key))
            qCWarning(lcConfig, "Option '%s' is global-only and will be ignored in per-monitor config",
                qUtf8Printable(propertyPath(key)));

        const auto jsonVal = obj.value(key);

        // Recurse into sub-objects
        auto current = prop.read(this);
        auto* subObj = current.value<ConfigObject*>();

        if (subObj) {
            qCDebug(lcConfig) << "  Recursing into sub-object" << key;
            subObj->loadFromJson(jsonVal.toObject());
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
}

QJsonObject ConfigObject::toJsonObject() const {
    QJsonObject obj;
    const auto* meta = metaObject();

    for (int i = meta->propertyOffset(); i < meta->propertyCount(); ++i) {
        const auto prop = meta->property(i);

        if (!prop.isReadable())
            continue;

        const auto key = QString::fromUtf8(prop.name());

        if (isGlobalOnly(key))
            continue;

        const auto value = prop.read(this);

        // Recurse into sub-objects — include only if they have loaded keys
        if (value.canView<ConfigObject*>()) {
            auto* const subObj = value.value<ConfigObject*>();
            if (subObj) {
                auto subJson = subObj->toJsonObject();
                if (!subJson.isEmpty())
                    obj.insert(key, subJson);
            }
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

    return obj;
}

void ConfigObject::clearLoadedKeys() {
    m_loadedKeys.clear();

    const auto* meta = metaObject();
    for (int i = meta->propertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        if (isGlobalOnly(QString::fromUtf8(prop.name())))
            continue;
        auto value = prop.read(this);
        auto* subObj = value.value<ConfigObject*>();
        if (subObj)
            subObj->clearLoadedKeys();
    }
}

void ConfigObject::syncFromGlobal(ConfigObject* global) {
    m_global = global;

    const auto* meta = metaObject();
    qCDebug(lcConfig) << "Syncing" << meta->className() << "from global, loaded keys:" << m_loadedKeys;

    // Connect batched change signal (single connection per ConfigObject pair)
    connect(global, &ConfigObject::propertiesChanged, this, &ConfigObject::onGlobalPropertiesChanged);

    // Initial sync: copy all non-loaded property values from global
    for (int i = meta->propertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        if (isGlobalOnly(key))
            continue;

        auto current = prop.read(this);
        auto* subObj = current.value<ConfigObject*>();

        if (subObj) {
            auto globalVal = prop.read(global);
            auto* globalSub = globalVal.value<ConfigObject*>();
            if (globalSub)
                subObj->syncFromGlobal(globalSub);
            continue;
        }

        if (!prop.isWritable())
            continue;

        if (!m_loadedKeys.contains(key)) {
            auto val = prop.read(global);
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
    for (int i = meta->propertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        if (isGlobalOnly(key))
            continue;

        auto current = prop.read(this);
        auto* subObj = current.value<ConfigObject*>();

        if (subObj) {
            subObj->resyncFromGlobal();
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

QString ConfigObject::propertyPath(const QString& name) const {
    QStringList parts;
    parts.append(name);

    const QObject* obj = this;
    while (auto* parentObj = obj->parent()) {
        auto* parentConfig = qobject_cast<const ConfigObject*>(parentObj);
        if (!parentConfig)
            break;

        // Find which property name this child is on the parent
        const auto* meta = parentConfig->metaObject();
        bool found = false;
        for (int i = meta->propertyOffset(); i < meta->propertyCount(); ++i) {
            auto prop = meta->property(i);
            auto val = prop.read(parentObj);
            if (val.value<QObject*>() == obj) {
                parts.prepend(QString::fromUtf8(prop.name()));
                found = true;
                break;
            }
        }

        if (!found)
            break;

        obj = parentObj;
    }

    return parts.join(QLatin1Char('.'));
}

bool ConfigObject::isPropertyLoaded(const QString& name) const {
    return m_loadedKeys.contains(name);
}

bool ConfigObject::isOverlay() const {
    return m_global != nullptr;
}

bool ConfigObject::isGlobalOnly(const QString& name) const {
    return isOverlay() && m_globalOnlyKeys.contains(name);
}

void ConfigObject::markPropertyLoaded(const QString& name) {
    m_loadedKeys.insert(name);
}

void ConfigObject::resetOption(const QString& name) {
    m_loadedKeys.remove(name);

    // If synced from global, re-copy the global value
    if (m_global) {
        int idx = metaObject()->indexOfProperty(name.toUtf8().constData());
        if (idx >= 0) {
            auto prop = metaObject()->property(idx);
            if (prop.isWritable())
                prop.write(this, prop.read(m_global));
        }
    }
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

void ConfigObject::markGlobalOnly(const QString& name) {
    m_globalOnlyKeys.insert(name);
}

void ConfigObject::notifyPropertyChanged(const QString& name, const QVariant& value) {
    m_pendingChanges.insert(name, value);

    if (!m_batchTimer) {
        m_batchTimer = new QTimer(this);
        m_batchTimer->setSingleShot(true);
        m_batchTimer->setInterval(0);
        connect(m_batchTimer, &QTimer::timeout, this, &ConfigObject::emitBatchedChanges);
    }

    m_batchTimer->start();
}

void ConfigObject::emitBatchedChanges() {
    if (m_pendingChanges.isEmpty())
        return;

    auto changes = std::move(m_pendingChanges);
    m_pendingChanges.clear();
    emit propertiesChanged(changes);
}

} // namespace caelestia::config
