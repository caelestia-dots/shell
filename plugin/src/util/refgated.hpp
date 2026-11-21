#pragma once

#include <qhash.h>
#include <qobject.h>

namespace util {

// Defers deletion until every QML delegate holding a ref is destroyed
class RefGated : public QObject {
    Q_OBJECT

public:
    using QObject::QObject;

    Q_INVOKABLE void ref(QObject* ref);
    Q_INVOKABLE void unref(QObject* ref);

protected:
    void release();
    [[nodiscard]] bool released() const;

private:
    bool m_released = false;
    QHash<QObject*, QMetaObject::Connection> m_refs;

    void dropRef(QObject* ref);
};

} // namespace util
