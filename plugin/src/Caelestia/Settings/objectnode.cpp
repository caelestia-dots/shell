#include "objectnode.hpp"

#include <qjsonobject.h>

#include "codecs.hpp"

namespace caelestia::settings {

ObjectNode::ObjectNode(ObjectNode* fallback, QObject* parent)
    : Node(fallback, parent) {}

QJsonValue ObjectNode::toJson(bool sparse) const {
    QJsonObject json;

    for (const auto& desc : schema().descriptors()) {
        const auto val = value(desc.key);

        if (const auto* node = val.value<Node*>()) {
            if (!sparse || node->hasOverrides())
                json.insert(desc.key, node->toJson(sparse));
            continue;
        }

        if (sparse && !isOverride(desc.key))
            continue;

        const auto codec = ValueCodec::codecFor(desc.type);
        if (!codec) { // This should not happen
            qCCritical(lcSettings, "No codec found for type %s, not serialising %s", desc.type.name(),
                qUtf8Printable(pathFor(desc.key)));
            continue;
        }

        json.insert(desc.key, codec->encode(val));
    }

    if (m_quarantine)
        return m_quarantine->apply(json);

    return json;
}

bool ObjectNode::syncJson(const QJsonValue& json, QList<Diagnostic>& diagnostics) {
    m_quarantine.reset(); // Clear out old quarantine

    if (!json.isObject()) {
        const auto d = Diagnostic::mismatch("an object", json, path());
        qCWarning(lcSettings, "Error decoding option %s: %s", qUtf8Printable(d.option), qUtf8Printable(d.message));
        diagnostics << d;
        return false;
    }

    const auto obj = json.toObject();

    qCDebug(lcSettings) << "Loading JSON into" << metaObject()->className() << "with" << obj.size()
                        << "keys:" << obj.keys();

    const auto visited = loadFromJson(obj, diagnostics);
    resetUnvisited(visited);

    return true;
}

Quarantine* ObjectNode::quarantine() const {
    return m_quarantine.get();
}

void ObjectNode::quarantineKey(const QString& key, const QJsonValue& value) {
    if (!m_quarantine)
        m_quarantine = std::make_unique<ObjectQuarantine>();
    m_quarantine->insert(key, value);
}

QSet<QString> ObjectNode::loadFromJson(const QJsonObject& json, QList<Diagnostic>& diagnostics) {
    const WriteScope scope(this, WriteOrigin::File);

    QSet<QString> visited;
    visited.reserve(json.size());

    // Convenience macro for quarantine then skip
#define SKIP                                                                                                           \
    quarantineKey(key, v);                                                                                             \
    continue

    for (const auto [k, v] : json.asKeyValueRange()) {
        const auto key = k.toString();
        const auto* desc = schema().get(key);

        if (!desc) {
            const auto path = pathFor(key);
            qCWarning(lcSettings) << "Unknown option" << path;
            diagnostics << Diagnostic{
                DiagnosticType::UnknownOption,
                path,
                QStringLiteral("Unknown option %1").arg(key),
            };
            SKIP;
        }

        // Recurse into child nodes
        if (desc->isNode) {
            qCDebug(lcSettings) << "  Recursing into" << key;
            auto* const node = value(key).value<Node*>();
            if (node->syncJson(v, diagnostics))
                visited << key;
            else
                quarantineKey(key, v); // Quarantine entire node cause sync failed
            continue;
        }

        if (desc->globalOnly && fallbackNode()) {
            qCWarning(lcSettings) << "Global property definition found in overlay file, ignoring" << key;
            diagnostics << Diagnostic{
                DiagnosticType::GlobalOption,
                pathFor(key),
                QStringLiteral("Global properties should not be defined in overlay files"),
            };
            SKIP;
        }

        const auto codec = ValueCodec::codecFor(desc->type);
        if (!codec) { // This should not happen
            qCCritical(lcSettings, "No codec found for type %s, not loading %s", desc->type.name(),
                qUtf8Printable(pathFor(key)));
            SKIP;
        }

        auto val = codec->decode(v);
        if (val.error) {
            const auto path = pathFor(key);
            qCWarning(
                lcSettings, "Error decoding option %s: %s", qUtf8Printable(path), qUtf8Printable(val.error->message));
            val.error->option = path;
            diagnostics << *val.error;
            SKIP;
        }

        visited << key;
        setValue(key, val.value);
    }

#undef SKIP

    return visited;
}

void ObjectNode::resetUnvisited(const QSet<QString>& visited) {
    const WriteScope scope(this, WriteOrigin::FileReset);

    for (const auto& desc : schema().descriptors()) {
        if (visited.contains(desc.key))
            continue;

        // Reset nodes recursively
        if (desc.isNode) {
            value(desc.key).value<Node*>()->resetToDefaults();
            continue;
        }

        setValue(desc.key, fallbackNode() ? fallbackNode()->value(desc.key) : desc.defaultValue);
    }
}

} // namespace caelestia::settings
