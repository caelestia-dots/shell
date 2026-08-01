#include "configlist.hpp"

#include <qjsonobject.h>
#include <qmetaobject.h>
#include <qqmlengine.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

ConfigList::ConfigList(QObject* parent, const QVariantList& defaults)
    : ConfigNode(parent)
    , m_defaults(QJsonArray::fromVariantList(defaults)) {}

int ConfigList::count() const {
    return static_cast<int>(m_items.size());
}

ConfigObject* ConfigList::itemAt(int index) const {
    if (index < 0 || index >= m_items.size())
        return nullptr;

    return m_items.at(index);
}

const QList<ConfigObject*>& ConfigList::items() const {
    return m_items;
}

void ConfigList::remove(int index) {
    if (index < 0 || index >= m_items.size()) {
        qCWarning(lcConfig) << metaObject()->className() << "cannot remove index" << index << "of" << count();
        return;
    }

    delete m_items.takeAt(index);

    m_loaded = true;
    emit countChanged();
    emit valuesChanged();
    notifyChanged();
}

void ConfigList::move(int from, int to) {
    if (from < 0 || from >= m_items.size() || to < 0 || to >= m_items.size()) {
        qCWarning(lcConfig) << metaObject()->className() << "cannot move" << from << "to" << to << "of" << count();
        return;
    }

    if (from == to)
        return;

    m_items.move(from, to);

    m_loaded = true;
    emit valuesChanged();
    notifyChanged();
}

void ConfigList::clear() {
    if (m_items.isEmpty())
        return;

    destroyItems();

    m_loaded = true;
    emit countChanged();
    emit valuesChanged();
    notifyChanged();
}

void ConfigList::loadFromJson(const QJsonValue& json) {
    populate(json.toArray());
    m_loaded = true;
}

QJsonValue ConfigList::toJson() const {
    if (!m_loaded)
        return QJsonValue::Undefined;

    return elementsToJson();
}

void ConfigList::clearLoadedKeys() {
    // Tracking only like ConfigObject, rebuilding here would drop an overlay to defaults
    m_loaded = false;
}

QStringList ConfigList::unknownKeys() const {
    QStringList keys;

    for (int i = 0; i < m_items.size(); ++i) {
        const auto childKeys = m_items.at(i)->unknownKeys();
        for (const auto& childKey : childKeys)
            keys.append(joinPath(u"[%1]"_s.arg(i), childKey));
    }

    return keys;
}

void ConfigList::resyncFromGlobal() {
    syncValuesFromGlobal();
}

ConfigObject* ConfigList::insertItem(const QVariantMap& props, int index) {
    const auto pos = index < 0 || index > m_items.size() ? m_items.size() : index;

    appendItem(QJsonObject::fromVariantMap(props));
    m_items.move(m_items.size() - 1, pos);

    auto* const item = m_items.at(pos);
    const auto unknown = item->unknownKeys();
    for (const auto& key : unknown)
        qCWarning(lcConfig) << "Unknown option" << key << "for" << item->metaObject()->className();

    m_loaded = true;
    emit countChanged();
    emit valuesChanged();
    notifyChanged();

    return item;
}

QJsonArray ConfigList::elementsToJson() const {
    QJsonArray arr;

    // Position is identity in a list, so every element is written even when empty
    for (auto* const item : m_items)
        arr.append(item->toJson().toObject());

    return arr;
}

void ConfigList::resetToDefaults() {
    populate(m_defaults);
    m_loaded = false;
}

void ConfigList::syncValuesFromGlobal() {
    if (m_loaded)
        return;

    if (auto* const global = qobject_cast<ConfigList*>(m_global))
        populate(global->elementsToJson());
}

void ConfigList::onGlobalPropertiesChanged(const QMap<QString, QVariant>&) {
    syncValuesFromGlobal();
}

void ConfigList::populate(const QJsonArray& arr) {
    destroyItems();

    for (const auto& val : arr)
        appendItem(val);

    emit countChanged();
    emit valuesChanged();

    // Persistence is gated on m_loaded, not on silence, so defaults still serialise to nothing
    notifyChanged();
}

void ConfigList::appendItem(const QJsonValue& json) {
    auto* const item = createItem();
    QQmlEngine::setObjectOwnership(item, QQmlEngine::CppOwnership);

    // Quiet so seeded defaults and synced values don't look like user edits
    item->loadFromJsonQuietly(json);

    connect(item, &ConfigNode::propertiesChanged, this, &ConfigList::onItemChanged);

    m_items.append(item);
}

void ConfigList::destroyItems() {
    qDeleteAll(m_items);
    m_items.clear();
}

void ConfigList::onItemChanged() {
    m_loaded = true;
    notifyChanged();
}

void ConfigList::notifyChanged() {
    notifyPropertyChanged(u"values"_s, count());
}

} // namespace caelestia::config
