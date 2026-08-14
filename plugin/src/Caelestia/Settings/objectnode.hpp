#pragma once

#include <qobject.h>

#include "node.hpp"

namespace caelestia::settings {

class ObjectNode : public Node {
    Q_OBJECT

public:
    explicit ObjectNode(ObjectNode* fallback, QObject* parent = nullptr);

    [[nodiscard]] QJsonValue toJson(bool sparse = true) const override;
    void syncJson(const QJsonValue& json, QList<Diagnostic>& diagnostics) override;
};

} // namespace caelestia::settings
