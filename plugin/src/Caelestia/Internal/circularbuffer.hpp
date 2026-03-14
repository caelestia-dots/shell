#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qvector.h>

namespace caelestia::internal {

class CircularBuffer : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int capacity READ capacity WRITE setCapacity NOTIFY capacityChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(QList<qreal> values READ values NOTIFY valuesChanged)
    Q_PROPERTY(qreal maximum READ maximum NOTIFY valuesChanged)

public:
    explicit CircularBuffer(QObject* parent = nullptr);

    [[nodiscard]] int capacity() const;
    void setCapacity(int capacity);

    [[nodiscard]] int count() const;
    [[nodiscard]] QList<qreal> values() const;
    [[nodiscard]] qreal maximum() const;

    Q_INVOKABLE void push(qreal value);
    Q_INVOKABLE void clear();
    Q_INVOKABLE [[nodiscard]] qreal at(int index) const;

signals:
    void capacityChanged();
    void countChanged();
    void valuesChanged();

private:
    QVector<qreal> m_data;
    int m_head = 0;
    int m_count = 0;
    int m_capacity = 0;
};

} // namespace caelestia::internal
