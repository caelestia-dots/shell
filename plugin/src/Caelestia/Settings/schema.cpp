#include "schema.hpp"

#include "node.hpp"

namespace caelestia::settings {

namespace {

// Descriptor annotations are stored here by Schema::annotate, which is called in the CONFIG_XXX macros.
// Schema::build then takes them from here.
QHash<const QMetaObject*, QHash<QString, Annotation>>& annotationCache() {
    static QHash<const QMetaObject*, QHash<QString, Annotation>> cache;
    return cache;
}

bool isNodeType(const QMetaType& type) {
    if (!type.flags().testFlag(QMetaType::PointerToQObject))
        return false;
    const auto* meta = type.metaObject();
    return meta && meta->inherits(&Node::staticMetaObject);
}

} // namespace

Schema Schema::build(const QMetaObject* meta, int baseOffset) {
    Schema schema;
    schema.m_descriptors.reserve(meta->propertyCount() - baseOffset);

    // Descriptors are taken from cache since this should be called exactly once per class
    auto annotations = annotationCache().take(meta);

    for (int i = baseOffset; i < meta->propertyCount(); ++i) {
        const auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        Descriptor desc{
            .key = key,
            .type = prop.metaType(),
            .metaIndex = i,
            .isNode = isNodeType(prop.metaType()),
            .annotation = annotations.value(key),
        };

        schema.m_descriptors.append(std::move(desc));
        schema.m_keyToIndex.insert(key, schema.m_descriptors.size() - 1);
    }

    return schema;
}

void Schema::annotate(const QMetaObject* meta, const QString& key, Annotation annotation) {
    annotationCache()[meta].insert(key, std::move(annotation));
}

const QList<Descriptor>& Schema::descriptors() const {
    return m_descriptors;
}

const Descriptor* Schema::get(const QString& key) const {
    const auto it = m_keyToIndex.find(key);
    return it != m_keyToIndex.end() ? &m_descriptors[it.value()] : nullptr;
}

} // namespace caelestia::settings
