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

        json.insert(desc.key, QJsonValue::fromVariant(val));
    }

    return json;
}

void ObjectNode::syncJson(const QJsonValue& json, QList<Diagnostic>& diagnostics) {
    const auto obj = json.toObject();

    qCDebug(lcSettings) << "Loading JSON into" << metaObject()->className() << "with" << obj.size()
                        << "keys:" << obj.keys();

    const auto visited = loadFromJson(obj, diagnostics);
    resetUnvisited(visited);
}

QSet<QString> ObjectNode::loadFromJson(const QJsonObject& json, QList<Diagnostic>& diagnostics) {
    const WriteScope scope(this, WriteOrigin::File);

    QSet<QString> visited;
    visited.reserve(json.size());

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
            continue;
        }

        visited << key;

        // Recurse into child nodes
        if (desc->isNode) {
            qCDebug(lcSettings) << "  Recursing into" << key;
            auto* const node = value(key).value<Node*>();
            node->syncJson(v, diagnostics);
            continue;
        }

        if (desc->globalOnly && fallbackNode()) {
            qCWarning(lcSettings) << "Global property definition found in overlay file, ignoring" << key;
            diagnostics << Diagnostic{
                DiagnosticType::GlobalOption,
                pathFor(key),
                QStringLiteral("Global properties should not be defined in overlay files"),
            };
            continue;
        }

        const auto codec = ValueCodec::codecFor(desc->type);
        if (!codec) { // This should not happen
            qCCritical(lcSettings, "No codec found for type %s, ignoring option %s", desc->type.name(),
                qUtf8Printable(pathFor(key)));
            continue;
        }

        auto val = codec->decode(v);
        if (val.error) {
            const auto path = pathFor(key);
            qCWarning(
                lcSettings, "Error decoding option %s: %s", qUtf8Printable(path), qUtf8Printable(val.error->message));
            val.error->option = path;
            diagnostics << *val.error;
            continue;
        }

        setValue(key, val.value);
    }

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
