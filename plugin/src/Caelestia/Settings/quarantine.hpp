#pragma once

#include <qhash.h>
#include <qjsonvalue.h>
#include <qtclasshelpermacros.h>

namespace caelestia::settings {

class Quarantine {
public:
    explicit Quarantine() = default;
    virtual ~Quarantine() = default;

    virtual void insert(const QString& key, const QJsonValue& value) = 0;
    virtual bool remove(const QString& key) = 0;
    virtual QJsonValue apply(const QJsonValue& json) const = 0;

    Q_DISABLE_COPY_MOVE(Quarantine)
};

class ObjectQuarantine : public Quarantine {
public:
    void insert(const QString& key, const QJsonValue& value) override;
    bool remove(const QString& key) override;
    QJsonValue apply(const QJsonValue& json) const override;

private:
    QHash<QString, QJsonValue> m_quarantine;
};

} // namespace caelestia::settings
