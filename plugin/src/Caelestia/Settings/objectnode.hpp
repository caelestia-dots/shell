#pragma once

#include <qjsonobject.h>
#include <qobject.h>
#include <qset.h>

#include "node.hpp"

namespace caelestia::settings {

class ObjectNode : public Node {
    Q_OBJECT

public:
    explicit ObjectNode(ObjectNode* fallback, QObject* parent = nullptr);

    [[nodiscard]] QJsonValue toJson(bool sparse = true) const override;
    void syncJson(const QJsonValue& json, QList<Diagnostic>& diagnostics) override;
    [[nodiscard]] const Quarantine& quarantine() override;

private:
    std::unique_ptr<ObjectQuarantine> m_quarantine;

    QSet<QString> loadFromJson(const QJsonObject& json, QList<Diagnostic>& diagnostics);
    void resetUnvisited(const QSet<QString>& visited);
};

} // namespace caelestia::settings
