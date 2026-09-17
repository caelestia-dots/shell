#include "schema.hpp"

#include "codecs.hpp"
#include "node.hpp"

namespace {

Q_LOGGING_CATEGORY(lcSchema, "caelestia.settings.schema", QtInfoMsg)

} // namespace

namespace caelestia::settings {

namespace {

// Descriptor annotations are stored here by Schema::annotate, which is called in the CONFIG_XXX macros.
// Schema::build then takes them from here.
QHash<const QMetaObject*, QHash<QString, Annotation>>& annotationCache() {
    static QHash<const QMetaObject*, QHash<QString, Annotation>> s_cache;
    return s_cache;
}

// Union options carry their alternatives in the annotation, everything else goes by property type
const ValueCodec* resolveCodec(Descriptor& desc) {
    auto& allowed = desc.annotation.allowedTypes;

    if (allowed.isEmpty())
        return ValueCodec::codecFor(desc.type);

    if (desc.type.id() != QMetaType::QVariant) {
        qCCritical(lcSchema, "Allowed types are only valid for QVariant properties, ignoring them for %s",
            qUtf8Printable(desc.key));
        allowed.clear();
        return ValueCodec::codecFor(desc.type);
    }

    if (const auto* codec = ValueCodec::unionFor(allowed))
        return codec;

    allowed.clear();
    return nullptr;
}

bool isNodeType(const QMetaType& type) {
    if (!type.flags().testFlag(QMetaType::PointerToQObject))
        return false;
    const auto* meta = type.metaObject();
    return meta && meta->inherits(&Node::staticMetaObject);
}

} // namespace

QString Descriptor::typeString() const {
    if (annotation.allowedTypes.isEmpty())
        return QString::fromUtf8(type.name());

    QStringList names;
    names.reserve(annotation.allowedTypes.size());
    for (const auto& allowed : annotation.allowedTypes)
        names << QString::fromUtf8(allowed.name());

    return names.join(QStringLiteral(" | "));
}

bool Descriptor::accepts(const QMetaType& valueType) const {
    // Unset is a valid state for QVariant options, they are simply absent from the file
    if (type.id() == QMetaType::QVariant && !valueType.isValid())
        return true;

    if (annotation.allowedTypes.isEmpty())
        return type == valueType;

    return annotation.allowedTypes.contains(valueType);
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

        if (!isNode) {
            desc.codec = resolveCodec(desc);
            if (!desc.codec)
                qCCritical(lcSchema, "No codec for %s of type %s, it will not be loaded or saved", qUtf8Printable(key),
                    desc.type.name());
        }

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
