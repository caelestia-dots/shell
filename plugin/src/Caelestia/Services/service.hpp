#pragma once

#include <qobject.h>
#include <qset.h>

namespace caelestia::services {

class Service : public QObject {
    Q_OBJECT

public:
    explicit Service(QObject* parent = nullptr);

    void ref(QObject* sender);
    void unref(QObject* sender);

private:
    QSet<QObject*> m_refs;

    virtual void start() = 0;
    virtual void stop() = 0;
};

} // namespace caelestia::services
