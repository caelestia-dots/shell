#pragma once

#include <QDebug>
#include <QObject>
#include <qqmlintegration.h>

class Service : public QObject {
    Q_OBJECT

    Q_PROPERTY(int refCount READ refCount WRITE setRefCount NOTIFY refCountChanged)

public:
    using QObject::QObject;

    [[nodiscard]] int refCount() const;
    void setRefCount(int refCount);

    virtual void start() = 0;
    virtual void stop() = 0;

signals:
    void refCountChanged();

private:
    int m_refCount;
};