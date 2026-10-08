#pragma once

#include <qobject.h>
#include <qqmlintegration.h>

#include "util/ringbuffer.hpp"

namespace caelestia {

class CircularBuffer : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int capacity READ capacity WRITE setCapacity NOTIFY capacityChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(qreal maximum READ maximum NOTIFY maximumChanged)

public:
    explicit CircularBuffer(QObject* parent = nullptr);

    [[nodiscard]] int capacity() const;
    void setCapacity(int capacity);

    [[nodiscard]] int count() const;
    [[nodiscard]] qreal maximum() const;

    Q_INVOKABLE void push(qreal value);
    Q_INVOKABLE void clear();
    [[nodiscard]] Q_INVOKABLE qreal at(int index) const;

signals:
    void capacityChanged();
    void countChanged();
    void maximumChanged();
    void valuesChanged();

private:
    [[nodiscard]] qreal computeMaximum() const;

    util::RingBuffer<qreal> m_data;
    qreal m_max = 0.0;
};

} // namespace caelestia
