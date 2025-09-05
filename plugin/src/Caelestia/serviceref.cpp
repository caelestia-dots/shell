#include "service.hpp"
#include <QObject>
#include <qqmlintegration.h>

class ServiceRef : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(Service* service READ service WRITE setService NOTIFY serviceChanged)

public:
    explicit ServiceRef(QObject* parent = nullptr)
        : QObject(parent)
        , m_service(nullptr) {
        updateRefCount(1);
    }
    ~ServiceRef() { updateRefCount(-1); }

    [[nodiscard]] Service* service() const { return m_service; }
    void setService(Service* service) {
        if (m_service == service) {
            return;
        }

        updateRefCount(-1);

        m_service = service;
        emit serviceChanged();

        updateRefCount(1);
    }

signals:
    void serviceChanged();

private:
    Service* m_service;

    void updateRefCount(int count) {
        if (m_service) {
            m_service->setRefCount(m_service->refCount() + count);
        }
    }
};