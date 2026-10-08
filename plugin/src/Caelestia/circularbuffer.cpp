#include "circularbuffer.hpp"

#include <algorithm>

namespace caelestia {

CircularBuffer::CircularBuffer(QObject* parent)
    : QObject(parent) {}

int CircularBuffer::capacity() const {
    return static_cast<int>(m_data.capacity());
}

void CircularBuffer::setCapacity(int capacity) {
    capacity = std::max(capacity, 0);
    if (this->capacity() == capacity)
        return;

    m_data = util::RingBuffer<qreal>(capacity);
    m_max = 0.0;

    emit capacityChanged();
    emit countChanged();
    emit maximumChanged();
    emit valuesChanged();
}

int CircularBuffer::count() const {
    return static_cast<int>(m_data.count());
}

qreal CircularBuffer::maximum() const {
    return m_max;
}

void CircularBuffer::push(qreal value) {
    if (m_data.capacity() <= 0)
        return;

    const auto oldCount = m_data.count();
    m_data.push(value);
    if (m_data.count() != oldCount)
        emit countChanged();

    const auto newMax = computeMaximum();
    if (!qFuzzyCompare(m_max + 1.0, newMax + 1.0)) {
        m_max = newMax;
        emit maximumChanged();
    }

    emit valuesChanged();
}

void CircularBuffer::clear() {
    if (m_data.count() == 0)
        return;

    m_data.clear();
    emit countChanged();

    if (m_max > 0.0) {
        m_max = 0.0;
        emit maximumChanged();
    }

    emit valuesChanged();
}

qreal CircularBuffer::computeMaximum() const {
    if (m_data.count() == 0)
        return 0.0;

    qreal maxVal = m_data.at(0);
    for (qsizetype i = 1; i < m_data.count(); ++i)
        maxVal = std::max(maxVal, m_data.at(i));
    return maxVal;
}

qreal CircularBuffer::at(int index) const {
    if (index < 0 || index >= m_data.count())
        return 0.0;

    return m_data.at(index);
}

} // namespace caelestia
