#include "schema.hpp"

#include "node.hpp"

namespace caelestia::settings {

Q_LOGGING_CATEGORY(lcSchema, "caelestia.settings.schema", QtInfoMsg)

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

QVariant DefaultSpec::resolve(const Node* self) const {
    if (func)
        return func(self);
    return value;
}

QString Descriptor::typeString() const {
    return type.name();
}

QVariant Descriptor::defaultValue(const Node* self) const {
    return annotation.defaultValue.resolve(self);
}

Schema Schema::build(const QMetaObject* meta, int baseOffset, bool includeReadOnly) {
    Schema schema;
    schema.m_descriptors.reserve(meta->propertyCount() - baseOffset);

    // Descriptors are taken from cache since this should be called exactly once per class
    const auto annotations = annotationCache().take(meta);

    qCDebug(lcSchema) << "Building schema for" << meta->className();

    for (int i = baseOffset; i < meta->propertyCount(); ++i) {
        const auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());
        const auto isNode = isNodeType(prop.metaType());

        // Skip read only properties (unless includeReadOnly)
        if (!isNode && !includeReadOnly && !prop.isWritable()) {
            qCDebug(lcSchema) << "  Skipping computed property" << key;
            continue;
        }

        qCDebug(lcSchema) << "  Adding property" << key;

        Descriptor desc{
            .key = key,
            .type = prop.metaType(),
            .metaIndex = i,
            .isNode = isNode,
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
