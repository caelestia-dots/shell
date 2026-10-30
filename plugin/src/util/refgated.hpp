#pragma once

#include <qobject.h>
#include <qset.h>

namespace util {

// Defers deletion until every QML delegate holding a ref is destroyed
class RefGated : public QObject {
    Q_OBJECT

public:
    using QObject::QObject;

    Q_INVOKABLE void ref(QObject* ref);

protected:
    void release();
    [[nodiscard]] bool released() const;

private:
    bool m_released = false;
    QSet<QObject*> m_refs;
};

} // namespace util
