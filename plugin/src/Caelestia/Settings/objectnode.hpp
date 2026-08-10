#pragma once

#include <qjsonobject.h>
#include <qjsonvalue.h>
#include <qobject.h>

#include "node.hpp"

namespace caelestia::settings {

class ObjectNode : public Node {
    Q_OBJECT

public:
    explicit ObjectNode(QObject* parent = nullptr);

    QJsonValue toJson() const override;
    SyncResult syncJson(const QJsonValue& json) override;

protected:
    void connectNotifiers() const override;

private slots:
    void onPropChanged();

private:
    QJsonObject m_json;
    QHash<int, const char*> m_notifyToProp;
};

} // namespace caelestia::settings
