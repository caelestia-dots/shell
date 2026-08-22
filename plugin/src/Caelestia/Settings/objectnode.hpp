#pragma once

#include <qjsonobject.h>
#include <qobject.h>
#include <qset.h>

#include "node.hpp"

namespace caelestia::settings {

class ObjectNode : public Node {
    Q_OBJECT

public:
    explicit ObjectNode(ObjectNode* fallback, QObject* parent = nullptr, bool globalOnly = false);

    Q_INVOKABLE void resetOption(const QString& key);
    Q_INVOKABLE Descriptor descriptorFor(const QString& key) const;

    [[nodiscard]] QJsonValue toJson(bool sparse = true) const override;
    bool syncJson(const QJsonValue& json, QList<Diagnostic>& diagnostics) override;

private:
    void quarantineKey(const QString& key, const QJsonValue& value);

    QSet<QString> loadFromJson(const QJsonObject& json, QList<Diagnostic>& diagnostics);
    void resetUnvisited(const QSet<QString>& visited);
};

} // namespace caelestia::settings
