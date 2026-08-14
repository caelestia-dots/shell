#include "schema.hpp"

#include "node.hpp"

namespace caelestia::settings {

namespace {

// Descriptor schemas are stored here by Schema::annotate, which is called in the CONFIG_XXX macros.
// Schema::build then takes them from here.
QHash<const QMetaObject*, QHash<QString, Descriptor>>& descriptorCache() {
    static QHash<const QMetaObject*, QHash<QString, Descriptor>> cache;
    return cache;
}

bool isNodeType(const QMetaType& type) {
    const auto* meta = type.metaObject();
    return meta && meta->inherits(&Node::staticMetaObject);
}

} // namespace

Schema Schema::build(const QMetaObject* meta, int baseOffset) {
    Schema schema;
    schema.m_descriptors.reserve(meta->propertyCount() - baseOffset);

    // Descriptors are taken from cache since this should be called exactly once per class
    auto descriptors = descriptorCache().take(meta);

    for (int i = baseOffset; i < meta->propertyCount(); ++i) {
        const auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        auto desc = descriptors.value(key);
        desc.key = key;
        desc.type = prop.metaType();
        desc.metaIndex = i;
        desc.isNode = isNodeType(prop.metaType());

        schema.m_descriptors.append(std::move(desc));
        schema.m_keyToIndex.insert(key, schema.m_descriptors.size() - 1);
    }

    return schema;
}

void Schema::annotate(const QMetaObject* meta, const QString& key, Descriptor descriptor) {
    descriptorCache()[meta].insert(key, std::move(descriptor));
}

const QList<Descriptor>& Schema::descriptors() const {
    return m_descriptors;
}

const Descriptor* Schema::get(const QString& key) const {
    const auto it = m_keyToIndex.find(key);
    return it != m_keyToIndex.end() ? &m_descriptors[it.value()] : nullptr;
}

} // namespace caelestia::settings
